# Bookshelf API

Rails 8 JSON API backend for the community bookshelf app. Paired with `bookshelf-spa` (React SPA frontend). Forked from `community_bookshelf` and converted to API-only mode.

## Tech Stack

- **Ruby** 3.x / **Rails** 8.1.3 (`config.api_only = true`)
- **Database**: PostgreSQL
- **Authentication**: Clearance (cookie-based signed token; cookies/session middleware added back to API stack)
- **Authorization**: Pundit (policy classes)
- **JSON views**: jbuilder (`app/views/api/v1/`)
- **CORS**: rack-cors (configured via `config/initializers/cors.rb`)
- **External API**: Open Library (book search + cover images via Faraday)
- **Background jobs / Cache**: solid_queue, solid_cache (DB-backed)
- **Testing**: Minitest
- **CI**: GitHub Actions (Brakeman, bundler-audit, StandardRB, full test suite vs PostgreSQL)
- **Deployment**: Docker + Kamal + Thruster

## Setup

```sh
bin/setup          # install deps, create/migrate DB, seed
bin/rails server   # start server on port 3000
```

## Common Commands

```sh
bin/rails test                          # full test suite
bin/rails test test/models/user_test.rb # single file

bin/rails routes                        # list all routes
bin/rails db:migrate                    # run pending migrations
bin/rails db:rollback                   # undo last migration
bin/rails db:seed                       # seed roles + users

bin/rubocop                             # lint (StandardRB via standard + standard-rails)
bin/rubocop -a                          # auto-correct safe offenses
bundle exec brakeman                    # security scan

bin/e2e_server                          # seeded test-env server for bookshelf-spa's real-backend Playwright project
```

`bin/e2e_server` resets the test DB (`db:test:prepare db:fixtures:load`), backfills
`remember_token` for fixture users (AR fixtures skip the `before_create` callback
Clearance needs for a real cookie-based sign-in), and boots Rails with
`OPEN_LIBRARY_STUB=1` (stubs `openlibrary.org/search.json` via WebMock — see
`config/initializers/open_library_stub.rb`) and `CORS_ORIGINS` defaulting to
`bookshelf-spa`'s dev port (3150). This repo has no Playwright suite of its own
(API-only, nothing to drive a browser against) — `bookshelf-spa`'s
`playwright.config.ts` starts this as a second `webServer` for its real-backend
parity project. Same shared fixture data as `community_bookshelf`/`bookshelf-islands`.

## The /api/v1 contract

This app serves community_bookshelf's `/api/v1` contract (its `doc/openapi.yaml` is the spec; #84). Controllers live in `app/controllers/api/v1/` and render jbuilder views in `app/views/api/v1/`, both ported from community_bookshelf. Keep them aligned with the reference when its contract changes.

