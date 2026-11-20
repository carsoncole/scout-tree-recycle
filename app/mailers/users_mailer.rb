class UsersMailer < ApplicationMailer
  # The template is a complete HTML document. Skipping the shared mailer
  # layout keeps the viewport meta in the document head so clients size
  # the message to the window instead of nesting a second document.
  layout false

  # Records the delivery in the system log, like the reservation emails.
  # Connection failures are recorded separately by EmailDeliveryErrorSubscriber.
  after_deliver :log_account_setup_email

  def account_created(user)
    @user = user
    setting = Setting.instance
    @organization_name = setting&.organization_name.presence || "Tree Recycle"
    @site_header = setting&.home_page_header.presence
    @site_url = setting&.site_url.presence
    @setup_url = edit_account_setup_url(@user.account_setup_token)
    @expires_in_days = User::ACCOUNT_SETUP_TOKEN_TTL.in_days.to_i

    mail to: user.email, subject: "Set up your #{@organization_name} account"
  end

  private

  def log_account_setup_email
    Log.create(
      log_type: "email",
      message: "Account setup email sent to #{@user.email}: #{message.subject}",
      context: { to: @user.email, subject: message.subject }
    )
  rescue StandardError => e
    Rails.logger.error("Account setup email could not be logged: #{e.class}: #{e.message}")
  end
end
