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

  test "readings index includes pagination metadata" do
    sign_in_as users(:member)
    get readings_url, as: :json
    assert_response :success
    pagination = response.parsed_body["pagination"]
    assert_equal 1, pagination["page"]
    assert_equal users(:member).readings.count, pagination["count"]
  end

  test "readings index can be filtered by status" do
    sign_in_as users(:member)
    finished = Reading.create!(user: users(:member), book: books(:two), status: :finished)

    # GET requests with a params: hash and as: :json rely on Rack::MethodOverride
    # to translate Rails' test-only POST+X-Http-Method-Override trick back to a
    # GET — a middleware config.api_only strips and this app never re-adds. Pass
    # the query string inline instead of via params: to sidestep it.
    get "/readings?status=finished", as: :json
    assert_response :success
    ids = response.parsed_body["readings"].pluck("id")
    assert_equal [finished.id], ids
  end

  test "readings index ignores an unknown status filter value" do
    sign_in_as users(:member)
    get "/readings?status=bogus", as: :json
    assert_response :success
    assert_equal users(:member).readings.count, response.parsed_body["pagination"]["count"]
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
