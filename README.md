:construction: Still being updated


![Example Image](public_screenshot.png)
![Example Image](confirmation2_screenshot.png)

# Tree Recycle II

Tree Recycle is a comprehensive web application that supports the running of a Christmas tree recycling fundraiser. Streamlining the tree pickup reservation and donation process and the logistics of tree pickup across a broad area.

## Features

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

- **Tree Pickups Site for Drivers**
  - Dedicated site for driver pickup management at "/pickups"
  - PDF pickup lists (backup in case online connectivity is down)
  - Map showing pickup locations and status
  - Drivers can update status of pickups and register missing trees

## Getting started

1. Install Ruby and PostgreSQL on your local computer.

2. Install Rails:

```ruby
gem install rails
```

3. Clone the repo:

```ruby
$ git clone https://github.com/carsoncole/tree_recycle.git
$ cd tree_recycle
```

4. Install gems:

```ruby
bundle install
```

5. Migrate the database:

```ruby
rails db:migrate
```

6. Start the web server:

```ruby
bin/dev
```

7. Go to ```http://localhost:3000``` and you should see an initial settings page.


## Deployment

The application can be deployed with [Kamal](https://kamal-deploy.org) to any cloud-based or local server with SSH root access.

### Prerequisites

- Docker Compose (installed locally)
- Docker account
- A host for the application with SSH root access enabled

### Steps

1. Configure ```config/deploy.yml```.
2. Configure your DNS settings for your domain with an 'A' record that points to the IP address of your host.
2. Launch your host. This can be any dedicated server, or even your local machine. It must have SSH root access enabled.
3. Create and configure ```.kamal/secrets```. You can use the sample file ```.kamal/secrets.sample```. Replace ```$KAMAL_REGISTRY_PASSWORD``` with your Docker access key. 
4. With your configuration complete, you need to commit your code, which is what will be used in the Docker image creation.
```ruby
$ git add .
$ git commit -a -m 'some message'
```
4. Setup remote server and deploy:

```ruby
$ kamal setup
$ kamal deploy
```

## Configure Time Zone

To configure the time zone for all times reflected in the application, modify `application.rb`. use 'rails time:zones:all' for a list of zones.

```ruby
config.time_zone = 'Pacific Time (US & Canada)'
```

## Configure secrets

Use encrypted credentials to store application secrets. Remove the existing secrets:

    $ rm config/credentials.yml.enc
    $ EDITOR=vim rails credentials:edit

Copy the sample ```credentials.ymp.enc.sample```. 


## Optional Integrations


### Email

With emailing configured, Tree Recycle will send automated emails confirming tree reservations, cancellations, and donation receipts. Two funnel-type marketing emails are also available to market to people who have made tree pickup reservations in the past.

#### Configure the email sender address

In the configuration file `tree_recycle.rb`, add the sender from email:

```ruby
EMAIL_FROM = "Anytown Tree Recycle <example@example.com>"
```


#### Gmail

- address:              smtp.gmail.com
- port:                 587
- user_name:            username
- password:             password
- authentication:       plain
- enable_starttls_auto: true

Use encrypted credentials to store the settings. The follow should be your ```development.rb``` and ```production.rb``` environment files.

``` ruby
config.action_mailer.smtp_settings = {
  :address              => Rails.application.credentials.mailer.development.address,
  :port                 => Rails.application.credentials.mailer.development.port,
  :user_name            => Rails.application.credentials.mailer.development.user_name,
  :password             => Rails.application.credentials.mailer.development.password,
  :authentication       => plain,
  :enable_starttls_auto => true
}
```
> :warning: **Important GMAIL Note** Gmail is free, but there are limitations. If you are on a free account, the daily sending limit is ~500 emails. If you do hit a limit, they will temporarily shut your account. For the marketing emails, you can control the batch size of emails in Settings and it is recommended that you keep it low (<50) and send multiple times. Sending a massive block of emails may not only shut your account, but it also could get your emails flagged as SPAM, by receiving email servers. Caution is advised.

### Routing

You can configure a mapping service to provide address => latitude and longitude address coordinates and handle geospatial queries to be able to determine whether an address is within a route. There are multiple services, and AWS Location Services is installed by default.

#### Configuration

1. For the Amazon Locations Service, you'll need an AWS account. 

2. Create a Place Index and give it a name, ie. 'tree_recycle', with the data provider 'Esri' with a single use.  You'll then need API credentials which you can obtain in your main profile under 'Security Credentials'.

3. Configure credentials in the Rails encrypted credentials file `config/credentials.yml.enc`.

```ruby
lookups:
  amazon_location_service:
    access_key_id: ACCESSKEY
    secret_access_key: SECRETACCESSKEY
```

4. Update the geocoder config file ``` config/intializers/geocoder.rb```.  When you create a Place Index, note the AWS region it was created in and update it accordingly in this config file. The two items to be updated are `index_name` and `AWS region`. 

```ruby
Geocoder.configure(
  amazon_location_service: {
    index_name: 'tree_recycle'}

Aws.config.update({region: 'us-west-2'})
```

### SMS Messaging

SMS messaging can be configured, and it will provide important messaging to users whose tree can not be found. The message encourages the user to put their tree out or provide instructions and to respond by SMS. This dialogue can be managed entirely with the app.

[Twilio.com](https://twilio.com) is used for SMS. 

#### Configuration

1. Sign up with Twilio. You will need to provide your organization's details and the purpose of your messaging. The process can take time, as they will review your account before permitting any SMS's to be sent.

2. For reservations with a mobile number, if it is flagged ```Missing```, then a Missing Tree SMS will be sent. It will inform the recipient to put out their tree and to respond to the SMS by saying their tree has been put out. Once the response is received, the reservation's status can be updated to ```Pending Pickup```.

3. General SMS enquiries can be received by the application and they can be replied to.

> :warning: Getting SMS service from Twilio takes time to set up as they will do a background check on the organization, to fight against spam messaging.

Add the following details from your Twilio account into the encrypted credentials file:

```ruby
$ EDITOR=vim rails credentials:edit
```
```ruby
twilio:
  production:
    number: TWILLIO_NUMBER
    account_sid: ACCOUNT_SID
    auth_token: AUTH_TOKEN
twilio:
  development:
    number: TWILLIO_NUMBER
    account_sid: ACCOUNT_SID
    auth_token: AUTH_TOKEN
```

In Twilio, you need to create a ```Messaging Service```, which defines the purpose behind what you plan on messaging. The use case should be "Notify my users".

In Twilio, in the section ```Develop```, ```Phone Numbers```, ```Active Numbers```, select your number and update the ```Messaging Configuration```:

```
Configure with: Webhook
A message comes in: Webhook
URL: https://YOUR_SITE_URL/sms/reply
HTTP: HTTP POST
```

Canned SMS reply responses can be modified in `tree_recycle.rb `. 


### Donations

[Stripe](https://stripe.com) is used for taking donations.

#### Configuration

1. Open a Stripe account. You will need organization details, such as tax id etc.
2. Configure your default donation amount. Go to ```Product catalog > Create product > Add price```

3. Configure your Strip donation page to include your organization information, default donation amount etc. You can also select what donation methods you would like to accept.
    - Configure payment methods in ```Settings > Payments > Payment methods```
    - Configure the payment domain (what URL you will be collecting payments) in ```Settings > Payments > Payment Method Domains```

4. Obtain your keys in ```Developers > API Keys```. You will need the ```Publishable key``` and ```Secret key```.


5. Add the Stripe keys to the encrypted creditials file `config/credentials.yml.enc`:

```ruby
EDITOR=vim rails credentials:edit
```

```
stripe:
  development:
    publishable_key: PUBLISHABLE_KEY
    secret_key: SECRET_KEY
  production:
    publishable_key: PRODUCTION_KEY
    secret_key: SECRET_KEY
```

6. Configure Stripe webhook. In Stripe, ```Developers > Webhooks > Webhook endpoints > Endpoint URL```:

```
https://YOUR_SITE_URL/stripe-webhook
```

7. Configure your default donation. In the Stripe Product Catalog, enter your product, ie. a donation, and product price. ```Product Catalog > Products > Create product "Tree Recycle Donation"``` and ```Product Catalog > Products > select Price (customer chooses), enter a present donation amount.```

8. Add the price id from the Stripe price page ```Product Catalog > Products > select your product "Tree Recycle Donation" > click on the price "Customer Chooses (USD)" > price id should be in the top right of page```, to the ```config/initializers/tree_recycle.rb```:

```ruby
STRIPE_DEVELOPMENT_PRICE_ITEM = 'price_1Lxwp5AY1LGWbDshKyepVUDL'
STRIPE_PRODUCTION_PRICE_ITEM = 'price_1M8vYzAY1LGWbDshqoJcAiV9'
```
> :question: You have to create a product and price in both Stripe ```Test mode``` as well as production. You will have different ids for each mode. The id from Test mode should be used in ```STRIPE_DEVELOPMENT_PRICE_ITEM```, and the id from production should be in ```STRIPE_PRODUCTION_PRICE_ITEM```.


9. Enable ```Test mode``` (top right) in your Stripe account, and on your tree recycle site, make a donation. Confirm that the transaction shows up in ```Transactions```.

> :question: **TEST MODE**:  In Test mode, and on your tree recycle donation page, select any credit card, use the credit card number ```4242 4242 4242 4242```, and any expiration data and CVC. The charge will be accepted and should show up within your Stripe account under ```Transactions```. 

10. Disable ```Test mode```.
---


## Marketing emails

### Marketings emails #1 and #2
There are two pre-definded marketing emails. The first email informs the recipient about the tree recycling event and encourages sign-up. The second email is a last call email sent just prior to the event reminding the recipient that time is running out to sign up. Both the first and second emails are only sent to recipients that have not, at the time of sending the email, signed up.

### Configuration
The application is already configured with defauls, but if you want to change them, they can be found in both the UI in `Settings`, or the initializer `tree_recycle.rb`.

Most importantly, in `Settings`, there is an `Email batch quantity` (default: 100) which is the number of emails sent every time you press the button to send emails. This number is important as sending too many emails in one go can more likely flag your email as spam, as well as exceed daily sending limits of your email provider. The free version of Gmail has a daily limit of ~500 emails a day. When you exceed it, they will immediately deactivate your sending for some period of time (~ 24 hours).

The information in the emails is all derived from your event and organization information that you configure in `Settings`. If you want modify the actual emails, they are `/views/marketing_mailer/marketing_email_1.html.erb` and `/views/marketing_mailer/marketing_email_2.html.erb`. There are also text `.text.erb` versions.

### Sending emails
You can send marketing emails through the `Marketing` section, where two emails (Marketing Email #1, Marketing Email #2), one followed by the other, are available. 

The recipients of the marketing emails are listed in `Marketing`. The recipients will be past participants of your tree recycling events. If this is the first year you are running a recycling event, then there will be none listed.

> :question: As soon as someone who is listed as a Prior Reservation in Marketing reserves a tree pickup, they will be removed from the Prior Reservations, and will not be a potential recipient of future marketing emails for the current year's event. At the end of the current event, the event reservations can be migrated in the `Settings > Operations` and all reservations will be merged into the `Prior Reservations` for future marketing.

> :question: In `initializers/tree_recycle.rb` there is a setting (MINIMUM_MONTHS_BEFORE_PRIOR_RESERVATION_REMOVAL) for how long a Prior Reservation will remain since they last participated before being automatically removed. The default is 24 months.

#### Unsubcribing

Recipients of the marketing emails will be given the option to unsubscribe. When they do, their contact information will be immedietly deleted and no longer appear in the `Marketing` section.

## Setting up Routing

Reservations are mapped into admin-defined routes. When entered, reservations will be checked for existence within Routes by either 1) a Route that is nearest to it (each Route has a base address), or 2) with a Route that has polygon defined for it. Multi-point polygons can be entered for each route.

### Routes

Routes need to be defined by first, a base address, and optionally, a polygon made up of 3 or more coordinates (entered counter-clockwise). Polygons can be defined to contain specific roads and addresses, and generally polygons should abut, not overlay, other Route polygons.

Routes should essentially be an area that could contain a manageable group of tree pickups. A pickup driver could be assigned to one or more Routes.

Maps of all pickups within a route are available in `Routes` in the adminstration section of the application. Clicking on each pickup on the map will show if its been picked up and has a link to directions to the pick-up.

![Screenshot](app/assets/images/map.png)

### Zones

Zones are made up of Routes and are used for organizational purposes so that Zone leaders can be defined to oversee groups of Routes.


## Secrets

Application secrets are stored in Rails application secrets in a credential file `/credentials.yml.enc`. The secrets include passwords and keys to access email providers, Twilio and more. You will add your own secrets to this file, which will be encrypted, and then deployed within your codebase to be used in Production on Heroku.

Delete any existing `config/credentials.yml.enc` file. Initialize your own secrets file:

```ruby
$ EDITOR=vim rails credentials:edit
```

This will create your initial credentials file and open it in an editor. Copy the contents of `/config/credentials_sample.yml` as your initial template and edit it accordingly.

Docker and deployment secrets are stored in /.kamal/secrets. This file is in the .gitignore as it holds the Docker registry password.  You will need this file in your local environment to be able to deploy with Kamal. There is a sample secrets file /.kamal/sample_secrets.


## Tests

Run tests and system tests:

    $ rails test
    $ rails system:test


For mailers, previews exist for the confirmation and reminder emails. To view in `development`:

```ruby
http://localhost:3000/rails/mailers/
```

> Viewing previews of emails requires emailing to be enabled in Settings and you need to have supporting reservations or prior reservations.

### Seed Data

There is sample seed data that will populate the application enough to see how it works, and for testing.

    $ rails db:seed


### Images

Default BSA Scouting images are used in emails and are stored in the `app/assets/images` directory. You can customize these images by replacing them with your own.


## Migrating from Tree-Recycle

The data you should migrate (make sure you run the post-event data migration will remove any incomplete reservations, and it will move the status of all reservations to 'archived'):

- Reservations. Fields: `email`, `name`, `street`, `phone`
- Points. Fields: `route_id`, `latitude`, `longitude`, `order`
- Routes. Fields `name`, `street`, `zone_id`, `city`, `state`, `country`, `latitude`, `longitude`
- Zones. `name`, `street`, `city`, `state`, `country`, `latitude`, `longitude` 


Migrating from [Tree Recycle I](https://github.com/carsoncole/tree-recycle.git) primarily transferring reservation data which can be used for marketing in future recycling events. These instructions are based on using PosgreSQL as the backend database.

The following tables and their fields can be migrated:

### Reservations

```sql
id, name, street, email, phone as mobile, NULL AS marketing_email_1_sent_at, NULL AS marketing_email_2_sent_at, created_at, updated_at
```

### Points

```sql
route_id, latitude, longitude, order, created_at, updated_at
```

### Routes

```sql
name, street, zone_id, city, state, country, latitude, longitude, created_at, updated_at
```

### Zones

```sql
name, street, city, state, country, latitude, longitude, created_at, updated_at
```

#### Example migration with  `reservations` table:

1. Download and install the [pgAdmin](https://www.pgadmin.org) utility.
2. Create connection to your Tree Recycle 1 database.
3. Open the query tool and create this query:
```sql
SELECT SELECT id, name, street, email, phone as mobile, NULL AS marketing_email_1_sent_at, NULL AS marketing_email_2_sent_at, created_at, updated_at FROM reservations;
```
3. Select the `reservations` table, right-click and select `Import/Export Data`.
4. Under `General`, select `Export`, name your export file, and select the download location. Under `Columns`, remove all of the table columns except for these:
```sql
id, name, email, phone, street, created_at, updated_at
```
5. Click OK.
6. Create connection to your new Tree Recycle 2 database.
6. Highlight the `prior_reservations` table and select `Import/Export data`.
7. Under `General`, select `Import` and seleect your file. Under `Options`, enable `Header` and under NULL Strings, enter `NULL`.
8. Click OK.
9. To verify, right-click on the `prior_reservations` table, and select `View/Edit Data > All Rows`.



# License

Tree Recycle is released under the [MIT License](https://opensource.org/licenses/MIT).



