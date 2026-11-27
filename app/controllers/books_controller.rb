class BooksController < ApplicationController
  skip_before_action :require_login, only: [:similar]
  before_action :set_book, only: %i[similar]

  def similar
    authorize @book, :show?
    render json: {books: policy_scope(@book.similar_books).map { |b| book_json(b) }}
  end

  def recommended
    render json: {books: policy_scope(Book.recommended_for(current_user)).map { |b| book_json(b) }}
  end

  private

  def set_book
    @book = Book.find(params.expect(:id))
  end

  def book_json(book)
    loaded_tags = book.tags.to_a
    {
      id: book.id,
      title: book.title,
      author: book.author,
      cover_url: book.cover_url,
      added_by_id: book.added_by_id,
      tags: loaded_tags.select(&:genre?).map(&:name).sort,
      mood_tags: loaded_tags.select(&:mood?).map(&:name).sort,
      pace_tags: loaded_tags.select(&:pace?).map(&:name).sort
    }
  end
end
