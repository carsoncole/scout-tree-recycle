class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: Setting.instance.email_from || "Anytown Tree Recycle <example@example.com>"
  layout "mailer"

  before_action :check_is_emailing_enabled

  def check_is_emailing_enabled
    unless Setting.instance.is_emailing_enabled?
      nil
    end
  end
end
