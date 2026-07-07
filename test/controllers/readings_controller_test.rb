require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "guest cannot access readings" do
    get readings_url, as: :json
    assert_response :unauthorized
  end

  test "member can view their readings" do
    sign_in_as users(:member)
    get readings_url, as: :json
    assert_response :success
    assert response.parsed_body.key?("readings")
  end

  test "member can create a reading" do
    sign_in_as users(:member)
    assert_difference "Reading.count" do
      post readings_url, params: {reading: {book_id: books(:two).id, status: :reading}}, as: :json
    end
    assert_response :created
    assert_equal "reading", response.parsed_body.dig("reading", "status")
  end

  test "member can update their own reading" do
    sign_in_as users(:member)
    patch reading_url(@reading), params: {reading: {status: :finished, book_id: @reading.book_id}}, as: :json
    assert_response :success
    assert_equal "finished", @reading.reload.status
    assert_equal "finished", response.parsed_body.dig("reading", "status")
  end

  test "member cannot soft-delete a reading" do
    sign_in_as users(:member)
    assert_no_difference "Reading.count" do
      delete reading_url(@reading), as: :json
    end
    assert_response :forbidden
    assert_nil @reading.reload.deleted_at
  end

  test "moderator can soft-delete a reading" do
    sign_in_as users(:moderator)
    assert_no_difference "Reading.unscoped.count" do
      delete reading_url(@reading), as: :json
    end
    assert_response :no_content
    assert_not_nil @reading.reload.deleted_at
  end
end
