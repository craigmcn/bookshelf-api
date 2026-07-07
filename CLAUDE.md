# Bookshelf API

Rails 8 JSON API backend for the community bookshelf app. Paired with `bookshelf-spa` (React SPA frontend). Forked from `community_bookshelf` and converted to API-only mode.

## Tech Stack

- **Ruby** 3.x / **Rails** 8.1.3 (`config.api_only = true`)
- **Database**: PostgreSQL
- **Authentication**: Clearance (cookie-based signed token; cookies/session middleware added back to API stack)
- **Authorization**: Pundit (policy classes)
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
```

## CORS & Auth

- CORS origins are set via the `CORS_ORIGINS` env var (comma-separated). Defaults to `http://localhost:5173` (Vite dev server).
- Auth uses Clearance's signed cookie (`remember_token`). The React SPA must send requests with `credentials: 'include'`.
- Session cookie is `SameSite=Lax` in development; set `SameSite=None; Secure` for cross-origin production deploys.

### Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/session` | Sign in — body: `{ session: { email, password } }` → `{ user: { id, email, roles } }` |
| `DELETE` | `/session` | Sign out → 204 |
| `GET` | `/session` | Restore session (on page load) → `{ user }` or 401 |
| `POST` | `/users` | Register → Clearance default |

## API Endpoints

All responses are JSON. Errors: `{ errors: [...] }` (422) or `{ error: "..." }` (401/403/404).

```
GET    /books              public
GET    /books/:id          public (includes user_reading if signed in)
POST   /books              member+
PATCH  /books/:id          moderator+
DELETE /books/:id          moderator+

GET    /readings           owner (current user's readings)
GET    /readings/:id       owner or moderator+
POST   /readings           member+
PATCH  /readings/:id       owner or moderator+
DELETE /readings/:id       owner or moderator+ (soft delete)

GET    /book_search?q=...  member+ (proxies Open Library)

GET    /admin/dashboard    admin only
GET    /admin/readings     moderator+
GET    /admin/users        admin only
PATCH  /admin/users/:id    admin only (update roles)
```

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

# Reading#rating
one: 1, two: 2, three: 3, four: 4, five: 5
```

### Soft Deletes
Readings use `deleted_at`. Default scopes exclude deleted records; use `Reading.with_deleted` to include them.

## Authorization

- Pundit policies in `app/policies/` — all default to `false`
- Roles via `current_user.member?`, `.moderator?`, `.admin?`, `.moderator_or_above?`
- `Pundit::NotAuthorizedError` → 403 JSON

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
`OpenLibraryService.search(query)` returns an array of hashes with `:title`, `:author`, `:cover_url`.
