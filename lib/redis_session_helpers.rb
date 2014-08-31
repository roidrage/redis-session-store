module RedisSessionHelpers

  def prefixed(sid)
    "#{default_options[:key_prefix]}#{sid}"
  end

  def find_by_session_id(sid)
    unless sid && (session = load_session_from_redis(sid))
      sid = generate_sid
      session = {}
    end

    [sid, session]
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

  def save_by_session_id(sid, session_data, opt)
    expiry = (options || env.fetch(ENV_SESSION_OPTIONS_KEY))[:expire_after]
    if expiry
      redis.setex(prefixed(sid), expiry, encode(session_data))
    else
      redis.set(prefixed(sid), encode(session_data))
    end
    return sid
  end

  def encode(session_data)
    serializer.dump(session_data)
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

end
