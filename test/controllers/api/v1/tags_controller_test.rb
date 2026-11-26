require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  test "signed out is a 401" do
    get api_v1_tags_url
    assert_response :unauthorized
  end

  test "a signed-in member lists all tags" do
    api_sign_in users(:member)
    get api_v1_tags_url
    assert_response :success
    assert_equal Tag.count, JSON.parse(response.body)["tags"].size
  end

  test "filters by category" do
    mood_tag = Tag.create!(name: "cozy", category: "mood")

    api_sign_in users(:member)

    get api_v1_tags_url, params: {category: "mood"}
    assert_response :success

    json = JSON.parse(response.body)["tags"]
    assert_equal [mood_tag.id], json.pluck("id")
  end

  test "an unrecognized category is ignored, returning all tags" do
    api_sign_in users(:member)
    get api_v1_tags_url, params: {category: "bogus"}
    assert_response :success
    assert_equal Tag.count, JSON.parse(response.body)["tags"].size
  end
end
