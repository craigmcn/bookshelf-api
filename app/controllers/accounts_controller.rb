class AccountsController < ApplicationController
  def show
    authorize current_user
    render json: account_json(current_user)
  end

  def update
    authorize current_user
    if current_user.update(account_params)
      render json: account_json(current_user)
    else
      render json: {errors: current_user.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize current_user

    if !current_user.authenticated?(params[:current_password])
      render json: {error: "Current password was incorrect."}, status: :unprocessable_content
    elsif current_user.sole_admin?
      render json: {error: "You're the only admin — promote another member to admin before deleting this account."},
        status: :unprocessable_content
    else
      user = current_user
      # sign_out must run before delete_account! destroys the record — it
      # writes a fresh remember_token to invalidate the session, which would
      # raise FrozenError against an already-destroyed (frozen) record.
      sign_out
      user.delete_account!
      head :no_content
    end
  end

  private

  def account_params
    params.expect(user: [:name, :bio])
  end

  def account_json(user)
    {user: {id: user.id, email: user.email, name: user.name, bio: user.bio, roles: user.roles.pluck(:name)}}
  end
end
