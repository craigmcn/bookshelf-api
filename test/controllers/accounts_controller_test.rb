require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "guest cannot view account" do
    get account_url, as: :json
    assert_response :unauthorized
  end

  test "member can view their account" do
    sign_in_as users(:member)
    get account_url, as: :json
    assert_response :success
    assert_equal users(:member).email, response.parsed_body.dig("user", "email")
  end

  test "member can update their name and bio" do
    sign_in_as users(:member)
    patch account_url, params: {user: {name: "Jo March", bio: "Writer."}}, as: :json
    assert_response :success
    assert_equal "Jo March", users(:member).reload.name
    assert_equal "Jo March", response.parsed_body.dig("user", "name")
    assert_equal "Writer.", response.parsed_body.dig("user", "bio")
  end

  test "account update rejects a bio over the length limit" do
    sign_in_as users(:member)
    patch account_url, params: {user: {bio: "x" * 501}}, as: :json
    assert_response :unprocessable_content
    assert_nil users(:member).reload.bio
  end

  test "guest cannot delete an account" do
    delete account_url, as: :json
    assert_response :unauthorized
  end

  test "member can delete their account with the correct password" do
    member = users(:member)
    sign_in_as member
    delete account_url, params: {current_password: User::DEFAULT_PASSWORD}, as: :json
    assert_response :no_content
    assert_not User.exists?(member.id)
  end

  test "member cannot delete their account with the wrong password" do
    sign_in_as users(:member)
    assert_no_difference "User.count" do
      delete account_url, params: {current_password: "wrong"}, as: :json
    end
    assert_response :unprocessable_content
  end

  test "deleting an account reassigns their books to the deleted-user placeholder" do
    sign_in_as users(:member)
    book = books(:one)
    assert_equal users(:member), book.added_by

    delete account_url, params: {current_password: User::DEFAULT_PASSWORD}, as: :json
    assert_response :no_content

    assert_equal User::DELETED_PLACEHOLDER_EMAIL, book.reload.added_by.email
  end

  test "deleting an account destroys their readings, including soft-deleted ones" do
    sign_in_as users(:member)
    reading = readings(:one)
    reading.soft_delete

    assert_difference "Reading.unscoped.count", -1 do
      delete account_url, params: {current_password: User::DEFAULT_PASSWORD}, as: :json
    end
    assert_response :no_content
  end

  test "the sole admin cannot delete their account" do
    sign_in_as users(:admin)
    assert_no_difference "User.count" do
      delete account_url, params: {current_password: User::DEFAULT_PASSWORD}, as: :json
    end
    assert_response :unprocessable_content
  end

  test "an admin can delete their account when another admin exists" do
    other_admin = User.create!(email: "other-admin@example.com", password: User::DEFAULT_PASSWORD)
    other_admin.roles << roles(:admin)
    admin = users(:admin)

    sign_in_as admin
    delete account_url, params: {current_password: User::DEFAULT_PASSWORD}, as: :json
    assert_response :no_content
    assert_not User.exists?(admin.id)
  end
end
