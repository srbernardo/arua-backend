require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AruaBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # ------------------------------------------------------------------
    # Admin session authentication (Devise + cookie store, no JWT)
    #
    # API-only apps do not include cookies/session middleware by default.
    # We add them back so the browser stores the admin session as an
    # HttpOnly cookie. The cookie flags are configurable through ENV so
    # the same code works in development and production:
    #
    #   ADMIN_COOKIE_SECURE   "true"/"false" (default: true in production)
    #   ADMIN_COOKIE_SAMESITE "lax"/"none"/"strict" (default: "lax")
    #   ADMIN_COOKIE_DOMAIN   optional domain for shared-parent-domain setups
    #                         (e.g. ".arua.pt" when API lives on a subdomain)
    # ------------------------------------------------------------------
    admin_cookie_secure = ENV.fetch("ADMIN_COOKIE_SECURE", Rails.env.production?.to_s) == "true"
    admin_cookie_samesite = ENV.fetch("ADMIN_COOKIE_SAMESITE", "lax").to_sym

    admin_session_options = {
      key: "_arua_admin_session",
      path: "/",
      httponly: true,
      secure: admin_cookie_secure,
      same_site: admin_cookie_samesite
    }
    admin_session_options[:domain] = ENV["ADMIN_COOKIE_DOMAIN"] if ENV["ADMIN_COOKIE_DOMAIN"].present?

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, admin_session_options
  end
end
