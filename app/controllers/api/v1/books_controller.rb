class Api::V1::BooksController < Api::V1::BaseController
  # The catalog is public, so signed-out reads work.
  skip_before_action :authenticate!, only: %i[index show]
  before_action :authenticate_if_present!, only: %i[index show]
  before_action -> { require_scope!("read:books") }, only: %i[index show]
  before_action -> { require_scope!("write:books") }, only: %i[create update destroy]
  before_action :set_book, only: %i[show update destroy]

  def index
    @books = policy_scope(Book)

    @query = search_query
    if @query
      query = "%#{@query}%"
      @books = @books.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
    end

    @books = @books.order(:title, :id)
    @pagy, @books = pagy(@books)
    # Keyed on each row plus the total: a relation's own key is only its SQL, row count and
    # newest updated_at, so a book deleted from a later page could 304 a stale page.
    books = @books.to_a
    return unless stale?(etag: [books, @pagy.count], last_modified: books.map(&:updated_at).max)

    # Only when rendering: a 304 never reads the tags, and Bullet flags an unused preload.
    ActiveRecord::Associations::Preloader.new(records: books, associations: :tags).call
  end

  def show
    authorize @book
    fresh_when @book
  end

  def create
    @book = Book.new(book_params.merge(added_by: current_user))
    authorize @book

    if @book.save
      render :show, status: :created
    else
      render json: {errors: @book.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @book
    if @book.update(book_params)
      render :show
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

  # The contract's other BookInput fields (isbn, page_count, series...) have no columns here
  # yet (#54), so they're dropped like any unpermitted param.
  def book_params
    params.expect(book: [:title, :author, :cover_url, :tag_list, :mood_list, :pace_list])
  end
end
