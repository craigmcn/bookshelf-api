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
end
