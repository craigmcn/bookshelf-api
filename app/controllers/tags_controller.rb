class TagsController < ApplicationController
  skip_before_action :require_login, only: [:index]

  def index
    tags = Tag.order(:name)
    tags = tags.where(category: params[:category]) if params[:category].present? && Tag.categories.key?(params[:category])
    render json: {tags: tags.map { |t| {id: t.id, name: t.name, category: t.category} }}
  end
end
