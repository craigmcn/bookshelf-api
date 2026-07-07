class ReadingsController < ApplicationController
  before_action :set_reading, only: %i[show update destroy]

  def index
    readings = current_user.readings.includes(:book)
    render json: {readings: readings.map { |r| reading_json(r) }}
  end

  def show
    authorize @reading
    render json: {reading: reading_json(@reading)}
  end

  def create
    @reading = Reading.new(reading_params.merge(user_id: current_user.id))
    authorize @reading

    if @reading.save
      render json: {reading: reading_json(@reading)}, status: :created
    else
      render json: {errors: @reading.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @reading
    if @reading.update(reading_params)
      render json: {reading: reading_json(@reading)}
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

  def reading_params
    params.expect(reading: [:book_id, :status, :rating, :review])
  end

  def reading_json(reading)
    {
      id: reading.id,
      status: reading.status,
      rating: reading.rating,
      review: reading.review,
      deleted_at: reading.deleted_at,
      book: {
        id: reading.book.id,
        title: reading.book.title,
        author: reading.book.author,
        cover_url: reading.book.cover_url
      }
    }
  end
end
