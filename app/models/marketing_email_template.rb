class MarketingEmailTemplate < ApplicationRecord
  include TemplatedEmail

  DEFAULTS_DIRECTORY = Rails.root.join("db/email_templates")
  IMAGES_DIRECTORY = EmailImageLibrary::DIRECTORY
  IMAGE_EXTENSIONS = EmailImageLibrary::EXTENSIONS
  MARKETING_EMAIL_NAMES = %w[marketing_email_1 marketing_email_2].freeze
  TEMPLATE_ATTRIBUTES = %i[from subject body_html body_text].freeze

  BASE_VARIABLES = [
    { name: "contact.name", description: "Contact's full name (blank when the contact has no usable name).", example: "Susan Banks" },
    { name: "contact.first_name", description: "First word of the contact's name.", example: "Susan" },
    { name: "contact.has_name", description: "True when the contact has a usable name. Use it for optional greetings.", example: "true" },
    { name: "contact.email", description: "Contact's email address.", example: "susan@example.com" },
    { name: "contact.street", description: "Contact's street address.", example: "123 Main St" },
    { name: "contact.mobile", description: "Contact's mobile phone number.", example: "+11234567890" },
    { name: "setting.organization_name", description: "Organization name from Settings.", example: "Troop 100" },
    { name: "setting.organization_url", description: "Organization website from Settings. May be blank.", example: "https://example.org" },
    { name: "setting.home_page_header", description: "Home page header from Settings.", example: "Troop 100 Tree Recycle" },
    { name: "setting.suggested_donation", description: "Suggested donation amount as a number.", example: "25" },
    { name: "setting.suggested_donation_currency", description: "Suggested donation amount formatted as currency.", example: "$25" },
    { name: "event.pickup_start_date", description: "Pickup start date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_start_weekday", description: "Pickup start date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_start_short", description: "Pickup start month and day.", example: "January 6" },
    { name: "event.pickup_start_time", description: "Pickup start time.", example: "4:00 PM" },
    { name: "event.pickup_end_date", description: "Pickup end date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_end_weekday", description: "Pickup end date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_end_short", description: "Pickup end month and day.", example: "January 6" },
    { name: "event.pickup_end_time", description: "Pickup end time.", example: "11:00 PM" },
    { name: "event.sign_up_deadline_date", description: "Sign-up deadline including the weekday and year.", example: "Friday, January 5, 2099" },
    { name: "event.sign_up_deadline_weekday", description: "Sign-up deadline including the weekday.", example: "Friday, January 5" },
    { name: "event.sign_up_deadline_short", description: "Sign-up deadline month and day.", example: "January 5" },
    { name: "urls.registration", description: "Reservation page pre-filled with this contact's details.", example: "https://example.org/?contact_id=..." },
    { name: "urls.unsubscribe", description: "This contact's unsubscribe link. Blank when previewing without a saved contact.", example: "https://example.org/contacts/.../unsubscribe" },
    { name: "urls.home", description: "Site home page.", example: "https://example.org/" },
    { name: "urls.organization", description: "Organization website. Blank when none is configured.", example: "https://example.org" }
  ].freeze

  def self.defaults_directory
    DEFAULTS_DIRECTORY
  end

  def self.template_attributes
    TEMPLATE_ATTRIBUTES
  end

  def self.build_default_definition(name, attributes)
    {
      name: name,
      description: attributes["description"],
      from: attributes["from"].presence,
      subject: attributes.fetch("subject"),
      body_html: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("html_file"))),
      body_text: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("text_file")))
    }
  end
  private_class_method :build_default_definition

  def self.available_variables
    BASE_VARIABLES + image_variables.map do |variable, filename|
      {
        name: "images.#{variable}",
        description: "Absolute URL for #{filename}.",
        example: "https://example.org/assets/#{filename}"
      }
    end
  end

  def self.available_images
    EmailImageLibrary.available_images
  end

  def self.image_variables
    EmailImageLibrary.image_variables
  end

  def self.image_key_for(filename)
    EmailImageLibrary.image_key_for(filename)
  end

  def self.image_variable_for(filename)
    EmailImageLibrary.image_variable_for(filename)
  end

  def self.sample_contact
    Contact.new(name: "Susan Banks", email: "susan@example.com", street: "123 Main St", mobile: "+11234567890")
  end

  def preview_html(assigns = {}, source: :draft)
    document = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f7fafc;">
          #{render_body_html(assigns, source: source)}
        </body>
      </html>
    HTML

    inline_css(document)
  end
end
