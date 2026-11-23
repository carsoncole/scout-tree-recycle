# Tree Recycle Development Roadmap

## Known Remaining Items

### API and webhooks

- Add signature verification for Stripe and Twilio webhooks.
- Remove the deprecated unversioned `/api/*` webhook aliases once Stripe and Twilio are configured to use `/api/v1/*`.

### Reservation flow

- Add Places v2 `Autocomplete` to the street field as a typeahead aid. Submit-time address verification and the suggested-address confirmation step are implemented with Places v2 `Geocode`.

### Controllers and REST

- Move state-changing GET actions to `PATCH`/`POST`, including marking logs and SMS conversations as viewed.
- Refactor the large `Admin::SmsController#create` action into smaller methods, Turbo Stream templates, or a dedicated resource.
- Reshape marketing, operations, and SMS conversation routes and controllers around standard REST resources where practical.

### Configuration and infrastructure

- Replace the hardcoded LAN database host in `config/database.yml` with localhost or an environment-driven host for development and test.

### Email

- Implement donation receipt emails with a proper `DonationsMailer`, or remove the receipt-generation claims from the README and donation views.

