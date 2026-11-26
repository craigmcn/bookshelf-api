require "test_helper"

class Api::V1::Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors get a 401" do
    get api_v1_admin_dashboard_url
    assert_response :unauthorized
  end

  test "members and moderators get a 403" do
    [:member, :moderator].each do |user|
      sign_in_as users(user)
      get api_v1_admin_dashboard_url
      assert_response :forbidden
      assert_equal({"error" => "You are not authorized to perform this action."}, JSON.parse(response.body))
    end
  end

  # Admin endpoints are cookie-only, so even an admin's signed-in cookie doesn't rescue a token.
  test "an Authorization header is refused" do
    sign_in_as users(:admin)
    get api_v1_admin_dashboard_url, headers: {"Authorization" => "Bearer anything"}
    assert_response :unauthorized
  end

  test "an admin sees totals, without the deleted-user placeholder, and the most-read books" do
    user_count = User.count
    User.deleted_placeholder
    2.times { Reading.create!(user: users(:member), book: books(:two), status: :want_to_read) }

    sign_in_as users(:admin)
    get api_v1_admin_dashboard_url

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [user_count, Book.count, Reading.count], body.values_at("total_users", "total_books", "total_readings")
    assert_equal({"id" => books(:two).id, "title" => "1984", "author" => "George Orwell", "readings_count" => 2}, body["popular_books"].first)
    assert_equal [2, 1], body["popular_books"].pluck("readings_count")
  end

  # The top list is cut at 5, so ties need a stable order or books swap between reloads (#102).
  test "books tied on readings count are listed newest first" do
    tied = 2.times.map { |i| Book.create!(title: "Tied #{i}", author: "A", added_by: users(:member)) }
    [books(:one), books(:two), *tied].each { |book| Reading.create!(user: users(:admin), book: book, status: :want_to_read) }

    sign_in_as users(:admin)
    get api_v1_admin_dashboard_url

    popular = JSON.parse(response.body)["popular_books"]
    tied_ids = popular.select { |book| book["readings_count"] == 1 }.pluck("id")
    assert_equal tied_ids.sort.reverse, tied_ids
  end
end
