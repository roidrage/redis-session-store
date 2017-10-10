require 'redis'
require 'securerandom'

# Redis session storage for Rails, and for Rails only. Derived from
# the MemCacheStore code, simply dropping in Redis instead.
class RedisSessionStore < ActionDispatch::Session::AbstractStore
  VERSION = '0.9.1'.freeze
  # Rails 3.1 and beyond defines the constant elsewhere
  unless defined?(ENV_SESSION_OPTIONS_KEY)
    if Rack.release.split('.').first.to_i > 1
      ENV_SESSION_OPTIONS_KEY = Rack::RACK_SESSION_OPTIONS
    else
      ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
    end
  end

  # ==== Options
  # * +:key+ - Same as with the other cookie stores, key name
  # * +:redis+ - A hash with redis-specific options
  #   * +:url+ - Redis url, default is redis://localhost:6379/0
  #   * +:key_prefix+ - Prefix for keys used in Redis, e.g. +myapp:+
  #   * +:hashkey_prefix+ - Prefix for hashkeys if session saved as hash
  #   * +:expire_after+ - A number in seconds for session timeout
  #   * +:client+ - Connect to Redis with given object rather than create one
  # * +:on_redis_down:+ - Called with err, env, and SID on Errno::ECONNREFUSED
  # * +:on_session_load_error:+ - Called with err and SID on Marshal.load fail
  # * +:serializer:+ - Serializer to use on session data, default is :marshal.
  # * +:adapter:+ - Adapter for other framework's session, default is :default.
  #
  # ==== Examples
  #
  #     My::Application.config.session_store :redis_session_store, {
  #       key: 'your_session_key',
  #       redis: {
  #         expire_after: 120.minutes,
  #         key_prefix: 'myapp:session:',
  #         url: 'redis://host:12345/2'
  #       },
  #       on_redis_down: ->(*a) { logger.error("Redis down! #{a.inspect}") }
  #       serializer: :hybrid # migrate from Marshal to JSON
  #     }
  #
  def initialize(app, options = {})
    super

    redis_options = options[:redis] || {}

    @default_options[:namespace] = 'rack:session'
    @default_options.merge!(redis_options)
    @redis = redis_options[:client] || Redis.new(redis_options)
    @on_redis_down = options[:on_redis_down]
    @serializer = determine_serializer(options[:serializer])
    @adapter = determine_adapter(options[:adapter])
    @on_session_load_error = options[:on_session_load_error]
    verify_handlers!
  end

  attr_accessor :on_redis_down, :on_session_load_error

  private

  attr_reader :redis, :key, :default_options, :serializer, :adapter

  # overrides method defined in rack to actually verify session existence
  # Prevents needless new sessions from being created in scenario where
  # user HAS session id, but it already expired, or is invalid for some
  # other reason, and session was accessed only for reading.
  def session_exists?(env)
    value = current_session_id(env)

    !!(
      value && !value.empty? &&
      redis.exists(prefixed(value))
    )
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, value) if on_redis_down

    true
  end

  def verify_handlers!
    %w(on_redis_down on_session_load_error).each do |h|
      next unless (handler = public_send(h)) && !handler.respond_to?(:call)

      raise ArgumentError, "#{h} handler is not callable"
    end
  end

  def prefixed(sid)
    "#{default_options[:key_prefix]}#{sid}"
  end

  def generate_session_sid
    adapter.generate_session_sid || generate_sid
  end

  def get_session(env, sid)
    session = load_session_from_redis(env, sid) if sid
    return [sid, session] if sid && session
    [generate_session_sid, {}]
  end
  alias find_session get_session

  def load_session_from_redis(env, sid)
    return adapter.load_session_from_redis(prefixed(sid))
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, sid) if on_redis_down
    nil
  rescue => e
    destroy_session_from_sid(sid, drop: true)
    on_session_load_error.call(e, sid) if on_session_load_error
    nil
  end

  def set_session(env, sid, session_data, options = nil)
    expiry = (options || env.fetch(ENV_SESSION_OPTIONS_KEY))[:expire_after]
    adapter.write_session_to_redis(prefixed(sid), session_data, expiry)
    return sid
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, sid) if on_redis_down
    false
  end
  alias write_session set_session

  def destroy_session(env, sid, options)
    destroy_session_from_sid(sid, (options || {}).to_hash.merge(env: env))
  end
  alias delete_session destroy_session

  def destroy(env)
    if env['rack.request.cookie_hash'] &&
       (sid = env['rack.request.cookie_hash'][key])
      destroy_session_from_sid(sid, drop: true, env: env)
    end
    false
  end

  def destroy_session_from_sid(sid, options = {})
    redis.del(prefixed(sid))
    (options || {})[:drop] ? nil : generate_session_sid
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
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

  def determine_adapter(adapter)
    adapter ||= :default
    case adapter
    when :default then DefaultAdapter.new(redis, serializer)
    when :java_spring then
      JavaSpringAdapter.new(redis, serializer, default_options[:hashkey_prefix])
    else adapter
    end
  end

  # Default adapter, save session in redis as string
  class DefaultAdapter
    def initialize(redis, serializer)
      @redis = redis
      @serializer = serializer
    end

    attr_accessor :redis, :serializer

    def generate_session_sid
    end

    def load_session_from_redis(s_key)
      data = redis.get(s_key)
      data ? serializer.load(data) : nil
    end

    def write_session_to_redis(s_key, session_data, expiry)
      if expiry
        redis.setex(s_key, expiry, serializer.dump(session_data))
      else
        redis.set(s_key, serializer.dump(session_data))
      end
    end
  end

  # Java Spring adapter, save session in redis as hash
  class JavaSpringAdapter < DefaultAdapter
    def initialize(redis, serializer, hashkey_prefix)
      @redis = redis
      @serializer = serializer
      @hashkey_prefix = hashkey_prefix || ''
    end

    attr_accessor :redis, :serializer, :hashkey_prefix

    def generate_session_sid
      SecureRandom.uuid
    end

    def load_session_from_redis(s_key)
      data = {}
      redis.hkeys(s_key).each do |key|
        next unless key.start_with?(hashkey_prefix)
        value = redis.hget(s_key, key).to_s
        key = key[hashkey_prefix.length..-1]
        data[key] = serializer.load(value) unless value.empty?
      end
      data
    end

    def write_session_to_redis(s_key, session_data, expiry)
      keys = []
      session_data.each do |key, value|
        key = "#{hashkey_prefix}#{key}"
        unless value.nil?
          redis.hset(s_key, key, serializer.dump(value))
          keys << key
        end
      end
      clear_old_keys(s_key, keys)
      redis.expire(s_key, expiry) if expiry
    end

    private

    def clear_old_keys(s_key, new_keys)
      redis.hkeys(s_key).each do |key|
        next unless key.start_with?(hashkey_prefix) && !new_keys.include?(key)
        redis.hdel(s_key, key)
      end
    end
  end
end
