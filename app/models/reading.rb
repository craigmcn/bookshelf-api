class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :book

  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  # validate: makes an unknown value a 422 rather than an ArgumentError (a 500).
  enum :status, {want_to_read: 0, reading: 1, finished: 2, dnf: 3}, validate: true
  enum :rating, {one: 1, two: 2, three: 3, four: 4, five: 5}, validate: {allow_nil: true}

  # Doesn't unscope itself, so callers chain it after with_deleted and keep their own filters.
  scope :for_moderation, -> { where.not(review: [nil, ""]).order(updated_at: :desc, id: :desc) }

  def soft_delete
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
