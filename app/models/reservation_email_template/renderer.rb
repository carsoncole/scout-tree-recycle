class ReservationEmailTemplate
  # Builds the Liquid assigns available to a reservation email template.
  class Renderer
    include EmailTemplateAssigns

    attr_reader :reservation, :setting, :extra_assigns, :follow_up

    def initialize(reservation: nil, setting: Setting.instance, follow_up: nil, extra_assigns: {})
      @reservation = reservation || ReservationEmailTemplate.sample_reservation
      @setting = setting || Setting.new
      @follow_up = follow_up
      @extra_assigns = extra_assigns.stringify_keys
    end

    private

    def domain_assigns
      { "reservation" => reservation_assigns }
    end

    def reservation_assigns
      {
        "id" => reservation.id,
        "name" => reservation_name,
        "first_name" => reservation_has_name? ? reservation_first_name : "",
        "has_name" => reservation_has_name?,
        "email" => reservation.email.to_s,
        "street" => reservation.street.to_s,
        "unit" => reservation.unit.to_s,
        "city" => reservation.city.to_s,
        "state" => reservation.state.to_s,
        "zip" => reservation.zip.to_s,
        "pickup_notes" => reservation.pickup_notes.to_s,
        "donation_received" => reservation.donation_received?,
        "donation_amount" => reservation.donation_amount,
        "donation_amount_currency" => reservation.donation_amount_currency,
        "status" => reservation.status.to_s,
        "missing_tree_follow_up" => missing_tree_follow_up?,
        "updated_at_date" => formatted_time(reservation.updated_at, "%A, %B %-d, %Y"),
        "updated_at_weekday" => formatted_time(reservation.updated_at, "%A, %B %-d"),
        "updated_at_short" => formatted_time(reservation.updated_at, "%B %-d")
      }
    end

    def url_assigns
      super.merge(
        "edit_reservation" => url_helpers.edit_reservation_url(reservation_identifier, **url_options),
        "donation" => url_helpers.new_reservation_donation_url(reservation_identifier, **url_options),
        "contact" => contact_url
      )
    end

    def contact_url
      return "mailto:#{setting.contact_email}" if setting.contact_email.present?

      url_helpers.about_url(**url_options)
    end

    def reservation_identifier
      return "sample-reservation" unless reservation&.id

      reservation.public_token
    end

    def reservation_name
      reservation_has_name? ? reservation.name.to_s.strip : ""
    end

    def reservation_first_name
      reservation_name.split(/\s+/).first.to_s
    end

    def reservation_has_name?
      name = reservation.name.to_s.strip
      name.present? && name.downcase != "no name provided"
    end

    def missing_tree_follow_up?
      return follow_up unless follow_up.nil?

      reservation.respond_to?(:missing_tree_email_sent_at) && reservation.missing_tree_email_sent_at.present?
    end
  end
end
