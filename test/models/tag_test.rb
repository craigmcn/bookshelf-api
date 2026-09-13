require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid with a name" do
    assert Tag.new(name: "fantasy").valid?
  end

  test "invalid without a name" do
    assert_not Tag.new.valid?
  end

  test "name is normalized to a stripped, downcased value" do
    tag = Tag.create!(name: "  Fantasy  ")
    assert_equal "fantasy", tag.name
  end

  test "name is unique, case-insensitively via normalization" do
    Tag.create!(name: "fantasy")
    duplicate = Tag.new(name: "Fantasy")
    assert_not duplicate.valid?
  end

  test "category defaults to genre" do
    assert_equal "genre", Tag.create!(name: "fantasy").category
  end

  test "category can be mood or pace" do
    assert_equal "mood", Tag.create!(name: "dark", category: "mood").category
    assert_equal "pace", Tag.create!(name: "fast-paced", category: "pace").category
  end
end
