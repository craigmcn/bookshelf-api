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
