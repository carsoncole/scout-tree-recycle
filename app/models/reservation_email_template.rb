class ReservationEmailTemplate < ApplicationRecord
  include TemplatedEmail

  DEFAULTS_DIRECTORY = Rails.root.join("db/reservation_email_templates")
  NAMES = %w[new_reservation_email cancelled_reservation_email missing_tree_email pickup_reminder_email donation_receipt_email].freeze
  TEMPLATE_ATTRIBUTES = %i[subject logo_image logo_alt body_html body_text].freeze
  DEFAULT_LOGO = "fleur-de-lis-2024-logo-4c-bc-icon.png"

  BASE_VARIABLES = [
    { name: "reservation.name", description: "Reservation holder's full name (blank when there is no usable name).", example: "Susan Banks" },
    { name: "reservation.first_name", description: "First word of the reservation holder's name.", example: "Susan" },
    { name: "reservation.has_name", description: "True when the reservation has a usable name. Use it for optional greetings.", example: "true" },
    { name: "reservation.email", description: "Reservation email address.", example: "susan@example.com" },
    { name: "reservation.street", description: "Pickup street address.", example: "123 Main St" },
    { name: "reservation.unit", description: "Pickup unit or apartment number.", example: "Apt 2" },
    { name: "reservation.city", description: "Pickup city.", example: "Anytown" },
    { name: "reservation.state", description: "Pickup state.", example: "CA" },
    { name: "reservation.zip", description: "Pickup ZIP code.", example: "12345" },
    { name: "reservation.pickup_notes", description: "Notes the reservation holder added for the pickup crew.", example: "Tree is behind the gate." },
    { name: "reservation.donation_received", description: "True when a paid donation has already been recorded for the reservation.", example: "false" },
  { name: "reservation.donation_amount", description: "Amount of the most recent donation for this reservation.", example: "25" },
  { name: "reservation.donation_amount_currency", description: "Amount of the most recent donation formatted as currency.", example: "$25.00" },
    { name: "reservation.status", description: "Current reservation status.", example: "pending_pickup" },
    { name: "reservation.missing_tree_follow_up", description: "True when this is a follow-up missing-tree notice.", example: "true" },
    { name: "reservation.updated_at_date", description: "Date the reservation was last updated, including the weekday and year.", example: "Saturday, January 6, 2029" },
    { name: "reservation.updated_at_weekday", description: "Date the reservation was last updated, including the weekday.", example: "Saturday, January 6" },
    { name: "setting.organization_name", description: "Organization name from Settings.", example: "Troop 100" },
    { name: "setting.organization_url", description: "Organization website from Settings. May be blank.", example: "https://example.org" },
    { name: "setting.contact_email", description: "Contact email from Settings. May be blank.", example: "help@example.org" },
    { name: "setting.suggested_donation", description: "Suggested donation amount as a number.", example: "25" },
    { name: "setting.suggested_donation_currency", description: "Suggested donation amount formatted as currency.", example: "$25" },
    { name: "setting.pickup_instructions", description: "Configured tree preparation and day-of-pickup instructions.", example: "Remove all decorations and tinsel from your tree." },
    { name: "event.pickup_start_date", description: "Pickup start date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_start_weekday", description: "Pickup start date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_start_short", description: "Pickup start month and day.", example: "January 6" },
    { name: "event.pickup_start_month_day_year", description: "Pickup start month, day, and year without the weekday.", example: "January 6, 2099" },
    { name: "event.pickup_start_time", description: "Pickup start time.", example: "4:00 PM" },
    { name: "event.pickup_start_time_compact", description: "Pickup start time in the compact style used by the default emails.", example: "4:00pm" },
    { name: "event.pickup_end_date", description: "Pickup end date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_end_weekday", description: "Pickup end date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_end_short", description: "Pickup end month and day.", example: "January 6" },
    { name: "event.pickup_end_month_day_year", description: "Pickup end month, day, and year without the weekday.", example: "January 6, 2099" },
    { name: "event.pickup_end_time", description: "Pickup end time.", example: "11:00 PM" },
    { name: "event.pickup_end_time_compact", description: "Pickup end time in the compact style used by the default emails.", example: "11:00pm" },
    { name: "urls.edit_reservation", description: "Link for the reservation holder to change or cancel their reservation.", example: "https://example.org/reservations/.../edit" },
    { name: "urls.donation", description: "Link to make a donation for this reservation.", example: "https://example.org/reservations/.../donations/new" },
    { name: "urls.contact", description: "Contact link. Uses the configured contact email, or the About page when no email is set.", example: "mailto:help@example.org" },
    { name: "urls.home", description: "Site home page.", example: "https://example.org/" },
    { name: "urls.organization", description: "Organization website. Blank when none is configured.", example: "https://example.org" }
  ].freeze

  validates :name, inclusion: { in: NAMES }
  validate :logo_image_is_available

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
      subject: attributes.fetch("subject"),
      logo_image: attributes["logo_image"].presence,
      logo_alt: attributes["logo_alt"],
      body_html: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("html_file"))),
      body_text: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("text_file")))
    }
  end
  private_class_method :build_default_definition

  def self.available_variables
    BASE_VARIABLES + EmailImageLibrary.image_variables.map do |variable, filename|
      {
        name: "images.#{variable}",
        description: "Absolute URL for #{filename}.",
        example: "https://example.org/assets/#{filename}"
      }
    end
  end

  def self.sample_reservation
    Reservation.new(
      name: "Susan Banks",
      email: "susan@example.com",
      street: "123 Main St",
      city: "Anytown",
      state: "CA",
      zip: "12345",
      pickup_notes: "The tree is behind the gate.",
      updated_at: Time.current
    )
  end

  def logo_image_or_default
    logo_image.presence || DEFAULT_LOGO
  end

  # Best-effort subject for admin lists. Falls back to the raw Liquid source
  # when the template cannot be rendered.
  def preview_subject(source: nil, follow_up: false)
    source ||= published? ? :published : :draft
    render_subject(
      ReservationEmailTemplate::Renderer.new(
        reservation: ReservationEmailTemplate.sample_reservation,
        follow_up: follow_up
      ).assigns,
      source: source
    )
  rescue Liquid::Error
    live_subject
  end

  private

  def logo_image_is_available
    return if logo_image.blank?
    return if EmailImageLibrary.image_file?(logo_image)

    errors.add(:logo_image, "must be an image from the email image library")
  end
end
