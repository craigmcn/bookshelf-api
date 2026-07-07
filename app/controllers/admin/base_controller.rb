class Admin::BaseController < ApplicationController
  before_action :require_moderator_or_above

  private

  def require_moderator_or_above
    render json: {error: "Forbidden"}, status: :forbidden unless current_user&.moderator_or_above?
  end

  def require_admin
    render json: {error: "Forbidden"}, status: :forbidden unless current_user&.admin?
  end
end
