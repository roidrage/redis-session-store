# vim:fileencoding=utf-8

unless defined?(ActionDispatch::Session::AbstractStore)
  module ActionDispatch
    module Session
      class AbstractStore
        def initialize(app, options = {})
          @app = app
          @default_options = {
            key: '_session_id',
            path: '/',
            domain: nil,
            expire_after: nil,
            secure: false,
            httponly: true,
            cookie_only: true
          }.merge(options)
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
