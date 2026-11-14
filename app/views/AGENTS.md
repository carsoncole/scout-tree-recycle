# Views

## The Rails Way

- Follow standard Ruby on Rails approach. RESTful routes.

## Routes and URLs

- Prefer Rails-standard, RESTful resource paths using underscores.
- Keep controllers, actions, and route helper names underscored, e.g. `Admin::ReservationsController` and `admin_reservations_path`.
- If a hyphenated public path is required, keep the helper name underscored and set `path:` in `config/routes.rb`.
- Follow the conventions already used in `config/routes.rb`; do not introduce a new URL style without a deliberate migration.
