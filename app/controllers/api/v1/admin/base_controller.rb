# Cookie-only, so an API token can never change roles or read members' emails.
class Api::V1::Admin::BaseController < Api::V1::BaseController
  before_action :reject_token_auth
  before_action :require_moderator_or_above

  private

  def require_moderator_or_above
    render_forbidden unless current_user.moderator_or_above?
  end

  def require_admin
    render_forbidden unless current_user.admin?
  end
end
