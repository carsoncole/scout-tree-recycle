class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(sms_id) 
    return unless Setting.instance.is_sms_enabled
    sms = Sms.find(sms_id)
    sms.send_via_twilio!
  end
end
