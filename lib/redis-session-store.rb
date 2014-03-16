# vim:fileencoding=utf-8
require 'redis'

# Redis session storage for Rails, and for Rails only. Derived from
# the MemCacheStore code, simply dropping in Redis instead.
class RedisSessionStore < ActionDispatch::Session::AbstractStore
  VERSION = '0.4.2'

  # ==== Options
  # * +:key+ - Same as with the other cookie stores, key name
  # * +:redis+ - A hash with redis-specific options
  #   * +:host+ - Redis host name, default is localhost
  #   * +:port+ - Redis port, default is 6379
  #   * +:db+ - Database number, defaults to 0.
  #   * +:key_prefix+ - Prefix for keys used in Redis, e.g. +myapp:+
  #   * +:expire_after+ - A number in seconds for session timeout
  #
  # ==== Examples
  #
  #     My::Application.config.session_store = :redis_session_store, {
  #       :key          => 'your_session_key',
  #       :redis        => {
  #         :db => 2,
  #         :expire_after => 120.minutes,
  #         :key_prefix => "myapp:session:",
  #         :host    => 'host', # Redis host name, default is localhost
  #         :port    => 12345   # Redis port, default is 6379
  #       }
  #     }
  #
  def initialize(app, options = {})
    super

    redis_options = options[:redis] || {}

    @default_options.merge!(namespace: 'rack:session')
    @default_options.merge!(redis_options)
    @redis = Redis.new(redis_options)
    @raise_errors = !options[:raise_errors].nil?
    @log_collisions = !options[:log_collisions].nil?
  end

  private

  attr_reader :redis, :key, :default_options, :raise_errors, :log_collisions

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
    prefixed_sid = prefixed(sid)
    return false unless redis.get(prefixed_sid)

    Rails.logger.warn(
      'RedisSessionStore#generate_sid: ' <<
        "collision found with key #{prefixed_sid.inspect}"
    ) if log_collisions
    true
  end

  def get_session(env, sid)
    unless sid && (session = load_session_from_redis(sid))
      sid = generate_sid
      session = {}
    end

    [sid, session]
  rescue Errno::ECONNREFUSED => e
    raise e if raise_errors
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
    raise e if raise_errors
    return false
  end

  def destroy_session(env, sid, options)
    redis.del(prefixed(sid))
    return nil if (options || {})[:drop]
    generate_sid
  end

  def destroy(env)
    if env['rack.request.cookie_hash'] && env['rack.request.cookie_hash'][key]
      redis.del(prefixed(env['rack.request.cookie_hash'][key]))
    end
  rescue Errno::ECONNREFUSED => e
    raise e if raise_errors
    Rails.logger.warn("RedisSessionStore#destroy: #{e.message}")
    false
  end
end
