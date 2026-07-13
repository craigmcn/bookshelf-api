require "test_helper"

class ReadingTest < ActiveSupport::TestCase
  test "valid with user, book, and status" do
    assert Reading.new(user: users(:member), book: books(:two), status: :want_to_read).valid?
  end

  test "invalid without status" do
    assert_not Reading.new(user: users(:member), book: books(:one)).valid?
  end

  test "rating serializes as an integer, not an enum label" do
    reading = readings(:one)
    assert_kind_of Integer, reading.rating
    assert_equal 4, reading.as_json["rating"]
  end

  test "invalid with rating outside 1..5" do
    reading = Reading.new(user: users(:member), book: books(:two), status: :want_to_read, rating: 6)
    assert_not reading.valid?
  end

  test "valid with nil rating" do
    assert Reading.new(user: users(:member), book: books(:two), status: :want_to_read, rating: nil).valid?
  end
end
