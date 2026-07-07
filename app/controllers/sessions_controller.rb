class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:create]

  # POST /session
  def create
    user = authenticate(params)
    if user
      sign_in(user)
      render json: user_json(user), status: :created
    else
      render json: {error: "Invalid email or password"}, status: :unauthorized
    end
  end

  # DELETE /session
  def destroy
    sign_out
    head :no_content
  end

  # GET /session — returns current user for session restore on page load
  def show
    if signed_in?
      render json: user_json(current_user)
    else
      render json: {error: "Not signed in"}, status: :unauthorized
    end
  end

  private

  def authenticate(params)
    User.authenticate(params.dig(:session, :email).to_s,
      params.dig(:session, :password).to_s)
  end

  def user_json(user)
    {
      user: {
        id: user.id,
        email: user.email,
        roles: user.roles.pluck(:name)
      }
    }
  end
end
