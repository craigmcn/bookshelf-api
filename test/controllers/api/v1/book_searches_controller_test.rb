require "test_helper"
require "webmock/minitest"

class Api::V1::BookSearchesControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors can't search Open Library" do
    get api_v1_book_search_url, params: {q: "gatsby"}
    assert_response :unauthorized
  end

  test "returns Open Library results" do
    stub_request(:get, "https://openlibrary.org/search.json")
      .with(query: hash_including({"q" => "gatsby"}))
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {docs: [{title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], cover_i: 7, key: "/works/OL468431W"}]}.to_json
      )

    api_sign_in users(:member)

    get api_v1_book_search_url, params: {q: "gatsby"}

    assert_response :success
    expected = {"title" => "The Great Gatsby", "author" => "F. Scott Fitzgerald",
                "cover_url" => "https://covers.openlibrary.org/b/id/7-M.jpg", "open_library_key" => "/works/OL468431W"}
    assert_equal({"results" => [expected]}, JSON.parse(response.body))
  end

  # WebMock would raise on an unstubbed call, so these also prove nothing was requested.
  test "a blank, array or hash query returns no results without calling Open Library" do
    api_sign_in users(:member)
    ["  ", ["gatsby"], {k: "gatsby"}].each do |q|
      get api_v1_book_search_url, params: {q: q}
      assert_response :success
      assert_equal({"results" => []}, JSON.parse(response.body))
    end
  end

  test "an Open Library outage returns no results, not a 500" do
    stub_request(:get, /openlibrary\.org\/search\.json/).to_return(status: 503, body: "<html>Down</html>")

    api_sign_in users(:member)

    get api_v1_book_search_url, params: {q: "gatsby"}

    assert_response :success
    assert_equal({"results" => []}, JSON.parse(response.body))
  end
end
