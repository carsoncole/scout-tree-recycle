require "uri"

class MarketingEmailTemplate
  # Builds the Liquid assigns available to a marketing email template.
  class Renderer
    attr_reader :contact, :setting, :extra_assigns

    def initialize(contact: nil, setting: Setting.instance, extra_assigns: {})
      @contact = contact || MarketingEmailTemplate.sample_contact
      @setting = setting || Setting.new
      @extra_assigns = extra_assigns.stringify_keys
    end

    def assigns
      {
        "contact" => contact_assigns,
        "setting" => setting_assigns,
        "event" => event_assigns,
        "urls" => url_assigns,
        "images" => image_assigns
      }.merge(extra_assigns)
    end

    private

    def contact_assigns
      {
        "id" => contact.id,
        "name" => contact.has_name? ? contact.name.to_s.strip : "",
        "first_name" => contact.has_name? ? contact.first_name : "",
        "email" => contact.email.to_s,
        "street" => contact.street.to_s,
        "mobile" => contact.mobile.to_s,
        "has_name" => contact.has_name?
      }
    end

    def setting_assigns
      {
        "organization_name" => setting.organization_name.to_s,
        "organization_url" => setting.organization_url.to_s,
        "home_page_header" => setting.home_page_header.to_s,
        "suggested_donation" => setting.suggested_donation_amount,
        "suggested_donation_currency" => helpers.number_to_currency(setting.suggested_donation_amount, precision: 0),
        "time_zone" => setting.time_zone.to_s
      }
    end

    def event_assigns
      {
        "pickup_start" => formatted_time(setting.event_pickup_start, "%Y-%m-%dT%H:%M:%S%:z"),
        "pickup_start_date" => formatted_time(setting.event_pickup_start, "%A, %B %-d, %Y"),
        "pickup_start_weekday" => formatted_time(setting.event_pickup_start, "%A, %B %-d"),
        "pickup_start_short" => formatted_time(setting.event_pickup_start, "%B %-d"),
        "pickup_start_time" => formatted_time(setting.event_pickup_start, "%-I:%M %p"),
        "pickup_end_date" => formatted_time(setting.event_pickup_end, "%A, %B %-d, %Y"),
        "pickup_end_weekday" => formatted_time(setting.event_pickup_end, "%A, %B %-d"),
        "pickup_end_short" => formatted_time(setting.event_pickup_end, "%B %-d"),
        "pickup_end_time" => formatted_time(setting.event_pickup_end, "%-I:%M %p"),
        "sign_up_deadline_date" => formatted_time(setting.event_sign_up_deadline, "%A, %B %-d, %Y"),
        "sign_up_deadline_weekday" => formatted_time(setting.event_sign_up_deadline, "%A, %B %-d"),
        "sign_up_deadline_short" => formatted_time(setting.event_sign_up_deadline, "%B %-d")
      }
    end

    def url_assigns
      {
        "home" => url_helpers.root_url(**url_options),
        "registration" => registration_url,
        "unsubscribe" => unsubscribe_url,
        "organization" => setting.organization_url.to_s
      }
    end

    def image_assigns
      MarketingEmailTemplate.image_variables.transform_values { |filename| image_url(filename) }
    end

    def registration_url
      return url_helpers.root_url(**url_options) if contact.id.blank?

      url_helpers.root_url(contact_id: contact.id, **url_options)
    end

    def unsubscribe_url
      return "" if contact.id.blank?

      url_helpers.unsubscribe_contact_url(contact.id, **url_options)
    end

    def image_url(name)
      "#{base_url}#{helpers.image_path(name)}"
    end

    def base_url
      protocol = url_options[:protocol].presence || "http"
      host = url_options[:host].to_s
      port = url_options[:port]
      host = "#{host}:#{port}" if port.present? && !host.include?(":")
      "#{protocol}://#{host}"
    end

    def formatted_time(time, format)
      return "" if time.blank?

      time.in_time_zone.strftime(format)
    end

    def helpers
      ActionController::Base.helpers
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def url_options
      @url_options ||= site_url_options.presence || ActionMailer::Base.default_url_options.symbolize_keys.presence || { host: "localhost", port: 3000 }
    end

    def site_url_options
      site_url = setting.site_url.to_s.strip
      return {} if site_url.blank?

      site_url = "https://#{site_url}" unless site_url.match?(%r{\Ahttps?://}i)
      uri = URI.parse(site_url)
      return {} if uri.host.blank?

      options = { host: uri.host, protocol: uri.scheme }
      options[:port] = uri.port if uri.port && uri.port != uri.default_port
      options
    rescue URI::InvalidURIError
      {}
    end
  end
end
