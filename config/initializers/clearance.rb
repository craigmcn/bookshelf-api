Clearance.configure do |config|
  config.mailer_sender = "reply@example.com"
  # A fresh CSRF token on each sign-in, so one fixed before sign-in can't be reused after it.
  config.rotate_csrf_on_sign_in = true
  # Lax, not None: the SPA must be deployed same-site with the API (#99), which also keeps
  # the cookie off cross-site requests. Secure wherever SSL is enforced.
  config.same_site = :lax
  config.secure_cookie = Rails.application.config.force_ssl
end
