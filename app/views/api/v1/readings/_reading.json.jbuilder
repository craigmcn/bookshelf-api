json.extract! reading, :id, :book_id, :user_id, :status, :rating, :review, :created_at, :updated_at
# The contract requires these, but this app has no columns for them yet (#25, #26, #55).
# is_review_public is the reference's default.
json.merge!(is_review_public: true, started_on: nil, finished_on: nil, progress_percent: nil, format: nil)
