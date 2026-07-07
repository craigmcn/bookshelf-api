class Admin::ReadingsController < Admin::BaseController
  def index
    readings = Reading.with_deleted.where.not(review: [nil, ""])
      .includes(:user, :book)
      .order(updated_at: :desc)

    render json: {
      readings: readings.map { |r|
        {
          id: r.id,
          review: r.review,
          status: r.status,
          rating: r.rating,
          deleted_at: r.deleted_at,
          updated_at: r.updated_at,
          user: {id: r.user.id, email: r.user.email},
          book: {id: r.book.id, title: r.book.title, author: r.book.author}
        }
      }
    }
  end
end
