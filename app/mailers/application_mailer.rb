class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: Setting.instance.email_from || 'Anytown Tree Recycle <example@example.com>'
  layout "mailer"
end
