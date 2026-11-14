# Views

## The Rails Way

- Follow standard Ruby on Rails approach. RESTful routes.

## URL conventions

URL path segments use **hyphens**, never underscores (`/security-movers`, `/tax-lots`, `/securities/sync-fmp-quotes`). This is the Rails convention and applies to every public segment: resource paths, custom collection/member actions, and standalone routes.

- Keep controllers, models, actions, helpers, and route helper names underscored (`SecurityMoversController`, `security_movers_path`) — only the **path** is hyphenated.
- For resources with multi-word names, set `path:` in `config/routes.rb`:
