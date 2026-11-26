require "test_helper"

# Ported from community_bookshelf's Api::V1::BooksControllerTest, with cookie sessions in place
# of API tokens (#58).
class Api::V1::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  test "signed-out visitors can list and show books" do
    get api_v1_books_url
    assert_response :success
    body = response.parsed_body
    assert_equal Book.count, body["books"].size
    assert_equal({"page" => 1, "pages" => 1, "count" => Book.count}, body["pagination"])

    get api_v1_book_url(@book)
    assert_response :success
    assert_equal @book.title, response.parsed_body["title"]
  end

  test "a book has every field the contract requires, empty where this app has no column" do
    @book.update!(tag_list: "fantasy, adventure", mood_list: "dark", pace_list: "fast-paced")

    get api_v1_book_url(@book)

    book = response.parsed_body
    assert_equal %w[added_by_id author cover_url created_at description id isbn mood_list pace_list page_count
      published_on series_id series_position subjects tag_list title updated_at], book.keys.sort
    assert_equal ["adventure, fantasy", "dark", "fast-paced"], book.values_at("tag_list", "mood_list", "pace_list")
    assert_equal [], book["subjects"]
  end

  test "index searches title and author, case-insensitively" do
    get api_v1_books_url, params: {q: "gatsby"}
    assert_equal [@book.title], response.parsed_body["books"].pluck("title")

    get api_v1_books_url, params: {q: "ORWELL"}
    assert_equal [books(:two).title], response.parsed_body["books"].pluck("title")

    get api_v1_books_url, params: {q: "nonexistent title"}
    assert_equal [], response.parsed_body["books"]
  end

  test "index treats an array or hash search param as no search" do
    get api_v1_books_url, params: {q: ["nothing-matches-this"]}
    assert_response :success
    assert_equal Book.count, response.parsed_body["books"].size

    get api_v1_books_url, params: {q: {k: "nothing-matches-this"}}
    assert_response :success
    assert_equal Book.count, response.parsed_body["books"].size
  end

  # The tag lists used to run three queries per book.
  test "the catalog's query count doesn't grow with the number of tagged books" do
    @book.update!(tag_list: "classic", mood_list: "reflective", pace_list: "slow")
    baseline = catalog_query_count

    3.times { |i| Book.create!(title: "Tagged #{i}", author: "A", added_by: users(:member), tag_list: "classic, drama", mood_list: "dark", pace_list: "fast") }

    assert_equal baseline, catalog_query_count
    tagged = response.parsed_body["books"].find { |book| book["title"] == "Tagged 0" }
    assert_equal ["classic, drama", "dark", "fast"], tagged.values_at("tag_list", "mood_list", "pace_list")
  end

  test "signed-out visitors cannot write books" do
    assert_no_difference "Book.count" do
      api_write :post, api_v1_books_url, {book: {title: "New Book", author: "Some Author"}}
      assert_response :unauthorized

      api_write :delete, api_v1_book_url(@book)
      assert_response :unauthorized
    end

    api_write :patch, api_v1_book_url(@book), {book: {title: "Changed"}}
    assert_response :unauthorized
    assert_not_equal "Changed", @book.reload.title
  end

  test "any Authorization header is a 401, since this app has no API tokens yet" do
    get api_v1_books_url, headers: {"Authorization" => "Bearer not-a-real-token"}
    assert_response :unauthorized
    assert_equal({"error" => "Invalid or missing API token"}, response.parsed_body)

    get api_v1_book_url(@book), headers: {"Authorization" => "Bearer not-a-real-token"}
    assert_response :unauthorized
  end

  test "member can create a book, with tags" do
    api_sign_in users(:member)

    assert_difference "Book.count" do
      api_write :post, api_v1_books_url, {book: {title: "New Book", author: "Some Author", tag_list: "sci-fi, adventure", mood_list: "dark"}}
    end

    assert_response :created
    body = response.parsed_body
    assert_equal ["New Book", "adventure, sci-fi", "dark", users(:member).id], body.values_at("title", "tag_list", "mood_list", "added_by_id")
  end

  test "create with invalid params returns 422 with errors" do
    api_sign_in users(:member)

    assert_no_difference "Book.count" do
      api_write :post, api_v1_books_url, {book: {title: ""}}
    end
    assert_response :unprocessable_content
    assert response.parsed_body["errors"].present?
  end

  test "member cannot update or destroy a book" do
    api_sign_in users(:member)

    api_write :patch, api_v1_book_url(@book), {book: {title: "Changed"}}
    assert_response :forbidden
    assert_not_equal "Changed", @book.reload.title

    assert_no_difference "Book.count" do
      api_write :delete, api_v1_book_url(@book)
    end
    assert_response :forbidden
  end

  test "moderator can update a book's title and tags" do
    api_sign_in users(:moderator)

    api_write :patch, api_v1_book_url(@book), {book: {title: "Updated", tag_list: "classic"}}

    assert_response :success
    assert_equal ["Updated", "classic"], response.parsed_body.values_at("title", "tag_list")
    assert_equal "Updated", @book.reload.title
  end

  test "admin can destroy a book" do
    api_sign_in users(:admin)

    assert_difference "Book.count", -1 do
      api_write :delete, api_v1_book_url(@book)
    end
    assert_response :no_content
  end

  test "an unknown book is a JSON 404" do
    get api_v1_book_url(id: 0)
    assert_response :not_found
    assert_equal({"error" => "Not found"}, response.parsed_body)
  end

  private

  def catalog_query_count
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get api_v1_books_url }
    assert_response :success
    count
  end
end
