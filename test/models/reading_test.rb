require "test_helper"

class ReadingTest < ActiveSupport::TestCase
  test "valid with user, book, and status" do
    assert Reading.new(user: users(:member), book: books(:two), status: :want_to_read).valid?
  end

  test "invalid without status" do
    assert_not Reading.new(user: users(:member), book: books(:one)).valid?
  end

  test "rating serializes as its /api/v1 enum name" do
    assert_equal "four", readings(:one).as_json["rating"]
  end

  test "an unknown rating or status is a validation error, not an exception" do
    assert_not Reading.new(user: users(:member), book: books(:two), status: :want_to_read, rating: "six").valid?
    assert_not Reading.new(user: users(:member), book: books(:two), status: "shelved").valid?
  end

  test "dnf is a valid status, matching the /api/v1 contract" do
    assert Reading.new(user: users(:member), book: books(:two), status: :dnf).valid?
  end

  test "for_moderation keeps a caller's earlier filters" do
    readings(:one).update_columns(deleted_at: Time.current)
    assert_includes Reading.with_deleted.for_moderation, readings(:one)
    assert_empty Reading.with_deleted.where(user: users(:admin)).for_moderation
  end

  test "valid with nil rating" do
    assert Reading.new(user: users(:member), book: books(:two), status: :want_to_read, rating: nil).valid?
  end
end
