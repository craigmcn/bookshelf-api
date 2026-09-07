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
end
