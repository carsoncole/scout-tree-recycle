# Tree Recycle

A comprehensive web application for managing Christmas tree recycling fundraisers. Streamlines the entire process from reservation to pickup, with features for routing, donations, and customer communication.

## Key Features

- **Reservation Management**
  - Public website for tree pickup reservations
  - Address verification and geocoding
  - Automatic or manual routing system
  - Status tracking (pending, picked up, missing, cancelled)

- **Routing System**
  - Automatic routing with geocoding
  - Manual routing option
  - Route assignment to drivers
  - Zone-based organization

- **Donation Processing**
  - Online donation acceptance
  - Stripe integration
  - Receipt generation
  - Donation tracking

- **Communication**
  - Email notifications for:
    - Reservation confirmations
    - Pickup reminders
    - Missing tree alerts
    - Donation receipts
  - SMS notifications for missing trees
  - Marketing emails to previous customers

- **Admin Features**
  - Dashboard for reservation management
  - Route assignment interface
  - Settings configuration
  - Marketing campaign management
  - User management

## Technical Stack

- Ruby 3.4
- Rails 8+
- PostgreSQL
- Tailwind CSS
- Stimulus.js
- Docker (for deployment)

## Optional Integrations

- AWS Location Service (for geocoding)
- Twilio (for SMS)
- Stripe (for donations)
- SMTP (for email)

## Setup

1. **Prerequisites**
   ```bash
   ruby 3.4+
   rails 8+
   postgresql
   ```

2. **Installation**
   ```bash
   git clone https://github.com/carsoncole/tree_recycle.git
   cd tree_recycle
   bundle install
   rails db:migrate
   ```

3. **Configuration**
   - Copy `config/credentials.yml.enc.sample` to `config/credentials.yml.enc`
   - Configure your credentials:
     ```bash
     EDITOR=vim rails credentials:edit
     ```

4. **Create Admin User**
   ```ruby
   rails console
   User.create(email: "admin@example.com", password: "password", role: "admin")
   ```

5. **Start the Server**
   ```bash
   bin/dev
   ```

## Deployment

The application can be deployed using Kamal:

1. Configure `config/deploy.yml`
2. Set up DNS records
3. Deploy:
   ```bash
   kamal setup
   kamal deploy
   ```

## License

[Add your license information here] 