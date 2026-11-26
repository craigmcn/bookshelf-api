class User < ApplicationRecord
  include Clearance::User

  DEFAULT_PASSWORD = "correct-horse-shelf".freeze
  DELETED_PLACEHOLDER_EMAIL = "deleted-user@bookshelf-api.invalid"

  class SoleAdminError < StandardError; end

  has_many :readings, dependent: :destroy
  has_many :books, foreign_key: :added_by_id
  has_many :role_assignments, dependent: :destroy
  has_many :roles, through: :role_assignments

  validates :email, presence: true, uniqueness: true
  validates :name, length: {maximum: 100}
  validates :bio, length: {maximum: 500}

  after_create :assign_default_role

  scope :excluding_deleted_placeholder, -> { where.not(email: DELETED_PLACEHOLDER_EMAIL) }

  def display_name = name.presence || email

  def admin?
    roles.exists?(name: "admin")
  end

  def moderator?
    roles.exists?(name: "moderator")
  end

  def member?
    !admin? && !moderator?
  end

  def moderator_or_above?
    moderator? || admin?
  end

  def primary_role
    return "admin" if admin?
    return "moderator" if moderator?

    "member"
  end

  # True for an admin with no other admin to hand the role to — deleting this
  # account would lock every /admin route with no recovery path short of a
  # console.
  def sole_admin?
    admin? && self.class.joins(:roles).where(roles: {name: "admin"}).where.not(id: id).none?
  end

  # Reassigns this user's contributed catalog books to a shared placeholder
  # account (so the book catalog isn't disrupted by an account deletion),
  # then destroys the user — cascading to their own role assignments via
  # dependent: :destroy. Readings' default scope hides soft-deleted rows from
  # that association, so they're destroyed explicitly first — otherwise one
  # left behind would still reference this user's id via its FK and the
  # final destroy! would fail.
  def delete_account!
    raise SoleAdminError, "Can't delete the only admin account." if sole_admin?

    transaction do
      books.update_all(added_by_id: self.class.deleted_placeholder.id)
      Reading.unscoped.where(user_id: id).delete_all
      destroy!
    end
  end

  # Two concurrent account deletions can both miss the find below before
  # either has created this placeholder. Depending on timing, the loser's
  # create! surfaces the collision as either a real ActiveRecord::RecordNotUnique
  # (the DB unique index, if both inserts race before either commits) or an
  # ActiveRecord::RecordInvalid (the uniqueness validation, if the winner's
  # insert already committed and is merely visible in time) — both rescued here.
  def self.deleted_placeholder
    find_by(email: DELETED_PLACEHOLDER_EMAIL) || create!(
      email: DELETED_PLACEHOLDER_EMAIL,
      name: "Deleted user",
      password: SecureRandom.hex(32)
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    find_by!(email: DELETED_PLACEHOLDER_EMAIL)
  end

  private

  def assign_default_role
    member_role = Role.find_by(name: "member")
    roles << member_role if member_role
  end
end
