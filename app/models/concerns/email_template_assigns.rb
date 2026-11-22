# Builds the Liquid assigns shared by all admin-editable email templates.
# Including renderers provide domain_assigns (and may extend url_assigns).
module EmailTemplateAssigns
  def assigns
    {
      "setting" => setting_assigns,
      "event" => event_assigns,
      "urls" => url_assigns,
      "images" => image_assigns
    }.merge(domain_assigns).merge(extra_assigns)
  end

  private

  def domain_assigns
    raise NotImplementedError, "#{self.class.name} must define domain_assigns"
  end

  def setting_assigns
    {
      "organization_name" => setting.organization_name.to_s,
      "organization_url" => setting.organization_url.to_s,
      "home_page_header" => setting.home_page_header.to_s,
      "contact_email" => setting.contact_email.to_s,
      "site_url" => setting.site_url.to_s,
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
      "pickup_start_month_day_year" => formatted_time(setting.event_pickup_start, "%B %-d, %Y"),
      "pickup_start_time" => formatted_time(setting.event_pickup_start, "%-I:%M %p"),
      "pickup_start_time_compact" => formatted_time(setting.event_pickup_start, "%-l:%M%P"),
      "pickup_end_date" => formatted_time(setting.event_pickup_end, "%A, %B %-d, %Y"),
      "pickup_end_weekday" => formatted_time(setting.event_pickup_end, "%A, %B %-d"),
      "pickup_end_short" => formatted_time(setting.event_pickup_end, "%B %-d"),
      "pickup_end_month_day_year" => formatted_time(setting.event_pickup_end, "%B %-d, %Y"),
      "pickup_end_time" => formatted_time(setting.event_pickup_end, "%-I:%M %p"),
      "pickup_end_time_compact" => formatted_time(setting.event_pickup_end, "%-l:%M%P"),
      "sign_up_deadline" => formatted_time(setting.event_sign_up_deadline, "%A, %B %-d, %Y at %-I:%M %p"),
      "sign_up_deadline_date" => formatted_time(setting.event_sign_up_deadline, "%A, %B %-d, %Y"),
      "sign_up_deadline_weekday" => formatted_time(setting.event_sign_up_deadline, "%A, %B %-d"),
      "sign_up_deadline_short" => formatted_time(setting.event_sign_up_deadline, "%B %-d"),
      "sign_up_deadline_time" => formatted_time(setting.event_sign_up_deadline, "%-I:%M %p")
    }
  end

  def url_assigns
    {
      "home" => url_helpers.root_url(**url_options),
      "organization" => setting.organization_url.to_s
    }
  end

  def image_assigns
    EmailImageLibrary.image_variables.transform_values { |filename| image_url(filename) }
  end

  def image_url(name)
    protocol = url_options[:protocol].presence || "http"
    host = url_options[:host].to_s
    port = url_options[:port]
    host_with_port = port.present? && !host.include?(":") ? "#{host}:#{port}" : host
    path = helpers.image_path(name)

    case path
    when /\Ahttps?:\/\//i
      path
    when /\A\/\//
      "#{protocol}:#{path}"
    else
      "#{protocol}://#{host_with_port}#{path}"
    end
  end

  def formatted_time(time, format)
    return "" if time.blank?

    time.in_time_zone(local_time_zone).strftime(format)
  end

  # Event times are stored in UTC and shown in the time zone from Settings.
  def local_time_zone
    ActiveSupport::TimeZone[setting.time_zone.to_s] || Time.zone
  end

  def helpers
    ActionController::Base.helpers
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def url_options
    @url_options ||= setting.site_url_options.presence || ActionMailer::Base.default_url_options.symbolize_keys.presence || { host: "localhost", port: 3000 }
  end
end
