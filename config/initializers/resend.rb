# The API key is read when Resend fetches a full inbound message after the
# email.received webhook. SMTP delivery does not use this key.
# Set it with bin/rails credentials:edit under resend.api_key.
Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
