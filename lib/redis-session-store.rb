require 'redis'

# Redis session storage for Rails, and for Rails only. Derived from
# the MemCacheStore code, simply dropping in Redis instead.
class RedisSessionStore < ActionDispatch::Session::AbstractSecureStore
  VERSION = '0.11.5'.freeze

  USE_INDIFFERENT_ACCESS = defined?(ActiveSupport).freeze
  # ==== Options
  # * +:key+ - Same as with the other cookie stores, key name
  # * +:redis+ - A hash with redis-specific options
  #   * +:url+ - Redis url, default is redis://localhost:6379/0
  #   * +:key_prefix+ - Prefix for keys used in Redis, e.g. +myapp:+
  #   * +:expire_after+ - A number in seconds for session timeout
  #   * +:client+ - Connect to Redis with given object rather than create one
  # * +:on_redis_down:+ - Called with err, env, and SID on Errno::ECONNREFUSED
  # * +:on_session_load_error:+ - Called with err and SID on Marshal.load fail
  # * +:serializer:+ - Serializer to use on session data, default is :marshal.
  #
  # ==== Examples
  #
  #     Rails.application.config.session_store :redis_session_store,
  #       key: 'your_session_key',
  #       redis: {
  #         expire_after: 120.minutes,
  #         key_prefix: 'myapp:session:',
  #         url: 'redis://localhost:6379/0'
  #       },
  #       on_redis_down: ->(*a) { logger.error("Redis down! #{a.inspect}") },
  #       serializer: :hybrid # migrate from Marshal to JSON
  #
  def initialize(app, options = {})
    super

    @default_options[:namespace] = 'rack:session'
    @default_options.merge!(options[:redis] || {})
    init_options = options[:redis]&.reject { |k, _v| %i[expire_after key_prefix].include?(k) } || {}
    @redis = init_options[:client] || Redis.new(init_options)
    @on_redis_down = options[:on_redis_down]
    @serializer = determine_serializer(options[:serializer])
    @on_session_load_error = options[:on_session_load_error]
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

    !!(
      value && !value.empty? &&
      key_exists_with_fallback?(value)
    )
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, value) if on_redis_down

    true
  end

  def key_exists_with_fallback?(value)
    return false if private_session_id?(value.public_id)

    key_exists?(value.private_id) || key_exists?(value.public_id)
  end

  def key_exists?(value)
    if redis.respond_to?(:exists?)
      # added in redis gem v4.2
      redis.exists?(prefixed(value))
    else
      # older method, will return an integer starting in redis gem v4.3
      redis.exists(prefixed(value))
    end
  end

  def private_session_id?(value)
    value.match?(/\A\d+::/)
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

  def session_default_values
    [generate_sid, USE_INDIFFERENT_ACCESS ? {}.with_indifferent_access : {}]
  end

  def get_session(env, sid)
    sid && (session = load_session_with_fallback(sid)) ? [sid, session] : session_default_values
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, sid) if on_redis_down
    session_default_values
  end
  alias find_session get_session

  def load_session_with_fallback(sid)
    return nil if private_session_id?(sid.public_id)

    load_session_from_redis(
      key_exists?(sid.private_id) ? sid.private_id : sid.public_id
    )
  end

  def load_session_from_redis(sid)
    data = redis.get(prefixed(sid))
    begin
      data ? decode(data) : nil
    rescue StandardError => e
      destroy_session_from_sid(sid, drop: true)
      on_session_load_error.call(e, sid) if on_session_load_error
      nil
    end
  end

  def decode(data)
    session = serializer.load(data)
    USE_INDIFFERENT_ACCESS ? session.with_indifferent_access : session
  end

  def set_session(env, sid, session_data, options = nil)
    expiry = get_expiry(env, options)
    if expiry
      redis.setex(prefixed(sid.private_id), expiry, encode(session_data))
    else
      redis.set(prefixed(sid.private_id), encode(session_data))
    end
    sid
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
    on_redis_down.call(e, env, sid) if on_redis_down
    false
  end
  alias write_session set_session

  def get_expiry(env, options)
    session_storage_options = options || env.fetch(Rack::RACK_SESSION_OPTIONS, {})
    session_storage_options[:ttl] || session_storage_options[:expire_after]
  end

  def encode(session_data)
    serializer.dump(session_data)
  end

  def destroy_session(env, sid, options)
    destroy_session_from_sid(sid.public_id, (options || {}).to_hash.merge(env: env, drop: true))
    destroy_session_from_sid(sid.private_id, (options || {}).to_hash.merge(env: env))
  end
  alias delete_session destroy_session

  def destroy(env)
    if env['rack.request.cookie_hash'] &&
       (sid = env['rack.request.cookie_hash'][key])
      sid = Rack::Session::SessionId.new(sid)
      destroy_session_from_sid(sid.private_id, drop: true, env: env)
      destroy_session_from_sid(sid.public_id, drop: true, env: env)
    end
    false
  end

  def destroy_session_from_sid(sid, options = {})
    redis.del(prefixed(sid))
    (options || {})[:drop] ? nil : generate_sid
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
end
