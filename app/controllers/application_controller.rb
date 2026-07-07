class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Clearance::Controller
  include Pundit::Authorization

  before_action :require_login

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def deny_access(flash_message = nil)
    render json: {error: "Unauthorized"}, status: :unauthorized
  end

  def user_not_authorized
    render json: {error: "Forbidden"}, status: :forbidden
  end
end
