class SmsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    to_number = params["To"]

    m = Sms.create(
      phone: from_number,
      body: message_body,
      direction: 'incoming'
      )
  end
end
