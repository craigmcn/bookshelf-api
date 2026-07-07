require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "guest cannot access admin dashboard" do
    get admin_root_url, as: :json
    assert_response :unauthorized
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_root_url, as: :json
    assert_response :forbidden
  end

  test "admin can access the dashboard" do
    sign_in_as users(:admin)
    get admin_root_url, as: :json
    assert_response :success
    assert response.parsed_body.key?("total_users")
  end
end
