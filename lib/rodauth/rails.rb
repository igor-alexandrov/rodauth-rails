require "rodauth/rails/version"
require "rodauth/rails/railtie"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :Auth, "rodauth/rails/auth"
    autoload :Model, "rodauth/rails/model"

    @app = nil
    @middleware = true

    class << self
      def rodauth(name = nil, **options)
        warn "The Rodauth::Rails.rodauth method has been deprecated, and will be removed in version 1.1. Please use Rodauth::Rails::Auth.instance instead."

        auth_class = app.rodauth!(name)
        auth_class.instance(**options)
      end

      def model(name = nil, **options)
        Rodauth::Rails::Model.new(app.rodauth!(name), **options)
      end

      # routing constraint that requires authentication
      def authenticated(name = nil, &condition)
        lambda do |request|
          rodauth = request.env.fetch ["rodauth", *name].join(".")
          rodauth.require_authentication
          rodauth.authenticated? && (condition.nil? || condition.call(rodauth))
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.2")
        def secret_key_base
          ::Rails.application.secret_key_base
        end
      else
        def secret_key_base
          ::Rails.application.secrets.secret_key_base
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.0")
        def api_only?
          ::Rails.application.config.api_only
        end
      else
        def api_only?
          false
        end
      end

      def configure
        yield self
      end

      attr_writer :app
      attr_writer :middleware

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless @app

        @app.constantize
      end

      def middleware?
        @middleware
      end
    end
  end
end
