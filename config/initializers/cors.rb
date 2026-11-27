# CORS_ORIGINS is a comma-separated allow-list, e.g. "https://app.example.com". Credentials are
# on, so every listed origin can make signed-in requests and read a user's CSRF token: list
# only origins trusted with users' sessions. Matches community_bookshelf's ApiCorsConfig.
module ApiCorsConfig
  # Plain http would let a network attacker inject script into a credentialed origin.
  # localhost is allowed for development (e.g. the SPA on :3150).
  ORIGIN_FORMAT = %r{\A(https://[^\s/]+|http://(localhost|127\.0\.0\.1)(:\d+)?)\z}

  def self.allowed_origins(raw = ENV.fetch("CORS_ORIGINS", "http://localhost:3150"))
    origins = raw.to_s.split(",").map(&:strip).compact_blank
    invalid = origins.grep_v(ORIGIN_FORMAT)
    raise ArgumentError, "CORS_ORIGINS entries must be https:// origins (or http://localhost): #{invalid.join(", ")}" if invalid.any?

    origins
  end

  # Shared with the CORS test, so it exercises the real policy rather than a copy.
  # Every path, not just /api/v1: sign-up and account still live at the root until their slices.
  def self.apply(cors, origins)
    cors.allow do
      origins(*origins)

      resource "*",
        headers: :any,
        methods: [:get, :post, :patch, :put, :delete, :options, :head],
        credentials: true
    end
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  ApiCorsConfig.apply(self, ApiCorsConfig.allowed_origins)
end
