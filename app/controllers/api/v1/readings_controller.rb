class Api::V1::ReadingsController < Api::V1::BaseController
  before_action -> { require_scope!("read:readings") }, only: %i[index show]
  before_action -> { require_scope!("write:readings") }, only: %i[create update destroy]
  before_action :set_reading, only: %i[show update destroy]

  def index
    @readings = policy_scope(Reading).includes(:book)

    # Moderators' index holds everyone's readings; a "my shelf" page needs only its owner's.
    @readings = @readings.where(user: current_user) if params[:mine] == "true"

    # Digits only: Rails would cast "12abc" to 12, and a hash would become a nested condition.
    if params[:book_id].is_a?(String) && params[:book_id].present?
      @readings = params[:book_id].match?(/\A\d+\z/) ? @readings.where(book_id: params[:book_id]) : @readings.none
    end

    if params[:status].present? && Reading.statuses.key?(params[:status])
      @readings = @readings.where(status: params[:status])
    end

    @readings = @readings.order(updated_at: :desc, id: :desc)
    @pagy, @readings = pagy(@readings)
    # Keyed on each row, its nested book and the total, for the same reason as the books index.
    readings = @readings.to_a
    books = readings.map(&:book)
    fresh_when(etag: [readings, books, @pagy.count], last_modified: [*readings, *books].map(&:updated_at).max)
  end

  def show
    authorize @reading
    # The response nests the book, so a book-only edit must bust the ETag too.
    fresh_when(etag: [@reading, @reading.book], last_modified: [@reading.updated_at, @reading.book.updated_at].max)
  end

  def create
    @reading = Reading.new(reading_params.merge(user_id: current_user.id))
    authorize @reading

    if @reading.save
      render :show, status: :created
    else
      render json: {errors: @reading.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @reading
    if @reading.update(reading_params)
      render :show
    else
      render json: {errors: @reading.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @reading
    @reading.soft_delete
    head :no_content
  end

  private

  def set_reading
    @reading = Reading.with_deleted.find(params.expect(:id))
  end

  # Dates, progress, format and review visibility have no columns here yet (#25, #26, #55).
  def reading_params
    params.expect(reading: [:book_id, :status, :rating, :review])
  end
end
