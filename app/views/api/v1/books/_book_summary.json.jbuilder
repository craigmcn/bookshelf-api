json.extract! book, :id, :title, :author, :cover_url, :added_by_id, :created_at, :updated_at
# The contract requires these, but this app has no columns for them yet (#54), so they're empty.
json.merge!(isbn: nil, page_count: nil, published_on: nil, description: nil, subjects: [],
  series_id: nil, series_position: nil)
