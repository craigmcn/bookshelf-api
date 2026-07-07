Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, replace with the deployed SPA origin
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip).compact_blank

    resource "*",
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      credentials: true
  end
end
