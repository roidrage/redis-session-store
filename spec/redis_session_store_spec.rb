# vim:fileencoding=utf-8
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
    default_options[:namespace].should == 'rack:session'
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
      store.instance_variable_get(:@redis).should_not be_nil
    end

    it 'assigns the :host option to @default_options' do
      default_options[:host].should == 'hosty.local'
    end

    it 'assigns the :port option to @default_options' do
      default_options[:port].should == 16_379
    end

    it 'assigns the :db option to @default_options' do
      default_options[:db].should == 2
    end

    it 'assigns the :key_prefix option to @default_options' do
      default_options[:key_prefix].should == 'myapp:session:'
    end

    it 'assigns the :expire_after option to @default_options' do
      default_options[:expire_after].should == 60 * 120
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
      store.instance_variable_get(:@redis).should_not be_nil
    end

    it 'assigns the :host option to @default_options' do
      default_options[:host].should == 'hostersons.local'
    end

    it 'assigns the :port option to @default_options' do
      default_options[:port].should == 26_379
    end

    it 'assigns the :db option to @default_options' do
      default_options[:db].should == 4
    end

    it 'assigns the :key_prefix option to @default_options' do
      default_options[:key_prefix].should == 'appydoo:session:'
    end

    it 'assigns the :expire_after option to @default_options' do
      default_options[:expire_after].should == 60 * 60
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
        store.send(:set_session, env, session_id, session_data, options)
          .should eq(session_id)
      end
    end

    context 'when unsuccessfully persisting the session' do
      before do
        store.stub(:redis).and_raise(Errno::ECONNREFUSED)
      end

      it 'returns false' do
        store.send(:set_session, env, session_id, session_data, options)
          .should eq(false)
      end
    end

    context 'when no expire_after option is given' do
      let(:options) { {} }

      it 'sets the session value without expiry' do
        store.send(:set_session, env, session_id, session_data, options)
          .should eq(session_id)
      end
    end

    context 'when redis is down' do
      before do
        store.stub(:redis).and_raise(Errno::ECONNREFUSED)
        store.on_redis_down = ->(*a) { @redis_down_handled = true }
      end

      it 'returns false' do
        store.send(:set_session, env, session_id, session_data, options)
          .should eq(false)
      end

      it 'calls the on_redis_down handler' do
        store.send(:set_session, env, session_id, session_data, options)
        expect(@redis_down_handled).to be_true
      end

      context 'when :on_redis_down re-raises' do
        before { store.on_redis_down = ->(e, *) { fail e } }

        it 'explodes' do
          expect do
            store.send(:set_session, env, session_id, session_data, options)
          end.to raise_error(Errno::ECONNREFUSED)
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

    it 'should retrieve the prefixed key from redis' do
      redis = double('redis')
      store.stub(redis: redis)
      store.stub(generate_sid: fake_key)
      expect(redis).to receive(:get).with("#{options[:key_prefix]}#{fake_key}")

      store.send(:get_session, double('env'), fake_key)
    end

    context 'when redis is down' do
      before do
        store.stub(:redis).and_raise(Errno::ECONNREFUSED)
        store.stub(generate_sid: 'foop')
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
        before { store.on_redis_down = ->(e, *) { fail e } }

        it 'explodes' do
          expect do
            store.send(:get_session, double('env'), fake_key)
          end.to raise_error(Errno::ECONNREFUSED)
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
        cookie_hash.stub(:[] => fake_key)
      end

      it 'deletes the prefixed key from redis' do
        redis = double('redis')
        store.stub(redis: redis)
        expect(redis).to receive(:del)
          .with("#{options[:key_prefix]}#{fake_key}")

        store.send(:destroy, env)
      end

      context 'when redis is down' do
        before { store.stub(:redis).and_raise(Errno::ECONNREFUSED) }

        it 'should return false' do
          expect(store.send(:destroy, env)).to be_false
        end

        context 'when :on_redis_down re-raises' do
          before { store.on_redis_down = ->(e, *) { fail e } }

          it 'explodes' do
            expect do
              store.send(:destroy, env)
            end.to raise_error(Errno::ECONNREFUSED)
          end
        end
      end
    end

    context 'when destroyed via #destroy_session' do
      it 'deletes the prefixed key from redis' do
        redis = double('redis', get: nil)
        store.stub(redis: redis)
        sid = store.send(:generate_sid)
        expect(redis).to receive(:del).with("#{options[:key_prefix]}#{sid}")

        store.send(:destroy_session, {}, sid, nil)
      end
    end
  end

  describe 'generating a sid' do
    before { store.on_sid_collision = ->(sid) { @sid = sid } }

    context 'when the generated sid is unique' do
      before do
        redis = double('redis', get: nil)
        store.stub(redis: redis)
      end

      it 'returns the sid' do
        expect(store.send(:generate_sid)).to_not be_nil
      end
    end

    context 'when there is a generated sid collision' do
      before do
        redis = double('redis', get: 'herp a derp')
        store.stub(redis: redis)
      end

      it 'passes the colliding sid to the collision handler' do
        store.send(:sid_collision?, 'whatever')
        expect(@sid).to eql('whatever')
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
      store.stub(:redis).and_return(redis)
    end

    shared_examples_for 'serializer' do
      it 'encodes correctly' do
        redis.should_receive(:set).with('12345', expected_encoding)
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
          def self.load(value)
            { 'some' => 'data' }
          end

          def self.dump(value)
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
        store.stub(
          redis: double('redis', get: "\x04\bo:\nNonExistentClass\x00")
        )
      end

      it 'returns an empty session' do
        expect(store.send(:load_session_from_redis, 'whatever')).to be_nil
      end

      context 'when a custom on_session_load_error handler is provided' do
        before do
          store.on_session_load_error = lambda do |e, sid, store|
            @e = e
            @sid = sid
            @store = store
          end
        end

        it 'passes the error and the sid to the handler' do
          store.send(:load_session_from_redis, 'foo')
          expect(@e).to be_kind_of(StandardError)
          expect(@sid).to eql('foo')
        end
      end
    end

    context 'when the encoded data is invalid' do
      before do
        store.stub(
          redis: double('redis', get: "\x00\x00\x00\x00")
        )
      end

      it 'returns an empty session' do
        expect(store.send(:load_session_from_redis, 'bar')).to be_nil
      end

      context 'when a custom on_session_load_error handler is provided' do
        before do
          store.on_session_load_error = lambda do |e, sid, store|
            @e = e
            @sid = sid
            @store = store
          end
        end

        it 'passes the error and the sid to the handler' do
          store.send(:load_session_from_redis, 'foo')
          expect(@e).to be_kind_of(StandardError)
          expect(@sid).to eql('foo')
          expect(@store).to be(store)
        end
      end
    end
  end

  describe 'validating custom handlers' do
    %w(on_redis_down on_sid_collision on_session_load_error).each do |h|
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
end
