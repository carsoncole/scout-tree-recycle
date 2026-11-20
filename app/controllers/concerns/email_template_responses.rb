# Shared preview and test-send responses for the admin email template editors.
module EmailTemplateResponses
  extend ActiveSupport::Concern

  private

  def validated_test_email(redirect_path)
    email = params[:email].to_s.strip

    if email.blank?
      redirect_to redirect_path, alert: "Enter an email address for the test message."
      return
    end

    if (message = Setting.instance.email_configuration_alert(purpose: "sending a test email"))
      redirect_to redirect_path, alert: message
      return
    end

    email
  end

  def set_preview_headers
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; img-src * data:; font-src * data:;"
  end

  def preview_error_html(error)
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head><meta charset="utf-8"><title>Preview error</title></head>
        <body style="margin: 0; padding: 24px; font-family: system-ui, sans-serif; color: #742a2a; background: #fff5f5;">
          <h1 style="margin: 0 0 8px; font-size: 18px;">This template could not be previewed.</h1>
          <pre style="white-space: pre-wrap; font-size: 13px;">#{ERB::Util.html_escape(error.message)}</pre>
        </body>
      </html>
    HTML
  end
end
