# vim:fileencoding=utf-8

unless defined?(ActionDispatch::Session::AbstractStore)
  module ActionDispatch # rubocop:disable Documentation
    module Session
      class AbstractStore
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
      end
    end
  end
end
