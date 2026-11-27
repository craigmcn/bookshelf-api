class OpenLibraryService
  BASE_URL = "https://openlibrary.org"
  COVER_URL = "https://covers.openlibrary.org/b/id/%s-M.jpg"

  def self.search(query)
    return [] if query.blank?

    conn = Faraday.new(url: BASE_URL)
    response = conn.get("/search.json", {q: query, limit: 10, fields: "title,author_name,cover_i,key"})
    # Faraday doesn't raise on an error status, and a rate-limited or broken reply isn't our JSON.
    return [] unless response.success?

    data = JSON.parse(response.body)
    docs = data["docs"] if data.is_a?(Hash)
    return [] unless docs.is_a?(Array)

    docs.filter_map do |doc|
      next unless doc.is_a?(Hash) && doc["title"].present?

      {
        title: doc["title"],
        author: Array(doc["author_name"]).first || "Unknown",
        cover_url: doc["cover_i"] ? format(COVER_URL, doc["cover_i"]) : nil,
        open_library_key: doc["key"]
      }
    end
  rescue Faraday::Error, JSON::ParserError
    []
  end
end
