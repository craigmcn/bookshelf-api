source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "pg", "~> 1.7"
gem "puma", ">= 5.0"

# CORS handling for React SPA
gem "rack-cors"

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Authentication
gem "clearance"

# Authorization
gem "pundit"

# HTTP client
gem "faraday"

# Pagination
gem "pagy", "~> 43.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache and Active Job
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "standard", ">= 1.35.1", require: false
  gem "standard-rails", require: false

  # Detects N+1 queries and unused eager loading
  gem "bullet"

  # Generates realistic fake data for db/seeds.rb — needed in :test too since
  # `bin/ci` runs `RAILS_ENV=test bin/rails db:seed:replant`
  gem "faker"
end

group :development do
  gem "dotenv-rails"
end

group :test do
  # Stubs the Open Library HTTP call when booting the server for Playwright e2e runs
  # (see bookshelf-spa's real-backend e2e project)
  gem "webmock", require: false
end
