ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    token = SecureRandom.hex(20)
    user.update_columns(remember_token: token)
    cookies[Clearance.configuration.cookie_name] = token
  end
end

# /api/v1 helpers: a cookie session plus the CSRF token its writes need.
class ActionDispatch::IntegrationTest
  def api_sign_in(user)
    sign_in_as(user)
    get api_v1_session_url
    @csrf_token = response.parsed_body.fetch("csrf_token")
  end

  # A JSON body with the session's CSRF token. GET params go in the query string instead,
  # since as: :json turns a GET into a POST override that api_only strips.
  def api_write(method, url, body = nil, headers: {})
    send(method, url, params: body&.to_json,
      headers: {"Content-Type" => "application/json", "X-CSRF-Token" => @csrf_token.to_s}.merge(headers))
  end
end
