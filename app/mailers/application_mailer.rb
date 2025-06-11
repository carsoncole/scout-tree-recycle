class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: EMAIL_FROM
  layout "mailer"
end
