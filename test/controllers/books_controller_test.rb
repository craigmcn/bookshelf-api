require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  # Public access
  test "anyone can view books index" do
    get books_url, as: :json
    assert_response :success
    assert response.parsed_body.key?("books")
  end

  test "books index includes pagination metadata" do
    get books_url, as: :json
    assert_response :success
    pagination = response.parsed_body["pagination"]
    assert_equal 1, pagination["page"]
    assert_equal Book.count, pagination["count"]
  end

  test "books index can be searched by title or author" do
    # GET requests with a params: hash and as: :json rely on Rack::MethodOverride
    # to translate Rails' test-only POST+X-Http-Method-Override trick back to a
    # GET — a middleware config.api_only strips and this app never re-adds. Pass
    # the query string inline instead of via params: to sidestep it.
    get "/books?q=gatsby", as: :json
    assert_response :success
    titles = response.parsed_body["books"].pluck("title")
    assert_equal [@book.title], titles
  end

  test "books index search is case-insensitive and matches author" do
    get "/books?q=ORWELL", as: :json
    assert_response :success
    titles = response.parsed_body["books"].pluck("title")
    assert_equal [books(:two).title], titles
  end

  test "books index search with no matches returns an empty list" do
    get "/books?q=#{CGI.escape("nonexistent title")}", as: :json
    assert_response :success
    assert_equal [], response.parsed_body["books"]
  end

  test "books index ignores a non-string q param instead of erroring" do
    get "/books?q[]=x", as: :json
    assert_response :success
  end

  test "anyone can view a book" do
    get book_url(@book), as: :json
    assert_response :success
    assert_equal @book.title, response.parsed_body.dig("book", "title")
  end

  # Auth wall
  test "guest cannot create a book" do
    post books_url, params: {book: {title: "New", author: "Author"}}, as: :json
    assert_response :unauthorized
  end

  # Member permissions
  test "member can create a book" do
    sign_in_as users(:member)
    assert_difference "Book.count" do
      post books_url, params: {book: {title: "New Book", author: "Some Author", cover_url: ""}}, as: :json
    end
    assert_response :created
    assert_equal "New Book", response.parsed_body.dig("book", "title")
  end

  test "member cannot update a book" do
    sign_in_as users(:member)
    patch book_url(@book), params: {book: {title: "Changed", author: @book.author, cover_url: @book.cover_url}},
      as: :json
    assert_response :forbidden
    assert_not_equal "Changed", @book.reload.title
  end

  test "member cannot destroy a book" do
    sign_in_as users(:member)
    assert_no_difference "Book.count" do
      delete book_url(@book), as: :json
    end
    assert_response :forbidden
  end

  # Moderator/admin permissions
  test "moderator can update a book" do
    sign_in_as users(:moderator)
    patch book_url(@book), params: {book: {title: "Updated", author: @book.author, cover_url: @book.cover_url}},
      as: :json
    assert_response :success
    assert_equal "Updated", @book.reload.title
    assert_equal "Updated", response.parsed_body.dig("book", "title")
  end

  test "moderator can destroy a book" do
    sign_in_as users(:moderator)
    assert_difference "Book.count", -1 do
      delete book_url(@book), as: :json
    end
    assert_response :no_content
  end
end
