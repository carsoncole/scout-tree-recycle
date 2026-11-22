# Tree Recycle

Tree recycling fundraiser reservations, donations and pickup management application.

## Stack

- Ruby 4.0.10 and Rails 8.1.4.1
- PostgreSQL, Hotwire, Tailwind CSS
- Rails 8 session authentication (`has_secure_password`, no Devise)
- Solid Queue, Solid Cache, Solid Cable
- Minitest with fixtures (model, controller, system tests)
- Secrets via `bin/rails credentials:edit`


## Core Principles - Follow The Rails Way

- Convention over Configuration (CoC) — Prefer Rails’ defaults and naming conventions over explicit configuration. (e.g., a User model maps to a users table; UsersController#index looks for app/views/users/index.html.erb.) This is the foundational idea.

- Don’t Repeat Yourself (DRY) — Eliminate duplication. Use concerns, shared modules, scopes, partials, helpers, and inheritance where appropriate instead of copying logic.

- Skinny Controllers, Fat Models — Keep controllers thin (mostly request handling, strong parameters, and rendering/redirecting). Put business logic, validations, queries, and domain rules in models (or model-related objects). Classic “Rails Way” advice is often summarized as “fat models, skinny controllers.”

- RESTful / Resourceful design — Design around resources and the seven standard actions (index, show, new, create, edit, update, destroy). Prefer resources/resource in routes; nest only one level deep (or use shallow nesting); map actions to HTTP verbs.


## Additional Principles

- Minimize third-party gems unless necessary
- Turbo for live UI updates; prefer Turbo Frames/Streams over custom JS
- Shared view partials live in `app/views/shared/`
- Tailwind CSS pre-defined classes vs custom styles is highly preferred.
- Tailwind CSS with `dark:` variants driven by native `prefers-color-scheme` (no manual theme toggle)


## Supporting Practices

- Follow MVC separation — Models handle data and domain logic, controllers handle HTTP flow, views handle presentation. Avoid leaking business logic into controllers or views.
Strong parameters — Always whitelist attributes with permit in controllers (never use params.permit! in production code).

- Use Active Record idioms — Scopes for reusable queries, associations with inverse_of where helpful, enums, validations, and careful use of callbacks. Prefer explicit service calls over heavy callback chains when logic gets complex.

- Avoid common pitfalls — Prevent N+1 queries (includes/preload/eager_load), prefer exists? over loading full records just to check presence, use find_each for large datasets, and keep views free of complex logic (use helpers, decorators, or presenters when needed).

- Naming and structure conventions — Stick to Rails’ expected file/class naming, Zeitwerk autoloading rules, and standard project layout so the framework can do the work for you.

- Testing — Use Minitest for testing. Write tests that exercise behavior, especially around models and important flows.

- Omakase / prefer defaults — Use the tools and patterns Rails provides (Active Record, Action Mailer, Active Storage, Turbo, etc.) unless you have a strong reason not to. The framework is designed so you don’t reinvent everything.


### Development context

Before significant development work:

1. Read this file (`AGENTS.md`).
2. Inspect the existing application before assuming architecture, models, services, schema, or conventions.

## Area guidelines

| Area | Guidelines |
|------|------------|
| Models | [`app/models/AGENTS.md`](app/models/AGENTS.md) |
| Views | [`app/views/AGENTS.md`](app/views/AGENTS.md) |
| Controllers | [`app/controllers/AGENTS.md`](app/controllers/AGENTS.md) |
| Testing | [`test/AGENTS.md`](test/AGENTS.md) — Minitest + fixtures; model/controller/system minimum |
| Roadmap | [`docs/roadmap.md`](docs/roadmap.md) - Tree Recycle Development roadmap
