require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "guest cannot access admin users" do
    get admin_users_url, as: :json
    assert_response :unauthorized
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_users_url, as: :json
    assert_response :forbidden
  end

  test "admin can list users" do
    sign_in_as users(:admin)
    get admin_users_url, as: :json
    assert_response :success
    assert response.parsed_body.key?("users")
    assert response.parsed_body.key?("available_roles")
  end

  test "admin can update a user role" do
    sign_in_as users(:admin)
    patch admin_user_url(users(:member)), params: {user: {role_ids: [roles(:moderator).id]}}, as: :json
    assert_response :success
    assert users(:member).reload.moderator?
    assert_equal users(:member).email, response.parsed_body.dig("user", "email")
  end
end
