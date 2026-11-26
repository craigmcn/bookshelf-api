require "test_helper"

# Ported from community_bookshelf's Api::ConditionalGetTest.
class Api::V1::ConditionalGetTest < ActionDispatch::IntegrationTest
  test "book show 304s on a matching If-None-Match, and flips to 200 once the book changes" do
    book = books(:one)
    get api_v1_book_url(book)
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_book_url(book), headers: {"If-None-Match" => etag}
    assert_response :not_modified

    book.update!(title: "A New Title")
    get api_v1_book_url(book), headers: {"If-None-Match" => etag}
    assert_response :success
  end

  test "book show 304 flips back to 200 when only its tags change" do
    book = books(:one)
    get api_v1_book_url(book)
    etag = response.headers["ETag"]

    book.update!(tag_list: "classic")

    get api_v1_book_url(book), headers: {"If-None-Match" => etag}
    assert_response :success
    assert_equal "classic", response.parsed_body["tag_list"]
  end

  test "books index 304s on a matching If-None-Match" do
    get api_v1_books_url
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_books_url, headers: {"If-None-Match" => etag}
    assert_response :not_modified
  end

  test "books index 304 flips back to 200 when a book on a later page is deleted" do
    19.times { |i| Book.create!(title: "Zzz #{i}", author: "Someone", added_by: users(:member)) }
    get api_v1_books_url
    etag = response.headers["ETag"]
    assert_equal 2, response.parsed_body.dig("pagination", "pages")

    Book.find_by!(title: "Zzz 9").destroy! # sorts last, so it's on page 2

    get api_v1_books_url, headers: {"If-None-Match" => etag}
    assert_response :success
    assert_equal 1, response.parsed_body.dig("pagination", "pages")
  end

  test "reading show 304s, and flips to 200 when only the nested book changes" do
    reading = readings(:one)
    api_sign_in reading.user
    get api_v1_reading_url(reading)
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_reading_url(reading), headers: {"If-None-Match" => etag}
    assert_response :not_modified

    reading.book.update!(title: "A Completely Different Title")
    get api_v1_reading_url(reading), headers: {"If-None-Match" => etag}
    assert_response :success
  end

  test "readings index 304s, and flips to 200 when only a nested book changes" do
    reading = readings(:one)
    api_sign_in reading.user
    get api_v1_readings_url
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_readings_url, headers: {"If-None-Match" => etag}
    assert_response :not_modified

    reading.book.update!(title: "A Completely Different Title")
    get api_v1_readings_url, headers: {"If-None-Match" => etag}
    assert_response :success
  end

  test "readings index 304 flips back to 200 when a reading itself changes" do
    reading = readings(:one)
    api_sign_in reading.user
    get api_v1_readings_url
    etag = response.headers["ETag"]

    reading.update!(status: :finished)

    get api_v1_readings_url, headers: {"If-None-Match" => etag}
    assert_response :success
    assert_equal "finished", response.parsed_body["readings"].first["status"]
  end

  # The ETag must cover each row and the total, or pagination and removed rows go stale.
  test "readings index 304 flips back to 200 when a reading on a later page is removed" do
    member = users(:member)
    extra = 20.times.map { Reading.create!(user: member, book: books(:two), status: :want_to_read) }
    Reading.where(id: extra.first.id).update_all(updated_at: 1.year.ago)
    api_sign_in member
    get api_v1_readings_url
    etag = response.headers["ETag"]
    assert_equal 2, response.parsed_body.dig("pagination", "pages")

    # A member can't delete their own reading through the API yet (#96).
    extra.first.soft_delete

    get api_v1_readings_url, headers: {"If-None-Match" => etag}
    assert_response :success
    assert_equal 1, response.parsed_body.dig("pagination", "pages")
  end

  # A full page: the next row slides in, so the page's row count and newest updated_at stay the same.
  test "readings index 304 flips back to 200 when a reading mid-page is removed" do
    member = users(:member)
    readings = 25.times.map { Reading.create!(user: member, book: books(:two), status: :want_to_read) }
    api_sign_in member
    get api_v1_readings_url, params: {book_id: books(:two).id}
    etag = response.headers["ETag"]

    readings[-3].soft_delete

    get api_v1_readings_url, params: {book_id: books(:two).id}, headers: {"If-None-Match" => etag}
    assert_response :success
    assert_not_includes response.parsed_body["readings"].pluck("id"), readings[-3].id
  end
end
