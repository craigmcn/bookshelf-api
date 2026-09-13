require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  test "anyone can view the tags index" do
    Tag.create!(name: "fantasy")
    Tag.create!(name: "adventure")

    get tags_url, as: :json
    assert_response :success
    names = response.parsed_body["tags"].pluck("name")
    assert_equal ["adventure", "fantasy"], names
  end

  test "tags index can be filtered by category" do
    Tag.create!(name: "fantasy", category: "genre")
    Tag.create!(name: "dark", category: "mood")

    get "/tags?category=mood", as: :json
    assert_response :success
    names = response.parsed_body["tags"].pluck("name")
    assert_equal ["dark"], names
  end

  test "tags index ignores an unknown category value" do
    Tag.create!(name: "fantasy", category: "genre")

    get "/tags?category=bogus", as: :json
    assert_response :success
    names = response.parsed_body["tags"].pluck("name")
    assert_equal ["fantasy"], names
  end
end
