# community_bookshelf's /api/v1 contract (#84). Its own tree, not ApplicationController, because
# auth here is the Clearance cookie with a CSRF header on writes, answering in JSON.
class Api::V1::BaseController < ActionController::API
  include ActionController::Cookies
  # Only for valid_authenticity_token?/form_authenticity_token: protect_from_forgery is never
  # called, since its form-param check doesn't fit an SPA. verify_csrf_token! checks the header.
  include ActionController::RequestForgeryProtection
  include Pundit::Authorization
  include Pagy::Method
  include SearchQuery

  # Scopes mirror community_bookshelf's ApiToken::SCOPES, so tokens (#58) can slot in later.
  SCOPES = %w[read:books write:books read:readings write:readings read:tags].freeze
  ANONYMOUS_SCOPES = %w[read:books].freeze

  before_action { request.format = :json }
  before_action :authenticate!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # An Authorization header means token auth only, so a bad token is a 401 and never falls
  # back to the cookie. This app has no API tokens yet (#58), so every token is a bad one.
  def authenticate!
    token_auth? ? reject_invalid_token : authenticate_via_cookie!
  end

  # For reads that are public on the website: signed-out visitors get through.
  def authenticate_if_present!
    token_auth? ? reject_invalid_token : @cookie_user = clearance_session.current_user
  end

  def reject_token_auth
    render json: {error: "This endpoint takes a session cookie, not an API token"}, status: :forbidden if token_auth?
  end

  # HTML forms can't send JSON, and cross-site fetch can't send it without a CORS preflight.
  def require_json_body
    return if request.media_type == "application/json"

    render json: {error: "Content-Type must be application/json"}, status: :unsupported_media_type
  end

  def token_auth?
    request.authorization.present?
  end

  def reject_invalid_token
    render json: {error: "Invalid or missing API token"}, status: :unauthorized
  end

  def authenticate_via_cookie!
    @cookie_user = clearance_session.current_user
    return render json: {error: "Not signed in: send an API token or a session cookie"}, status: :unauthorized unless @cookie_user

    verify_csrf_token!
  end

  # Called directly rather than through protect_from_forgery, so it holds even in the test
  # env, which turns forgery protection off.
  def verify_csrf_token!
    return if request.get? || request.head?
    return if valid_authenticity_token?(session, request.headers["X-CSRF-Token"])

    render json: {error: "Invalid CSRF token"}, status: :forbidden
  end

  def clearance_session
    request.env[:clearance]
  end

  def current_user
    @cookie_user
  end

  # A cookie session can do everything, so it holds every scope. Signed-out visitors only
  # reach the actions that use authenticate_if_present!, and may only read books.
  def current_scopes
    @cookie_user ? SCOPES : ANONYMOUS_SCOPES
  end

  def require_scope!(scope)
    return if current_scopes.include?(scope.to_s)

    render json: {error: "Token missing required scope: #{scope}"}, status: :forbidden
  end

  def render_forbidden
    render json: {error: "You are not authorized to perform this action."}, status: :forbidden
  end

  def render_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
