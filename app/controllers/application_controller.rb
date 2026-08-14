class ApplicationController < ActionController::API
  # ActionController::API does not include CSRF protection by default.
  # The admin namespace enables it explicitly (see Api::Admin::*Controller).
  include ActionController::RequestForgeryProtection

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
