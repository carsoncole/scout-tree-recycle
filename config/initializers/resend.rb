# The API key is read when Resend fetches a full inbound message after the
# email.received webhook. It is stored in admin settings rather than credentials
# so it can be updated without a deploy. The lambda keeps the lookup lazy
# because the database is not available while initializers run.
Resend.api_key = -> { Setting.instance&.resend_api_key.presence }

# The Resend gem only reads its Action Mailbox signing secret from credentials
# or the environment. Prefer the value stored in admin settings.
module ResendIngressSigningSecret
  private

  def signing_secret
    Setting.instance&.resend_signing_secret.presence
  end
end

Rails.application.config.to_prepare do
  ActionMailbox::Ingresses::Resend::InboundEmailsController.prepend(ResendIngressSigningSecret)
end
