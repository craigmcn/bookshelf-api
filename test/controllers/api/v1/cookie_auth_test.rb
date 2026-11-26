require "test_helper"

# Ported from community_bookshelf's Api::CookieAuthTest: cookie sessions and their CSRF check.
class Api::V1::CookieAuthTest < ActionDispatch::IntegrationTest
  setup { users(:member).reset_remember_token! }

  test "a cookie write without the CSRF token is a 403" do
    sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers

    assert_response :forbidden
    assert_equal({"error" => "Invalid CSRF token"}, response.parsed_body)
  end

  test "a cookie write with the CSRF token succeeds" do
    csrf_token = sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token)

    assert_response :created
  end

  test "a cookie PATCH needs the CSRF token too" do
    csrf_token = sign_in_via_api

    patch api_v1_reading_url(readings(:one)), params: {reading: {status: "finished"}}.to_json, headers: json_headers
    assert_response :forbidden

    patch api_v1_reading_url(readings(:one)), params: {reading: {status: "finished"}}.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token)
    assert_response :success
  end

  test "signing in again makes the earlier CSRF token stale" do
    old_token = sign_in_via_api
    sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => old_token)

    assert_response :forbidden
  end

  test "the CSRF token from GET /session also works" do
    sign_in_as users(:member)
    get api_v1_session_url
    csrf_token = response.parsed_body["csrf_token"]

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token)

    assert_response :created
  end

  test "an Authorization header is a 401 even with a valid cookie" do
    csrf_token = sign_in_via_api

    get api_v1_books_url, headers: {"Authorization" => "Bearer garbage"}
    assert_response :unauthorized
    assert_equal({"error" => "Invalid or missing API token"}, response.parsed_body)

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token, "Authorization" => "Bearer garbage")
    assert_response :unauthorized
  end

  private

  def json_headers
    {"Content-Type" => "application/json"}
  end

  def reading_params
    {reading: {book_id: books(:two).id, status: "reading"}}
  end

  def sign_in_via_api
    post api_v1_session_url, params: {email: "member@example.com", password: "correct-horse-shelf"}.to_json, headers: json_headers
    assert_response :created
    response.parsed_body["csrf_token"]
  end
end
