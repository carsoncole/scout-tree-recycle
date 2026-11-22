# Parent mailer for admin-related emails (logs, passwords, settings, users).
# It renders every child mailer through the shared "admin_mailer" layout and
# exposes canonical inline styles so fonts and styling stay consistent.
class AdminMailer < ApplicationMailer
  layout "admin_mailer"

  FONT_STACK = "Arial, Helvetica, sans-serif"

  helper_method :admin_event_name, :admin_heading_style, :admin_paragraph_style,
                :admin_muted_style, :admin_link_style, :admin_button_style

  private

  # Basic event name from Settings, with no date or time information.
  def admin_event_name
    setting = Setting.instance
    setting&.home_page_header.presence ||
      setting&.organization_name.presence ||
      "Tree Recycle"
  end

  def admin_heading_style
    "font-family: #{FONT_STACK}; font-size: 24px; font-weight: bold; color: #1f2937; margin: 0 0 20px 0; text-align: center;"
  end

  def admin_paragraph_style
    "font-family: #{FONT_STACK}; font-size: 15px; line-height: 1.6; color: #1f2937; margin: 0 0 16px 0;"
  end

  def admin_muted_style
    "font-family: #{FONT_STACK}; font-size: 12px; line-height: 1.5; color: #6b7280; margin: 24px 0 0 0; text-align: center;"
  end

  def admin_link_style
    "color: #4c6a57; text-decoration: none;"
  end

  def admin_button_style
    "display: inline-block; padding: 12px 24px; background-color: #4c6a57; color: #ffffff; font-family: #{FONT_STACK}; font-size: 15px; font-weight: bold; text-decoration: none; border-radius: 6px;"
  end
end
