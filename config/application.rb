require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CommunityBookshelf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.api_only = true

    # Re-add cookie and session middleware so Clearance can use signed cookies.
    # Must come before Clearance::RackSession (inserted by Clearance's own railtie) —
    # `use` always appends to the end of the stack, which put Cookies *after*
    # RackSession here. Since Rack unwinds the response inside-out, Cookies was
    # flushing its (still-empty) jar before RackSession ever wrote the remember_token
    # into it, so `Set-Cookie` was silently never sent on a real sign-in.
    config.middleware.insert_before Clearance::RackSession, ActionDispatch::Cookies
    config.middleware.insert_after ActionDispatch::Cookies, ActionDispatch::Session::CookieStore

    config.autoload_lib(ignore: %w[assets tasks])
  end
end
