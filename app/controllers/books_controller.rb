class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_book, only: %i[show update destroy]

  def index
    @books = policy_scope(Book)

    query = params[:q].to_s.strip
    if query.present?
      like = "%#{query}%"
      @books = @books.where("books.title ILIKE :q OR books.author ILIKE :q", q: like)
    end

    tag_name = params[:tag].to_s.strip.downcase
    if tag_name.present?
      # A subquery, not @books.joins(:tags).where(tags: {name: tag_name}) —
      # joining :tags here would collide with the includes(:tags) preload
      # below and silently truncate it to just the matching tag instead of
      # every tag on the book.
      matching_book_ids = Tagging.joins(:tag).where(tags: {name: tag_name}).select(:book_id)
      @books = @books.where(id: matching_book_ids)
    end

    @books = @books.order(:title, :id)
    @pagy, @books = pagy(@books)
    @books = @books.includes(:tags)

    render json: {
      books: @books.map { |b| book_json(b) },
      pagination: {page: @pagy.page, pages: @pagy.pages, count: @pagy.count}
    }
  end

  def show
    authorize @book
    render json: {book: book_json(@book, current_user: current_user)}
  end

  def create
    @book = Book.new(book_params.merge(added_by: current_user))
    authorize @book

    if @book.save
      render json: {book: book_json(@book)}, status: :created
    else
      render json: {errors: @book.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @book
    if @book.update(book_params)
      render json: {book: book_json(@book)}
    else
      render json: {errors: @book.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @book
    @book.destroy!
    head :no_content
  end

  private

  def set_book
    @book = Book.find(params.expect(:id))
  end

  def book_params
    params.expect(book: [:title, :author, :cover_url, :tag_list])
  end

  def book_json(book, current_user: nil)
    json = {
      id: book.id,
      title: book.title,
      author: book.author,
      cover_url: book.cover_url,
      added_by_id: book.added_by_id,
      tags: book.tags.map(&:name).sort
    }
    if current_user
      reading = current_user.readings.find_by(book: book)
      json[:user_reading] = reading ? reading_json(reading) : nil
    end
    json
  end

  def reading_json(reading)
    {id: reading.id, status: reading.status, rating: reading.rating, review: reading.review}
  end
end
