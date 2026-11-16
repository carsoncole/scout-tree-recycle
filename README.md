# Scout Tree Recycle

Tree Recycle is a Rails application for running a Christmas tree recycling fundraiser: public tree-pickup reservations and donations, an admin back office, and a driver pickups portal.

Written by [Carson Cole](https://github.com/carsoncole), a former Scoutmaster of Troop 1564 on Bainbridge Island, WA.

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

On first run with no settings, create them at `/admin/settings/new`, including credentials for the initial admin user.

Seed default data (built-in marketing email templates) with:

```sh
bin/rails db:seed
```

For optional example development data, load the sample dataset:

```sh
bin/rails sample_data:load
```

This task loads example zones, routes, route points, and related sample records (drivers, reservations, and contacts) for **Bainbridge Island, Washington**. It is intended for local development/demo use and can be run manually when you want a realistic starting map and sample pickup data.

Database connection settings live in `config/database.yml`.

## Configuration

Most configuration is done in `/admin/settings` (event, organization, site content, email, routing, SMS, donations, pickups). The Site Content section controls the public home page header, image, and supporting copy. Secrets use Rails encrypted credentials (`bin/rails credentials:edit`). Optional integrations are configured through the settings UI.

Set **Site URL** to the public HTTPS URL of the deployment. It is used for links in emails.

## External services

Every integration below is optional and can be enabled or disabled independently in `/admin/settings`. When one is disabled, the related feature is hidden or falls back to a manual workflow (for example, reservations are routed by hand instead of automatically).

| Service | Used for | What you need | Where to get it |
|---------|----------|---------------|-----------------|
| [Twilio](https://www.twilio.com) | Outgoing SMS notifications and incoming replies | Account SID, Auth Token, an SMS-capable From number | Twilio Console |
| [Stripe](https://stripe.com) | Online donations and card payments | Secret key (test or live) and a one-time Price ID | Stripe Dashboard |
| SMTP email provider | Reservation confirmations, password resets, marketing, and log emails | Host, port, username, password, authentication, encryption, From address | Your email provider (e.g. Postmark, SendGrid, Mailgun, Google Workspace) |
| [Amazon Location Service](https://aws.amazon.com/location/) | Address geocoding and automatic pickup routing | Access key ID, secret access key, region, and a Place Index name | AWS Console / IAM |

### Twilio (SMS)

1. Create a Twilio account and buy or provision a phone number with SMS capability.
2. In `/admin/settings` → SMS, enable SMS and enter the **Account SID**, **Auth Token**, and **From Number** (E.164 format, e.g. `+15555550123`).
3. On the Twilio number's messaging configuration, set the webhook for incoming messages to:

   ```text
   https://your-host/api/v1/sms/reply
   ```

   Twilio sends `From` and `Body` parameters; replies appear in the admin SMS inbox. SMS signature verification is not implemented yet.

### Stripe (donations)

1. Create a Stripe product/price for donations. A one-time price is expected; checkout uses the configured Price ID.
2. In `/admin/settings` → Donations, enable online donations and enter the **Secret Key** and **Price ID** (`price_...`). Use test keys while developing.
3. Add a webhook endpoint in Stripe pointing to:

   ```text
   https://your-host/api/v1/stripe-webhook
   ```

   Subscribe to the events the app processes: `checkout.session.completed` (records the donation and links it to the reservation), `charge.refunded`/`charge.updated` (refunds), and `payment_intent.*` (in-person Stripe Terminal charges). Stripe signature verification is not implemented yet.

Without Stripe configured, the donation form still accepts cash/check or no-donation choices.

### Email (SMTP)

1. Obtain SMTP credentials from your email provider or transactional email service.
2. In `/admin/settings` → Email, enable emailing and enter the **From Address** plus SMTP **address**, **port**, **username**, **password**, **authentication** (`plain`, `login`, or `cram_md5`), and **encryption** (`STARTTLS` is recommended; `TLS` and `None` are also supported).
3. Verify **Site URL** is set so email links point at the public host.

SMTP settings are stored in the database and applied to Action Mailer at runtime, so changes take effect without a restart. In development and test, mail is not delivered by SMTP.

#### Marketing email templates

Marketing emails are stored in the database and edited at `/admin/marketing_email_templates` (also linked from `/admin/marketing`). The two built-in campaigns are seeded from `db/email_templates/` and can be restored at any time with **Load Default Templates**, `bin/rails db:seed`, or `bin/rails marketing_email_templates:install_defaults`.

- Templates are rendered with [Liquid](https://shopify.github.io/liquid/), so admins can use variables like `{{ contact.first_name }}` without giving templates access to Ruby.
- Styles are written in normal `<style>` blocks or classes and are inlined automatically by [premailer-rails](https://github.com/premailer/premailer-rails) when the email is delivered.
- Edits save as a draft. Emails keep sending the last published version until **Publish Template** is clicked, so a bad edit cannot go live immediately.
- Each template page shows the available variables, a preview using a real contact, and a **Send Test Email** button. A plain-text version is optional; if it is blank, one is generated from the HTML at send time.
- The **View Email Images** page lists files directly in `app/assets/images` along with the Liquid variable generated from each filename.
- Marketing sends and test sends require the **From Address**, **SMTP Address**, and **SMTP Port** in Settings. If any are missing, sending is blocked and the page lists what still needs to be configured.

### Amazon Location Service (geocoding and routing)

1. Create a [Place Index](https://docs.aws.amazon.com/location/latest/developerguide/places.html) in Amazon Location Service.
2. Create an IAM user with permission to use Location Service place indexes, and generate an access key.
3. In `/admin/settings` → Location Services, enable automatic routing and enter the **Access Key ID**, **Secret Access Key**, **Region** (default `us-west-2`), and **Place Index Name**.

Addresses are geocoded with the Place Index and assigned to routes by zone. If Location Services is not configured or routing is disabled, reservations must be assigned to routes manually in the admin.

## Deployment

Deploy as a Docker container with Kamal: configure `config/deploy.yml` and `.kamal/secrets`, then run `kamal setup` and `kamal deploy`. You will need a PostgreSQL database, a container registry, and the Rails master key (`RAILS_MASTER_KEY`) available to the container.

## Testing

```sh
bin/rails test
bin/rails test:system
```

## License

MIT — see [LICENSE](LICENSE).
