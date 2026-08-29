require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "valid credentials return 201 with user JSON" do
    post session_url, params: {session: {email: users(:member).email, password: User::DEFAULT_PASSWORD}},
      as: :json
    assert_response :created
    assert_equal users(:member).email, response.parsed_body.dig("user", "email")
    assert_includes response.parsed_body.dig("user", "roles"), "member"
  end

  test "valid credentials set the remember_token cookie" do
    # Fixtures skip the before_create callback that generates a remember_token,
    # so backfill one here to exercise the same cookie-setting path a real
    # sign-in hits (see config/application.rb for why middleware order matters).
    users(:member).update_columns(remember_token: SecureRandom.hex(20))

    post session_url, params: {session: {email: users(:member).email, password: User::DEFAULT_PASSWORD}},
      as: :json
    assert_response :created
    assert_match(/remember_token/, response.headers["Set-Cookie"].to_s)
  end

  test "invalid credentials return 401" do
    post session_url, params: {session: {email: users(:member).email, password: "wrong"}}, as: :json
    assert_response :unauthorized
  end

  test "authenticated user can restore session" do
    sign_in_as users(:member)
    get session_url, as: :json
    assert_response :success
    assert_equal users(:member).email, response.parsed_body.dig("user", "email")
  end

  test "unauthenticated session check returns 401" do
    get session_url, as: :json
    assert_response :unauthorized
  end

  test "sign out returns 204" do
    sign_in_as users(:member)
    delete session_url, as: :json
    assert_response :no_content
  end
end
