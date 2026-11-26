require "test_helper"

# Similar and recommended stay at their old paths until community_bookshelf#219 adds them to
# the contract; everything else moved to Api::V1::BooksControllerTest.
class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  test "anyone can view similar books" do
    other = Book.create!(title: "Other", author: "A", added_by: users(:member))
    @book.update!(tag_list: "fantasy")
    other.update!(tag_list: "fantasy")

    get similar_book_url(@book), as: :json
    assert_response :success
    titles = response.parsed_body["books"].pluck("title")
    assert_equal [other.title], titles
  end

  test "similar books each show their full tag list, not just the overlapping tag" do
    first = Book.create!(title: "First", author: "A", added_by: users(:member), tag_list: "fantasy, adventure")
    second = Book.create!(title: "Second", author: "A", added_by: users(:member), tag_list: "fantasy, classic")
    @book.update!(tag_list: "fantasy")

    get similar_book_url(@book), as: :json
    assert_response :success
    tags_by_title = response.parsed_body["books"].to_h { |b| [b["title"], b["tags"]] }
    assert_equal ["adventure", "fantasy"], tags_by_title[first.title]
    assert_equal ["classic", "fantasy"], tags_by_title[second.title]
  end

  test "guest cannot view recommended books" do
    get recommended_books_url, as: :json
    assert_response :unauthorized
  end

  test "member can view their recommended books" do
    liked = @book
    liked.update!(tag_list: "fantasy")
    liked.readings.create!(user: users(:member), status: :finished)
    recommended = Book.create!(title: "Recommended", author: "A", added_by: users(:member), tag_list: "fantasy")

    sign_in_as users(:member)
    get recommended_books_url, as: :json
    assert_response :success
    titles = response.parsed_body["books"].pluck("title")
    assert_equal [recommended.title], titles
  end
end
