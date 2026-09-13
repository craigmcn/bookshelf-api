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

  test "mood_list and pace_list sync independently of tag_list and each other" do
    book = books(:one)
    book.update!(tag_list: "fantasy", mood_list: "dark", pace_list: "fast-paced")

    assert_equal ["fantasy"], book.tags.genre.pluck(:name)
    assert_equal ["dark"], book.tags.mood.pluck(:name)
    assert_equal ["fast-paced"], book.tags.pace.pluck(:name)
  end

  test "updating mood_list does not touch existing genre or pace tags" do
    book = books(:one)
    book.update!(tag_list: "fantasy", pace_list: "fast-paced")
    book.update!(mood_list: "dark")

    assert_equal ["fantasy"], book.reload.tags.genre.pluck(:name)
    assert_equal ["fast-paced"], book.tags.pace.pluck(:name)
    assert_equal ["dark"], book.tags.mood.pluck(:name)
  end

  test "similar_books ranks by tag overlap, excluding the book itself" do
    book = books(:one)
    same_two_tags = Book.create!(title: "Two Overlap", author: "A", added_by: users(:member))
    same_one_tag = Book.create!(title: "One Overlap", author: "A", added_by: users(:member))
    no_overlap = Book.create!(title: "No Overlap", author: "A", added_by: users(:member))

    book.update!(tag_list: "fantasy, adventure")
    same_two_tags.update!(tag_list: "fantasy, adventure")
    same_one_tag.update!(tag_list: "fantasy")
    no_overlap.update!(tag_list: "romance")

    assert_equal [same_two_tags, same_one_tag], book.similar_books
  end

  test "similar_books returns none when the book has no tags" do
    assert_equal [], books(:one).similar_books.to_a
  end

  test "recommended_for suggests books tagged like the user's finished or highly-rated reads" do
    member = users(:member)
    liked = books(:one)
    liked.update!(tag_list: "fantasy")
    liked.readings.create!(user: member, status: :finished)

    recommended = Book.create!(title: "Recommended", author: "A", added_by: member, tag_list: "fantasy")
    unrelated = Book.create!(title: "Unrelated", author: "A", added_by: member, tag_list: "romance")

    results = Book.recommended_for(member)
    assert_includes results, recommended
    assert_not_includes results, unrelated
    assert_not_includes results, liked
  end

  test "recommended_for excludes books already on the user's shelf" do
    member = users(:member)
    liked = books(:one)
    liked.update!(tag_list: "fantasy")
    liked.readings.create!(user: member, status: :finished)

    already_shelved = Book.create!(title: "Already Shelved", author: "A", added_by: member, tag_list: "fantasy")
    already_shelved.readings.create!(user: member, status: :want_to_read)

    assert_not_includes Book.recommended_for(member), already_shelved
  end

  test "recommended_for returns none for a nil user" do
    assert_equal [], Book.recommended_for(nil).to_a
  end
end
