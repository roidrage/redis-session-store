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
end
