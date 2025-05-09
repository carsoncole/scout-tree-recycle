class Sms < ApplicationRecord
  belongs_to :reservation, optional: true
  has_many :reservations, foreign_key: "phone"

  enum :direction, { outgoing: 1, incoming: 2 }

  normalizes :phone, with: ->(phone) { Phonelib.parse(phone).full_e164.presence if phone.present? }
  
  after_create_commit :send_outgoing!, if: :outgoing?

  def send_via_twilio!
    begin
      client.messages.create(
        from: from_number,
        to: phone,
        body: body
      )

      update_column(:service_status, 'sent') # optional: mark status after send
    rescue => e
      Rails.logger.error("Twilio send failed: #{e.message}")
      update_column(:service_status, 'failed') # optional: mark failure
    end
  end

  def client
    if Rails.env.test? 
      sid, auth_token = Rails.application.credentials.twilio.test.account_sid, Rails.application.credentials.twilio.test.auth_token
    else
      sid, auth_token = Rails.application.credentials.twilio.production.account_sid, Rails.application.credentials.twilio.production.auth_token
    end

    @client ||= Twilio::REST::Client.new sid, auth_token
  end

  def from_number
    @from_number = if Rails.env.test?
      Rails.application.credentials.twilio.test.number
    else
      Rails.application.credentials.twilio.production.number
    end
  end

  def send_outgoing!
    return unless Setting.instance.is_sms_enabled
    SendSmsJob.perform_later(self.id)
  end


  def formatted_phone
    parsed_phone = Phonelib.parse(phone)
    return phone if parsed_phone.invalid?

    formatted =
      if parsed_phone.country_code == "1" # NANP
        parsed_phone.full_national # (415) 555-2671;123
      else
        parsed_phone.full_international # +44 20 7183 8750
      end
    formatted.gsub!(";", " x") # (415) 555-2671 x123
    formatted
  end


  # def send_with_object(obj, message)
  #   begin
  #   return if !Setting.first.is_sms_enabled
  #   return unless obj.phone.present?
  #   return if obj.respond_to?(:no_sms) && obj.no_sms?

  #   response = client.messages.create(
  #     from: from_number,
  #     to: obj.phone,
  #     body: message
  #   )

  #   # obj.logs.create(message: "SMS message sent: '#{ message }'") if obj.respond_to?(:logs)

  #   return response

  #   rescue => exception
  #     if Rails.env.production?
  #       Rollbar.log('error', exception)
  #     else 
  #       exception
  #     end
  #   end
  # end

end    