require 'json'

describe RedisSessionStore do
  let :random_string do
    "#{rand}#{rand}#{rand}"
  end

  let :options do
    {}
  end

  subject(:store) { RedisSessionStore.new(nil, options) }

  let :default_options do
    store.instance_variable_get(:@default_options)
  end

  it 'assigns a :namespace to @default_options' do
    expect(default_options[:namespace]).to eq('rack:session')
  end

  describe 'when initializing with the redis sub-hash options' do
    let :options do
      {
        key: random_string,
        secret: random_string,
        redis: {
          host: 'hosty.local',
          port: 16_379,
          db: 2,
          key_prefix: 'myapp:session:',
          expire_after: 60 * 120
        }
      }
    end

    it 'creates a redis instance' do
      expect(store.instance_variable_get(:@redis)).to_not be_nil
    end

    it 'assigns the :host option to @default_options' do
      expect(default_options[:host]).to eq('hosty.local')
    end

    it 'assigns the :port option to @default_options' do
      expect(default_options[:port]).to eq(16_379)
    end

    it 'assigns the :db option to @default_options' do
      expect(default_options[:db]).to eq(2)
    end

    it 'assigns the :key_prefix option to @default_options' do
      expect(default_options[:key_prefix]).to eq('myapp:session:')
    end

    it 'assigns the :expire_after option to @default_options' do
      expect(default_options[:expire_after]).to eq(60 * 120)
    end
  end

  describe 'when configured with both :ttl and :expire_after' do
    let(:ttl_seconds) { 60 * 120 }
    let :options do
      {
        key: random_string,
        secret: random_string,
        redis: {
          host: 'hosty.local',
          port: 16_379,
          db: 2,
          key_prefix: 'myapp:session:',
          ttl: ttl_seconds,
          expire_after: nil
        }
      }
    end

    it 'assigns the :ttl option to @default_options' do
      expect(default_options[:ttl]).to eq(ttl_seconds)
      expect(default_options[:expire_after]).to be_nil
    end
  end

  describe 'when initializing with top-level redis options' do
    let :options do
      {
        key: random_string,
        secret: random_string,
        host: 'hostersons.local',
        port: 26_379,
        db: 4,
        key_prefix: 'appydoo:session:',
        expire_after: 60 * 60
      }
    end

    it 'creates a redis instance' do
      expect(store.instance_variable_get(:@redis)).to_not be_nil
    end

    it 'assigns the :host option to @default_options' do
      expect(default_options[:host]).to eq('hostersons.local')
    end

    it 'assigns the :port option to @default_options' do
      expect(default_options[:port]).to eq(26_379)
    end

    it 'assigns the :db option to @default_options' do
      expect(default_options[:db]).to eq(4)
    end

    it 'assigns the :key_prefix option to @default_options' do
      expect(default_options[:key_prefix]).to eq('appydoo:session:')
    end

    it 'assigns the :expire_after option to @default_options' do
      expect(default_options[:expire_after]).to eq(60 * 60)
    end
  end

  describe 'when initializing with existing redis object' do
    let :options do
      {
        key: random_string,
        secret: random_string,
        redis: {
          client: redis_client,
          key_prefix: 'myapp:session:',
          expire_after: 60 * 30
        }
      }
    end

    let(:redis_client) { double('redis_client') }

    it 'assigns given redis object to @redis' do
      expect(store.instance_variable_get(:@redis)).to be(redis_client)
    end

    it 'assigns the :client option to @default_options' do
      expect(default_options[:client]).to be(redis_client)
    end

    it 'assigns the :key_prefix option to @default_options' do
      expect(default_options[:key_prefix]).to eq('myapp:session:')
    end

    it 'assigns the :expire_after option to @default_options' do
      expect(default_options[:expire_after]).to eq(60 * 30)
    end
  end

  describe 'rack 1.45 compatibility' do
    # Rack 1.45 (which Rails 3.2.x depends on) uses the return value of
    # set_session to set the cookie value.  See:
    # https://github.com/rack/rack/blob/1.4.5/lib/rack/session/abstract/id.rb

    let(:env)          { double('env') }
    let(:session_id)   { 12_345 }
    let(:session_data) { double('session_data') }
    let(:options)      { { expire_after: 123 } }

    context 'when successfully persisting the session' do
      it 'returns the session id' do
        expect(store.send(:set_session, env, session_id, session_data, options))
          .to eq(session_id)
      end
    end

    context 'when unsuccessfully persisting the session' do
      before do
        allow(store).to receive(:redis).and_raise(Redis::CannotConnectError)
      end

      it 'returns false' do
        expect(store.send(:set_session, env, session_id, session_data, options))
          .to eq(false)
      end
    end

    context 'when no expire_after option is given' do
      let(:options) { {} }

      it 'sets the session value without expiry' do
        expect(store.send(:set_session, env, session_id, session_data, options))
          .to eq(session_id)
      end
    end

    context 'when redis is down' do
      before do
        allow(store).to receive(:redis).and_raise(Redis::CannotConnectError)
        store.on_redis_down = ->(*_a) { @redis_down_handled = true }
      end

      it 'returns false' do
        expect(store.send(:set_session, env, session_id, session_data, options))
          .to eq(false)
      end

      it 'calls the on_redis_down handler' do
        store.send(:set_session, env, session_id, session_data, options)
        expect(@redis_down_handled).to eq(true)
      end

      context 'when :on_redis_down re-raises' do
        before { store.on_redis_down = ->(e, *) { raise e } }

        it 'explodes' do
          expect do
            store.send(:set_session, env, session_id, session_data, options)
          end.to raise_error(Redis::CannotConnectError)
        end
      end
    end
  end

  describe 'checking for session existence' do
    let(:session_id) { 'foo' }

    before do
      allow(store).to receive(:current_session_id)
        .with(:env).and_return(session_id)
    end

    context 'when session id is not provided' do
      context 'when session id is nil' do
        let(:session_id) { nil }
        it 'returns false' do
          expect(store.send(:session_exists?, :env)).to eq(false)
        end
      end

      context 'when session id is empty string' do
        let(:session_id) { '' }
        it 'returns false' do
          allow(store).to receive(:current_session_id).with(:env).and_return('')
          expect(store.send(:session_exists?, :env)).to eq(false)
        end
      end
    end

    context 'when session id is provided' do
      let(:redis) do
        double('redis').tap do |o|
          allow(store).to receive(:redis).and_return(o)
        end
      end

      context 'when session id does not exist in redis' do
        it 'returns false' do
          expect(redis).to receive(:exists).with('foo').and_return(false)
          expect(store.send(:session_exists?, :env)).to eq(false)
        end
      end

      context 'when session id exists in redis' do
        it 'returns true' do
          expect(redis).to receive(:exists).with('foo').and_return(true)
          expect(store.send(:session_exists?, :env)).to eq(true)
        end
      end

      context 'when redis is down' do
        it 'returns true (fallback to old behavior)' do
          allow(store).to receive(:redis).and_raise(Redis::CannotConnectError)
          expect(store.send(:session_exists?, :env)).to eq(true)
        end
      end
    end
  end

  describe 'fetching a session' do
    let :options do
      {
        key_prefix: 'customprefix::'
      }
    end

    let(:fake_key) { 'thisisarediskey' }

    it 'retrieves the prefixed key from redis' do
      redis = double('redis')
      allow(store).to receive(:redis).and_return(redis)
      allow(store).to receive(:generate_sid).and_return(fake_key)
      expect(redis).to receive(:get).with("#{options[:key_prefix]}#{fake_key}")

      store.send(:get_session, double('env'), fake_key)
    end

    context 'when redis is down' do
      before do
        allow(store).to receive(:redis).and_raise(Redis::CannotConnectError)
        allow(store).to receive(:generate_sid).and_return('foop')
      end

      it 'returns an empty session hash' do
        expect(store.send(:get_session, double('env'), fake_key).last)
          .to eq({})
      end

      it 'returns a newly generated sid' do
        expect(store.send(:get_session, double('env'), fake_key).first)
          .to eq('foop')
      end

      context 'when :on_redis_down re-raises' do
        before { store.on_redis_down = ->(e, *) { raise e } }

        it 'explodes' do
          expect do
            store.send(:get_session, double('env'), fake_key)
          end.to raise_error(Redis::CannotConnectError)
        end
      end
    end
  end

  describe 'destroying a session' do
    context 'when the key is in the cookie hash' do
      let(:env) { { 'rack.request.cookie_hash' => cookie_hash } }
      let(:cookie_hash) { double('cookie hash') }
      let(:fake_key) { 'thisisarediskey' }

      before do
        allow(cookie_hash).to receive(:[]).and_return(fake_key)
      end

      it 'deletes the prefixed key from redis' do
        redis = double('redis')
        allow(store).to receive(:redis).and_return(redis)
        expect(redis).to receive(:del)
          .with("#{options[:key_prefix]}#{fake_key}")

        store.send(:destroy, env)
      end

      context 'when redis is down' do
        before do
          allow(store).to receive(:redis).and_raise(Redis::CannotConnectError)
        end

        it 'returns false' do
          expect(store.send(:destroy, env)).to eq(false)
        end

        context 'when :on_redis_down re-raises' do
          before { store.on_redis_down = ->(e, *) { raise e } }

          it 'explodes' do
            expect do
              store.send(:destroy, env)
            end.to raise_error(Redis::CannotConnectError)
          end
        end
      end
    end

    context 'when destroyed via #destroy_session' do
      it 'deletes the prefixed key from redis' do
        redis = double('redis', setnx: true)
        allow(store).to receive(:redis).and_return(redis)
        sid = store.send(:generate_sid)
        expect(redis).to receive(:del).with("#{options[:key_prefix]}#{sid}")

        store.send(:destroy_session, {}, sid, nil)
      end
    end
  end

  describe 'session encoding' do
    let(:env)          { double('env') }
    let(:session_id)   { 12_345 }
    let(:session_data) { { 'some' => 'data' } }
    let(:options)      { {} }
    let(:encoded_data) { Marshal.dump(session_data) }
    let(:redis)        { double('redis', set: nil, get: encoded_data) }
    let(:expected_encoding) { encoded_data }

    before do
      allow(store).to receive(:redis).and_return(redis)
    end

    shared_examples_for 'serializer' do
      it 'encodes correctly' do
        expect(redis).to receive(:set).with('12345', expected_encoding)
        store.send(:set_session, env, session_id, session_data, options)
      end

      it 'decodes correctly' do
        expect(store.send(:get_session, env, session_id))
          .to eq([session_id, session_data])
      end
    end

    context 'marshal' do
      let(:options) { { serializer: :marshal } }
      it_should_behave_like 'serializer'
    end

    context 'json' do
      let(:options) { { serializer: :json } }
      let(:encoded_data) { '{"some":"data"}' }

      it_should_behave_like 'serializer'
    end

    context 'hybrid' do
      let(:options) { { serializer: :hybrid } }
      let(:expected_encoding) { '{"some":"data"}' }

      context 'marshal encoded data' do
        it_should_behave_like 'serializer'
      end

      context 'json encoded data' do
        let(:encoded_data) { '{"some":"data"}' }

        it_should_behave_like 'serializer'
      end
    end

    context 'custom' do
      let :custom_serializer do
        Class.new do
          def self.load(_value)
            { 'some' => 'data' }
          end

          def self.dump(_value)
            'somedata'
          end
        end
      end

      let(:options) { { serializer: custom_serializer } }
      let(:expected_encoding) { 'somedata' }

      it_should_behave_like 'serializer'
    end
  end

  describe 'handling decode errors' do
    context 'when a class is serialized that does not exist' do
      before do
        allow(store).to receive(:redis)
          .and_return(double('redis',
                             get: "\x04\bo:\nNonExistentClass\x00",
                             del: true))
      end

      it 'returns an empty session' do
        expect(store.send(:load_session_from_redis, 'whatever')).to be_nil
      end

      it 'destroys and drops the session' do
        expect(store).to receive(:destroy_session_from_sid)
          .with('wut', drop: true)
        store.send(:load_session_from_redis, 'wut')
      end

      context 'when a custom on_session_load_error handler is provided' do
        before do
          store.on_session_load_error = lambda do |e, sid|
            @e = e
            @sid = sid
          end
        end

        it 'passes the error and the sid to the handler' do
          store.send(:load_session_from_redis, 'foo')
          expect(@e).to be_kind_of(StandardError)
          expect(@sid).to eq('foo')
        end
      end
    end

    context 'when the encoded data is invalid' do
      before do
        allow(store).to receive(:redis)
          .and_return(double('redis', get: "\x00\x00\x00\x00", del: true))
      end

      it 'returns an empty session' do
        expect(store.send(:load_session_from_redis, 'bar')).to be_nil
      end

      it 'destroys and drops the session' do
        expect(store).to receive(:destroy_session_from_sid)
          .with('wut', drop: true)
        store.send(:load_session_from_redis, 'wut')
      end

      context 'when a custom on_session_load_error handler is provided' do
        before do
          store.on_session_load_error = lambda do |e, sid|
            @e = e
            @sid = sid
          end
        end

        it 'passes the error and the sid to the handler' do
          store.send(:load_session_from_redis, 'foo')
          expect(@e).to be_kind_of(StandardError)
          expect(@sid).to eq('foo')
        end
      end
    end
  end

  describe 'validating custom handlers' do
    %w(on_redis_down on_session_load_error).each do |h|
      context 'when nil' do
        it 'does not explode at init' do
          expect { store }.to_not raise_error
        end
      end

      context 'when callable' do
        let(:options) { { :"#{h}" => ->(*) { !nil } } }

        it 'does not explode at init' do
          expect { store }.to_not raise_error
        end
      end

      context 'when not callable' do
        let(:options) { { :"#{h}" => 'herpderp' } }

        it 'explodes at init' do
          expect { store }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'setting the session' do
    it 'allows changing the session' do
      env = { 'rack.session.options' => {} }
      sid = 1234
      allow(store).to receive(:redis).and_return(Redis.new)
      data1 = { 'foo' => 'bar' }
      store.send(:set_session, env, sid, data1)
      data2 = { 'baz' => 'wat' }
      store.send(:set_session, env, sid, data2)
      _, session = store.send(:get_session, env, sid)
      expect(session).to eq(data2)
    end

    it 'allows changing the session when the session has an expiry' do
      env = { 'rack.session.options' => { expire_after: 60 } }
      sid = 1234
      allow(store).to receive(:redis).and_return(Redis.new)
      data1 = { 'foo' => 'bar' }
      store.send(:set_session, env, sid, data1)
      data2 = { 'baz' => 'wat' }
      store.send(:set_session, env, sid, data2)
      _, session = store.send(:get_session, env, sid)
      expect(session).to eq(data2)
    end
  end
end
