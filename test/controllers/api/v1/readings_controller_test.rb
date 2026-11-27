require "test_helper"

# Ported from community_bookshelf's Api::V1::ReadingsControllerTest, with cookie sessions in
# place of API tokens (#58).
class Api::V1::ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "signed out, or with any Authorization header, is a 401" do
    get api_v1_readings_url
    assert_response :unauthorized

    get api_v1_readings_url, headers: {"Authorization" => "Bearer not-a-real-token"}
    assert_response :unauthorized
  end

  test "member's index only shows their own readings" do
    Reading.create!(user: users(:admin), book: books(:two), status: :reading)
    api_sign_in users(:member)

    get api_v1_readings_url

    assert_response :success
    assert_equal [@reading.id], response.parsed_body["readings"].pluck("id")
  end

  test "a reading has every field the contract requires, with string enums" do
    api_sign_in users(:member)

    get api_v1_readings_url

    reading = response.parsed_body["readings"].first
    assert_equal %w[book book_id created_at finished_on format id is_review_public progress_percent rating review
      started_on status updated_at user_id], reading.keys.sort
    assert_equal ["want_to_read", "four", true], reading.values_at("status", "rating", "is_review_public")
  end

  test "index breaks updated_at ties by newest id, so paging is stable" do
    older = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    newer = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    tied_at = 1.day.from_now
    [older, newer].each { |reading| reading.update_column(:updated_at, tied_at) }
    api_sign_in users(:member)

    get api_v1_readings_url

    assert_equal [newer.id, older.id], response.parsed_body["readings"].pluck("id").first(2)
  end

  test "moderator's index shows every user's readings, and mine=true only their own" do
    other_reading = Reading.create!(user: users(:admin), book: books(:two), status: :reading)
    own = Reading.create!(user: users(:moderator), book: books(:two), status: :reading)
    api_sign_in users(:moderator)

    get api_v1_readings_url
    assert_equal [@reading.id, other_reading.id, own.id].sort, response.parsed_body["readings"].pluck("id").sort

    get api_v1_readings_url, params: {mine: "true"}
    assert_equal [own.id], response.parsed_body["readings"].pluck("id")
  end

  test "index nests each reading's book, without its tag lists" do
    Reading.create!(user: users(:member), book: books(:two), status: :reading)
    api_sign_in users(:member)

    get api_v1_readings_url

    # Bullet raises on an N+1, so two books also check the preload.
    books = response.parsed_body["readings"].pluck("book")
    assert_equal [books(:one).title, books(:two).title].sort, books.pluck("title").sort
    assert_includes books.first.keys, "cover_url"
    assert_not_includes books.first.keys, "tag_list"
  end

  test "status filters the index, and an unknown status is ignored" do
    other = Reading.create!(user: users(:member), book: books(:two), status: :finished)
    api_sign_in users(:member)

    get api_v1_readings_url, params: {status: "finished"}
    assert_equal [other.id], response.parsed_body["readings"].pluck("id")

    get api_v1_readings_url, params: {status: "bogus"}
    assert_equal 2, response.parsed_body["readings"].size
  end

  test "book_id limits the index to readings of that book" do
    other = Reading.create!(user: users(:member), book: books(:two), status: :reading)
    api_sign_in users(:member)

    get api_v1_readings_url, params: {book_id: books(:two).id}

    assert_equal [other.id], response.parsed_body["readings"].pluck("id")
  end

  test "a book_id that isn't a book matches nothing, and a blank one is ignored" do
    api_sign_in users(:member)

    ["not-a-book", "#{@reading.book_id}abc", "#{@reading.book_id}.9", "#{@reading.book_id},#{books(:two).id}", "-#{@reading.book_id}"].each do |book_id|
      get api_v1_readings_url, params: {book_id: book_id}
      assert_empty response.parsed_body["readings"], book_id
    end

    get api_v1_readings_url, params: {book_id: "9" * 30}
    assert_response :success
    assert_empty response.parsed_body["readings"]

    get api_v1_readings_url, params: {book_id: ""}
    assert_equal [@reading.id], response.parsed_body["readings"].pluck("id")
  end

  test "an array or hash book_id is ignored" do
    api_sign_in users(:member)

    get api_v1_readings_url, params: {book_id: {k: "1"}}
    assert_equal [@reading.id], response.parsed_body["readings"].pluck("id")

    get api_v1_readings_url, params: {book_id: ["1"]}
    assert_equal [@reading.id], response.parsed_body["readings"].pluck("id")
  end

  test "member can show their own reading, with its full book" do
    api_sign_in users(:member)

    get api_v1_reading_url(@reading)

    assert_response :success
    assert_equal [@reading.id, books(:one).title], [response.parsed_body["id"], response.parsed_body.dig("book", "title")]
    assert_includes response.parsed_body["book"].keys, "tag_list"
  end

  test "member cannot show another member's reading" do
    other = Reading.create!(user: users(:admin), book: books(:two), status: :reading)
    api_sign_in users(:member)

    get api_v1_reading_url(other)

    assert_response :forbidden
  end

  test "member can create a reading with a string rating" do
    api_sign_in users(:member)

    assert_difference "Reading.count" do
      api_write :post, api_v1_readings_url, {reading: {book_id: books(:two).id, status: "reading", rating: "five"}}
    end

    assert_response :created
    assert_equal ["reading", "five", users(:member).id], response.parsed_body.values_at("status", "rating", "user_id")
  end

  test "member can create a reading with dnf status" do
    api_sign_in users(:member)

    api_write :post, api_v1_readings_url, {reading: {book_id: books(:two).id, status: "dnf"}}

    assert_response :created
    assert_equal "dnf", response.parsed_body["status"]
  end

  test "an unknown status or rating, or a missing status, is a 422" do
    api_sign_in users(:member)

    [{status: nil}, {status: "dnf-ish"}, {status: "reading", rating: "six"}].each do |attrs|
      assert_no_difference "Reading.count" do
        api_write :post, api_v1_readings_url, {reading: attrs.merge(book_id: books(:two).id)}
      end
      assert_response :unprocessable_content, attrs.inspect
      assert response.parsed_body["errors"].present?
    end
  end

  test "member can update their own reading, and clear its rating" do
    api_sign_in users(:member)

    api_write :patch, api_v1_reading_url(@reading), {reading: {status: "finished", rating: nil}}

    assert_response :success
    @reading.reload
    assert_equal ["finished", nil], [@reading.status, @reading.rating]
  end

  test "member cannot destroy another member's reading" do
    other = Reading.create!(user: users(:moderator), book: books(:two), status: :reading)
    api_sign_in users(:member)

    api_write :delete, api_v1_reading_url(other)

    assert_response :forbidden
    assert_nil other.reload.deleted_at
  end

  test "moderator destroy soft-deletes a reading" do
    api_sign_in users(:moderator)

    assert_no_difference "Reading.unscoped.count" do
      api_write :delete, api_v1_reading_url(@reading)
    end
    assert_response :no_content
    assert_not_nil @reading.reload.deleted_at
  end
end
