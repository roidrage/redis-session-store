# vim:fileencoding=utf-8
require 'redis'

# Redis session storage for Rails, and for Rails only. Derived from
# the MemCacheStore code, simply dropping in Redis instead.
class RedisSessionStore < ActionDispatch::Session::AbstractStore
  VERSION = '0.5.0'

  # ==== Options
  # * +:key+ - Same as with the other cookie stores, key name
  # * +:redis+ - A hash with redis-specific options
  #   * +:host+ - Redis host name, default is localhost
  #   * +:port+ - Redis port, default is 6379
  #   * +:db+ - Database number, defaults to 0.
  #   * +:key_prefix+ - Prefix for keys used in Redis, e.g. +myapp:+
  #   * +:expire_after+ - A number in seconds for session timeout
  # * +:on_sid_collision:+ - Called with SID string when generated SID collides
  # * +:on_redis_down:+ - Called with err, env, and SID on Errno::ECONNREFUSED
  #
  # ==== Examples
  #
  #     My::Application.config.session_store = :redis_session_store, {
  #       key: 'your_session_key',
  #       redis: {
  #         db: 2,
  #         expire_after: 120.minutes,
  #         key_prefix: 'myapp:session:',
  #         host: 'host', # Redis host name, default is localhost
  #         port: 12345   # Redis port, default is 6379
  #       },
  #       on_sid_collision: ->(sid) { logger.warn("SID collision! #{sid}") },
  #       on_redis_down: ->(*a) { logger.error("Redis down! #{a.inspect}") }
  #     }
  #
  def initialize(app, options = {})
    super

    redis_options = options[:redis] || {}

    @default_options.merge!(namespace: 'rack:session')
    @default_options.merge!(redis_options)
    @redis = Redis.new(redis_options)
    @on_sid_collision = options[:on_sid_collision]
    @on_redis_down = options[:on_redis_down]
  end

  attr_accessor :on_sid_collision, :on_redis_down

  private

  attr_reader :redis, :key, :default_options

  def prefixed(sid)
    "#{default_options[:key_prefix]}#{sid}"
  end

  def generate_sid
    loop do
      sid = super
      break sid unless sid_collision?(sid)
    end
  end

  def sid_collision?(sid)
    !!redis.get(prefixed(sid)).tap do |value| # rubocop: disable DoubleNegation
      on_sid_collision.call(sid) if value && on_sid_collision
    end
  end

  def get_session(env, sid)
    unless sid && (session = load_session_from_redis(sid))
      sid = generate_sid
      session = {}
    end

    [sid, session]
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, sid) if on_redis_down
    [generate_sid, {}]
  end

  def load_session_from_redis(sid)
    data = redis.get(prefixed(sid))
    data ? Marshal.load(data) : nil
  end

  def set_session(env, sid, session_data, options = nil)
    expiry = (options || env[ENV_SESSION_OPTIONS_KEY])[:expire_after]
    if expiry
      redis.setex(prefixed(sid), expiry, Marshal.dump(session_data))
    else
      redis.set(prefixed(sid), Marshal.dump(session_data))
    end
    return sid
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, sid) if on_redis_down
    return false
  end

  def destroy_session(env, sid, options)
    redis.del(prefixed(sid))
    return nil if (options || {})[:drop]
    generate_sid
  end

  def destroy(env)
    if env['rack.request.cookie_hash'] &&
        (sid = env['rack.request.cookie_hash'][key])
      redis.del(prefixed(sid))
    end
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, sid) if on_redis_down
    false
  end
end
