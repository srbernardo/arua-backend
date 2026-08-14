# Cross-Origin Resource Sharing (CORS)
#
# The admin session uses an HttpOnly cookie, so credentialed cross-origin
# requests must be explicitly allowed. Origins are configured through ENV
# (comma separated) and default to the local development servers.
#
#   CORS_ORIGINS="https://admin.arua.pt,https://arua.pt"
#
# `credentials: true` is required for the browser to send/store cookies.
# Wildcard origins are NOT used together with credentials.

allowed_origins =
  ENV.fetch("CORS_ORIGINS", "http://localhost:5173,http://localhost:3000")
     .split(",")
     .map(&:strip)
     .reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 600
  end
end
