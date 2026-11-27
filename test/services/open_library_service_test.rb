require "test_helper"
require "webmock/minitest"

class OpenLibraryServiceTest < ActiveSupport::TestCase
  test "search includes the open_library_key for each result" do
    stub_request(:get, /openlibrary\.org\/search\.json/)
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {docs: [{title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], key: "/works/OL468431W"}]}.to_json
      )

    results = OpenLibraryService.search("gatsby")

    assert_equal "/works/OL468431W", results.first[:open_library_key]
  end

  # Faraday doesn't raise on an error status, so each of these reached JSON.parse or #filter_map.
  test "search returns no results when Open Library fails or answers oddly" do
    [
      {status: 503, body: "<html>Down</html>"},
      {status: 429, body: "slow down"},
      {status: 500, body: {docs: [{title: "From an error page"}]}.to_json},
      {status: 200, body: ""},
      {status: 200, body: {numFound: 0}.to_json},
      {status: 200, body: [1, 2].to_json},
      {status: 200, body: {docs: "nope"}.to_json},
      {status: 200, body: {docs: [nil, "x", {title: "Kept"}]}.to_json}
    ].each do |reply|
      WebMock.reset!
      stub_request(:get, /openlibrary\.org\/search\.json/).to_return(**reply, headers: {"Content-Type" => "application/json"})

      results = OpenLibraryService.search("gatsby")

      expected = reply[:body].include?("Kept") ? ["Kept"] : []
      assert_equal expected, results.pluck(:title), reply.inspect
    end
  end
end
