class TagsController < ApplicationController
  skip_before_action :require_login, only: [:index]

  def index
    tags = Tag.order(:name)
    render json: {tags: tags.map { |t| {id: t.id, name: t.name} }}
  end
end
