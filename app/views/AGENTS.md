# Views

## The Rails Way

- Follow standard Ruby on Rails approach. RESTful routes.

##

## Theming

- Support light and dark modes for all views using Tailwind's `dark:` variants driven by native `prefers-color-scheme` (no manual theme toggle).
- Prefer `dark:` variants over custom JavaScript or separate stylesheets for color changes.

## Forms

- Use the shared `admin-select` class for `<select>` elements. Tailwind's preflight removes native form-control styling, and native selects can render with no inner padding. `admin-select` sets `appearance: none`, explicit padding, and a custom chevron so dropdown text is always inset. Avoid bare or custom-styled selects without it.

## Routes and URLs

- Prefer Rails-standard, RESTful resource paths using underscores.
- Keep controllers, actions, and route helper names underscored, e.g. `Admin::ReservationsController` and `admin_reservations_path`.
- If a hyphenated public path is required, keep the helper name underscored and set `path:` in `config/routes.rb`.
- Follow the conventions already used in `config/routes.rb`; do not introduce a new URL style without a deliberate migration.