# vim:fileencoding=utf-8

unless defined?(Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY)
  module Rack # rubocop:disable Documentation
    module Session
      module Abstract # rubocop:disable Documentation
        ENV_SESSION_OPTIONS_KEY = 'rack.session.options'.freeze
      end
    end
  end
end

unless defined?(ActionDispatch::Session::AbstractStore)
  module ActionDispatch # rubocop:disable Documentation
    module Session
      class AbstractStore # rubocop:disable Documentation
        ENV_SESSION_OPTIONS_KEY = 'rack.session.options'.freeze
        DEFAULT_OPTIONS = {
          key: '_session_id',
          path: '/',
          domain: nil,
          expire_after: nil,
          secure: false,
          httponly: true,
          cookie_only: true
        }.freeze

        def initialize(app, options = {})
          @app = app
          @default_options = DEFAULT_OPTIONS.dup.merge(options)
          @key = @default_options[:key]
          @cookie_only = @default_options[:cookie_only]
        end

        private

        def generate_sid
          rand(999..9999).to_s(16)
        end
      end
    end
  end
end

unless defined?(Rails)
  require 'logger'

  module Rails # rubocop:disable Documentation
    def self.logger
      @logger ||= Logger.new('/dev/null')
    end
  end
end
