class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :book

  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  enum :status, {want_to_read: 0, reading: 1, finished: 2}

  validates :status, presence: true
  validates :rating, inclusion: {in: 1..5}, allow_nil: true

  def soft_delete
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
