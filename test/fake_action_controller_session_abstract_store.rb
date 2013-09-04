unless defined?(ActionController::Session::AbstractStore)
  module ActionController
    module Session
      class AbstractStore
        def initialize(app, options = {})
          @app = app
          @default_options = {
            :key => '_session_id',
            :path => '/',
            :domain => nil,
            :expire_after => nil,
            :secure => false,
            :httponly => true,
            :cookie_only => true
          }.merge(options)
          @key = @default_options[:key]
          @cookie_only = @default_options[:cookie_only]
        end
      end
    end
  end
end
