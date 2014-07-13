# vim:fileencoding=utf-8
require 'redis'

# Redis session storage for Rails, and for Rails only. Derived from
# the MemCacheStore code, simply dropping in Redis instead.
class RedisSessionStore < ActionDispatch::Session::AbstractStore
  VERSION = '0.7.0'
  # Rails 3.1 and beyond defines the constant elsewhere
  unless defined?(ENV_SESSION_OPTIONS_KEY)
    ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
  end

  # ==== Options
  # * +:key+ - Same as with the other cookie stores, key name
  # * +:redis+ - A hash with redis-specific options
  #   * +:host+ - Redis host name, default is localhost
  #   * +:port+ - Redis port, default is 6379
  #   * +:db+ - Database number, defaults to 0.
  #   * +:key_prefix+ - Prefix for keys used in Redis, e.g. +myapp:+
  #   * +:expire_after+ - A number in seconds for session timeout
  # * +:on_redis_down:+ - Called with err, env, and SID on Errno::ECONNREFUSED
  # * +:on_session_load_error:+ - Called with err and SID on Marshal.load fail
  # * +:serializer:+ - Serializer to use on session data, default is :marshal.
  #
  # ==== Examples
  #
  #     My::Application.config.session_store :redis_session_store, {
  #       key: 'your_session_key',
  #       redis: {
  #         db: 2,
  #         expire_after: 120.minutes,
  #         key_prefix: 'myapp:session:',
  #         host: 'host', # Redis host name, default is localhost
  #         port: 12345   # Redis port, default is 6379
  #       },
  #       on_redis_down: ->(*a) { logger.error("Redis down! #{a.inspect}") }
  #       serializer: :hybrid # migrate from Marshal to JSON
  #     }
  #
  def initialize(app, options = {})
    super

    redis_options = options[:redis] || {}

    @default_options.merge!(namespace: 'rack:session')
    @default_options.merge!(redis_options)
    @redis = Redis.new(redis_options)
    @on_redis_down = redis_options[:on_redis_down]
    @serializer = determine_serializer(redis_options[:serializer])
    @on_session_load_error = redis_options[:on_session_load_error]
    verify_handlers!
  end

  attr_accessor :on_redis_down, :on_session_load_error

  private

  attr_reader :redis, :key, :default_options, :serializer

  # overrides method defined in rack to actually verify session existence
  # Prevents needless new sessions from being created in scenario where
  # user HAS session id, but it already expired, or is invalid for some
  # other reason, and session was accessed only for reading.
  def session_exists?(env)
    value = current_session_id(env)

    value && !value.empty? &&
      redis.exists(prefixed(value)) # new behavior
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, value) if on_redis_down

    true
  end

  def verify_handlers!
    %w(on_redis_down on_session_load_error).each do |h|
      next unless (handler = public_send(h)) && !handler.respond_to?(:call)

      fail ArgumentError, "#{h} handler is not callable"
    end
  end

  def prefixed(sid)
    "#{default_options[:key_prefix]}#{sid}"
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
    begin
      data ? decode(data) : nil
    rescue => e
      destroy_session_from_sid(sid, drop: true)
      on_session_load_error.call(e, sid) if on_session_load_error
      nil
    end
  end

  def decode(data)
    serializer.load(data)
  end

  def set_session(env, sid, session_data, options = nil) # rubocop: disable MethodLength, LineLength
    expiry = (options || env.fetch(ENV_SESSION_OPTIONS_KEY))[:expire_after]
    if expiry
      redis.setex(prefixed(sid), expiry, encode(session_data))
    else
      redis.set(prefixed(sid), encode(session_data))
    end
    return sid
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, sid) if on_redis_down
    return false
  end

  def encode(session_data)
    serializer.dump(session_data)
  end

  def destroy_session(env, sid, options)
    destroy_session_from_sid(sid, (options || {}).to_hash.merge(env: env))
  end

  def destroy(env)
    if env['rack.request.cookie_hash'] &&
        (sid = env['rack.request.cookie_hash'][key])
      destroy_session_from_sid(sid, drop: true, env: env)
    end
    false
  end

  def destroy_session_from_sid(sid, options = {})
    redis.del(prefixed(sid))
    (options || {})[:drop] ? nil : generate_sid
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, options[:env] || {}, sid) if on_redis_down
  end

  def determine_serializer(serializer)
    serializer ||= :marshal
    case serializer
    when :marshal then Marshal
    when :json    then JsonSerializer
    when :hybrid  then HybridSerializer
    else serializer
    end
  end

  # Uses built-in JSON library to encode/decode session
  class JsonSerializer
    def self.load(value)
      JSON.parse(value, quirks_mode: true)
    end

    def self.dump(value)
      JSON.generate(value, quirks_mode: true)
    end
  end

  # Transparently migrates existing session values from Marshal to JSON
  class HybridSerializer < JsonSerializer
    MARSHAL_SIGNATURE = "\x04\x08".freeze

    def self.load(value)
      if needs_migration?(value)
        Marshal.load(value)
      else
        super
      end
    end

    def self.needs_migration?(value)
      value.start_with?(MARSHAL_SIGNATURE)
    end
  end
end
