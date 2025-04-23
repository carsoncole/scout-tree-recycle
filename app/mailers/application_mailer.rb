class ApplicationMailer < ActionMailer::Base
  helper ApplicationHelper
  default from: Setting.instance.email_from || 'Anytown Tree Recycle <example@example.com>'
  layout "mailer"
end
