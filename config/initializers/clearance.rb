Clearance.configure do |config|
  config.mailer_sender = "reply@example.com"
  config.rotate_csrf_on_sign_in = false

  # The React SPA is a separate origin from this API in production, so the
  # remember_token cookie needs SameSite=None (which requires Secure) to be
  # sent on cross-origin requests at all.
  config.same_site = Rails.env.production? ? :none : :lax
  config.secure_cookie = Rails.env.production?
end
