class ApplicationController < ActionController::API
  # ActionController::API does not include CSRF protection by default.
  # The admin namespace enables it explicitly (see Api::Admin::*Controller).
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies

  # ActionController::API does not inherit `allow_forgery_protection` from the
  # app config (only ActionController::Base does), so mirror it here.
  # In development/production it stays unset (CSRF enabled via
  # `protect_from_forgery` in the admin controllers); in the test environment
  # it follows config/environments/test.rb and is disabled.
  configured_forgery = Rails.application.config.action_controller.allow_forgery_protection
  self.allow_forgery_protection = configured_forgery unless configured_forgery.nil?

  private

  # The admin session cookie is HttpOnly; the CSRF token cookie is NOT
  # HttpOnly so the frontend can read it when both apps share an origin.
  # The same ENV flags used for the session cookie must apply here.
  def admin_cookie_secure?
    ENV.fetch("ADMIN_COOKIE_SECURE", Rails.env.production?.to_s) == "true"
  end

  def admin_cookie_samesite
    ENV.fetch("ADMIN_COOKIE_SAMESITE", "lax").to_sym
  end

  def set_csrf_cookie
    cookies[:csrf_token] = {
      value: form_authenticity_token,
      path: "/",
      secure: admin_cookie_secure?,
      same_site: admin_cookie_samesite,
      httponly: false
    }
  end
end
