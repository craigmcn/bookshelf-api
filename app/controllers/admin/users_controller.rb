class Admin::UsersController < Admin::BaseController
  before_action :require_admin

  def index
    users = User.all.order(:email).includes(:roles)
    render json: {
      users: users.map { |u|
        {id: u.id, email: u.email, roles: u.roles.map(&:name)}
      },
      available_roles: Role.all.order(:name).pluck(:name)
    }
  end

  def update
    user = User.find(params[:id])
    user.roles = Role.where(id: params.dig(:user, :role_ids) || [])
    render json: {user: {id: user.id, email: user.email, roles: user.roles.pluck(:name)}}
  end
end
