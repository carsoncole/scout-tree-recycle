class UsersMailer < ApplicationMailer
  # Records the delivery in the system log, like the reservation emails.
  # Connection failures are recorded separately by EmailDeliveryErrorSubscriber.
  after_deliver :log_account_setup_email

  def account_created(user)
    @user = user
    @organization_name = Setting.instance&.organization_name.presence || "Tree Recycle"
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