- **Auth:** the Clearance cookie. `Api::V1::BaseController` (an `ActionController::API`, not `ApplicationController`) checks `X-CSRF-Token` on every write with `valid_authenticity_token?`, called directly so the test env's disabled forgery protection doesn't skip it. Any `Authorization` header is a 401 with no cookie fallback, because this app has no API tokens yet (#58). The scope checks (`require_scope!`) are already in place so tokens can slot in.
- **Session:** `GET`/`POST`/`DELETE /api/v1/session`. `POST` takes JSON only (415 otherwise; blocks login CSRF) with top-level `email`/`password`, and returns `{user: {id, email, name, display_name, roles}, csrf_token}`. It renders only after Clearance's `sign_in` returns, since `rotate_csrf_on_sign_in` replaces the token after the block runs.
- **Shapes:** single records render at the top level (`GET /books/:id` is the book, not `{book: ...}`). Errors are `{"error"}` for 400/401/403/404/415 and `{"errors": [...]}` for 422. Ratings and statuses are enum names (`"four"`, `"want_to_read"`). An unknown one is a 422, via `enum ..., validate:`.
- **Fields with no column yet** are sent empty, because the contract requires them: books' `isbn`/`page_count`/`published_on`/`description`/`series_*` as `null` and `subjects` as `[]` (#54), and readings' dates/progress/format as `null` and `is_review_public` as `true` (#25, #26, #55). Inputs for them are dropped like any unpermitted param.
- **Indexes:** `GET /books` is public (`authenticate_if_present!`), searches with `q` (read through the `SearchQuery` concern, so an array/hash `q` is no search), and preloads tags only after `stale?` (a 304 never reads them; Bullet flags an unused preload). `GET /readings` is the policy scope (everyone's, for a moderator), takes `mine=true`, `book_id` (digits only, otherwise nothing matches) and `status`, and nests each book's summary (no tag lists). Both key their ETag on each row plus `@pagy.count`, because a relation's own cache key is only its SQL, row count and newest `updated_at`. `Book#sync_tags_for_category` touches the book so tag edits bust it too.
- **Admin** (`/api/v1/admin/dashboard`, `users`, `readings`) is cookie-only (`reject_token_auth`). Role updates take names, not ids, read from `request.raw_post`, because Rails' deep munge turns `[null]` into `[]`, which would strip every role. Audit logging is #59.
- **Not in the contract yet:** sign-up (`POST /users`), `/account`, `GET /books/:id/similar` and `GET /books/recommended` keep their root paths and the old `ApplicationController` until their community_bookshelf#219 slices. The old `?tag=` filter on the books index was dropped, since the contract has none.
- **Tests:** `api_sign_in(user)` (test_helper) signs in by cookie and keeps the CSRF token, and `api_write` sends a JSON body with it. In api_only tests, pass GET params with `params:` and no `as: :json`: `as: :json` turns a GET into a method-override POST, and api_only strips `Rack::MethodOverride`.

## CORS & cookies

- `CORS_ORIGINS` (comma-separated, default `http://localhost:3150`) is validated by `ApiCorsConfig.allowed_origins` (`config/initializers/cors.rb`). Only `https://` origins and `http://localhost` are allowed, and a `*`, plain-http or scheme-less entry raises at boot, since credentials are on. CORS covers every path while sign-up and account remain at the root.
- The Clearance cookie is `SameSite=Lax`, and Secure wherever `force_ssl` is on (`config/initializers/clearance.rb`, #99). So the SPA must be deployed **same-site** with this API (e.g. `app.example.com` + `api.example.com`). A cross-site deployment would need `None`, which would also expose the cookie to cross-site requests.
- `config/application.rb` re-adds `ActionDispatch::Cookies`/`Session::CookieStore` (stripped by `api_only`) via `insert_before Clearance::RackSession`. They must sit *before* `Clearance::RackSession` in the middleware stack, not just appended with `.use`. Rack unwinds the response inside-out, so if Cookies were the more-inner middleware it would flush its jar before `Clearance::RackSession` wrote the remember_token, and `Set-Cookie` would silently never be sent. The session store also holds the CSRF token. Check with `Rails.application.middleware.each_with_index { |m, i| puts "#{i}: #{m.klass}" }` if auth cookies ever seem to stop working.
- `config/application.rb` loads `action_view/railtie`, which jbuilder needs.

## Domain Model

### Core Tables
- **books** — `title`, `author`, `cover_url`, `added_by_id` (FK → users)
- **readings** — `user_id`, `book_id`, `status` (enum), `rating` (enum), `review`, `deleted_at` (soft delete)
- **users** — Clearance authentication (email, encrypted_password, tokens)
- **roles** — `name`: `member | moderator | admin`
- **role_assignments** — join table users ↔ roles

### Enums
```ruby
# Reading#status
want_to_read: 0, reading: 1, finished: 2

# Reading#rating (stored as integers, sent as names)
one: 1, two: 2, three: 3, four: 4, five: 5
```

### Soft Deletes
Readings use `deleted_at`. Default scopes exclude deleted records; use `Reading.with_deleted` to include them.

## Authorization

- Pundit policies in `app/policies/` — all default to `false`
- Roles via `current_user.member?`, `.moderator?`, `.admin?`, `.moderator_or_above?`
- `Pundit::NotAuthorizedError` → 403 JSON (`{"error": "You are not authorized to perform this action."}` under `/api/v1`)

## Testing Conventions

- **Framework**: Minitest (no system tests — no browser)
- **Fixtures** over factories
- Controller tests use `sign_in_as(users(:member))` / `sign_in_as(users(:admin))`
- Always test three tiers: unauthenticated, member, moderator/admin

### Fixture Users
| Fixture | Role | Password |
|---|---|---|
| `users(:member)` | member | correct-horse-shelf |
| `users(:moderator)` | moderator | correct-horse-shelf |
| `users(:admin)` | admin | correct-horse-shelf |

## Key Patterns

### Adding a new policy check
1. Add method to `app/policies/<model>_policy.rb`
2. Call `authorize @record` in controller
3. Add fixture-based tests

### Open Library integration
`OpenLibraryService.search(query)` returns an array of hashes with `:title`, `:author`, `:cover_url`, `:open_library_key`, or `[]` when Open Library errors, rate-limits or replies with something unexpected (Faraday doesn't raise on an error status).
