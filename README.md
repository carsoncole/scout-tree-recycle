# Scout Tree Recycle

Tree Recycle is a Rails application for running a Christmas tree recycling fundraiser: public tree-pickup reservations and donations, an admin back office, and a driver pickups portal.

## Stack

- Ruby 3.4 / Rails 8.1
- PostgreSQL
- Hotwire (Turbo + Stimulus), Tailwind CSS
- Solid Queue, Solid Cache, Solid Cable
- Minitest
- Optional integrations: Stripe (donations), Twilio (SMS), AWS Location Service (geocoding/routing), SMTP (email)

## Structure

- **Public site** (`/`) — reservation form with address verification, donation flow, about/privacy pages.
- **Admin** (`/admin`) — reservations, routes, drivers, zones, users, donations, SMS conversations, logs, marketing emails, settings, and background jobs (`/admin/jobs`).
- **Pickups portal** (`/pickups`) — driver login via a shared secret key; pickup lists, status updates, and PDF export.
- **API** (`/api/v1`) — Stripe and Twilio webhooks.

## Getting started

Prerequisites: Ruby 3.4, PostgreSQL, and Bundler.

```sh
git clone https://github.com/carsoncole/tree_recycle.git
cd tree_recycle
bin/setup
```

`bin/setup` installs gems, prepares the database, and starts the dev server. Visit `http://localhost:3000`.

On first run with no settings, create them at `/admin/settings/new`; an admin user is created and its password is shown. Optional seed data: `bin/rails db:seed`.

Database connection settings live in `config/database.yml`.

## Configuration

Most configuration is done in `/admin/settings` (organization, email, routing, SMS, donations, pickups). Secrets use Rails encrypted credentials (`bin/rails credentials:edit`). Optional integrations are configured through the settings UI.

## Deployment

Deploy as a Docker container with Kamal: configure `config/deploy.yml` and `.kamal/secrets`, then run `kamal setup` and `kamal deploy`.

## Testing

```sh
bin/rails test
bin/rails test:system
```

## License

MIT — see [LICENSE](LICENSE).
