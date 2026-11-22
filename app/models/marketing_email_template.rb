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
    { name: "setting.contact_email", description: "Contact email from Settings. Blank when none is configured.", example: "help@example.org" },
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
    { name: "urls.unsubscribe", description: "This contact's unsubscribe link. Added automatically at the bottom of every marketing email, so it does not need to be placed in the template. Blank when previewing without a saved contact.", example: "https://example.org/contacts/.../unsubscribe" },
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

  # The editable template plus the required unsubscribe footer. Preview, test
  # sends, and live sends all use this so the link cannot be left out.
  def render_message_html(assigns = {}, source: :draft)
    "#{render_body_html(assigns, source: source)}\n#{unsubscribe_footer_html(assigns)}"
  end

  def render_message_text(assigns = {}, source: :draft)
    [ render_body_text(assigns, source: source).to_s.rstrip, unsubscribe_footer_text(assigns) ].compact_blank.join("\n\n")
  end

  def preview_html(assigns = {}, source: :draft)
    document = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f6f3ea;">
          #{render_message_html(assigns, source: source)}
        </body>
      </html>
    HTML

    inline_css(document)
  end

  private

  def unsubscribe_footer_html(assigns)
    url = unsubscribe_url_from(assigns)
    link = if url.present?
      %(<a href="#{ERB::Util.html_escape(url)}" style="color:#7e8273;text-decoration:underline;">Unsubscribe</a>)
    else
      "Unsubscribe"
    end

    <<~HTML
      <table class="email-unsubscribe" role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#f6f3ea">
        <tr>
          <td align="center" style="padding:32px 24px 56px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;font-size:13px;line-height:1.6;color:#7e8273;">
            #{link}
          </td>
        </tr>
      </table>
    HTML
  end

  def unsubscribe_footer_text(assigns)
    url = unsubscribe_url_from(assigns)
    url.present? ? "Unsubscribe: #{url}" : "Unsubscribe"
  end

  def unsubscribe_url_from(assigns)
    urls = assigns.to_h.stringify_keys["urls"]
    return "" if urls.blank?

    urls.to_h.stringify_keys["unsubscribe"].to_s
  end
end
