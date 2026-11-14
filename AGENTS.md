# Tree Recycle

Tree recycling fundraiser reservations, donations and pickup management application.

**Slogan:** Financials. Filings. Fundamentals.

## Stack

- Ruby on Rails 8.1 (PostgreSQL, Hotwire, Tailwind CSS)
- Rails 8 session authentication (`has_secure_password`, no Devise)
- Solid Queue, Solid Cache, Solid Cable
- Minitest with fixtures (model, controller, system tests)
- Secrets via `bin/rails credentials:edit`

## Principles

- Follow **The Rails Way**: convention over configuration, RESTful routing, fat models / skinny controllers, DRY
- Minimize third-party gems unless necessary
- Turbo for live UI updates; prefer Turbo Frames/Streams over custom JS
- API is RESTful and versioned under `/api/v1` (add `/v2` when needed)
- Shared view partials live in `app/views/shared/`
- Tailwind CSS with `dark:` variants driven by native `prefers-color-scheme` (no manual theme toggle)

### Development context

Before significant development work:

1. Read this file (`AGENTS.md`).
2. Read [`docs/roadmap.md`](docs/roadmap.md).
3. Read [`docs/development_state.md`](docs/development_state.md).
4. Inspect the existing application before assuming architecture, models, services, schema, or conventions.
5. Prefer extending existing Valivra patterns over introducing unnecessary abstractions.

**Source of truth:** source code, schema, tests, and configuration describe how Valivra actually works. Planning documents must not override or contradict the implementation.

## Area guidelines

| Area | Guidelines |
|------|------------|
| Models | [`app/models/AGENTS.md`](app/models/AGENTS.md) |
| Views | [`app/views/AGENTS.md`](app/views/AGENTS.md) |
| Controllers | [`app/controllers/AGENTS.md`](app/controllers/AGENTS.md) |
| Testing | [`test/AGENTS.md`](test/AGENTS.md) — Minitest + fixtures; model/controller/system minimum |
