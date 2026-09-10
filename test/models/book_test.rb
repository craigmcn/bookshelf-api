require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "valid with title, author, and added_by" do
    assert Book.new(title: "Test", author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without title" do
    assert_not Book.new(author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without author" do
    assert_not Book.new(title: "Test", added_by: users(:member)).valid?
  end

  test "tag_list creates tags and associates them with the book" do
    book = books(:one)
    book.update!(tag_list: "Fantasy, Adventure")
    assert_equal ["adventure", "fantasy"], book.tags.order(:name).pluck(:name)
  end

  test "tag_list reuses an existing tag instead of duplicating it" do
    existing = Tag.create!(name: "fantasy")
    book = books(:one)
    book.update!(tag_list: "fantasy")
    assert_equal [existing.id], book.tags.pluck(:id)
  end

  test "tag_list removes tags no longer present in the list" do
    book = books(:one)
    book.update!(tag_list: "fantasy, adventure")
    book.update!(tag_list: "fantasy")
    assert_equal ["fantasy"], book.tags.pluck(:name)
  end

  test "tag_list getter returns the book's current tags as a comma-separated string" do
    book = books(:one)
    book.update!(tag_list: "fantasy, adventure")
    assert_equal "adventure, fantasy", book.reload.tag_list
  end

  test "omitting tag_list on update leaves existing tags alone" do
    book = books(:one)
    book.update!(tag_list: "fantasy")
    book.update!(title: "New Title")
    assert_equal ["fantasy"], book.reload.tags.pluck(:name)
  end

  test "tag_list sync does not raise if the tagging was already created concurrently" do
    book = books(:one)
    tag = Tag.create!(name: "fantasy")
    book.taggings.create!(tag: tag)

    assert_nothing_raised do
      book.send(:create_tagging, tag.id)
    end
  end
end
