class Sms < ApplicationRecord
  belongs_to :user, optional: true
  has_many :reservations, foreign_key: "mobile", primary_key: "phone"

  enum :direction, { outgoing: 1, incoming: 2 }, default: :outgoing

  scope :incoming, -> { where(direction: :incoming) }
  scope :unviewed, -> { where(viewed: false) }
  scope :viewed, -> { where(viewed: true) }

  validates :phone, presence: true
  validates :direction, presence: true

  normalizes :phone, with: ->(phone) { Phonelib.parse(phone, Setting.instance&.phone_default_country.presence || "US").full_e164.presence if phone.present? }

  after_create_commit :send_outgoing!, if: :outgoing?

  after_commit :broadcast_sms_update! # , on: [:create, :update]

  # Records an sms log for every message sent or received. When the phone
  # number matches a reservation's mobile, the log is associated with the
  # most recent reservation for that number.
  after_create :log_sms!

  def self.grouped_by_phone_for_index
    # Get all SMS messages ordered by creation time descending
    all_smses = includes(:user).order(created_at: :desc)

    # Group by phone and sort conversations
    smses_by_phone = all_smses.group_by(&:phone).transform_values do |messages|
      messages.sort_by(&:created_at)
    end

    # Sort conversations: unviewed incoming first, then by most recent message
    smses_by_phone.sort_by do |phone, messages|
      has_unviewed_incoming = messages.any? { |msg| msg.incoming? && !msg.viewed? }
      most_recent_time = messages.max_by(&:created_at).created_at

      # Sort by: 1) has unviewed incoming (true first), 2) most recent time (descending)
      [ has_unviewed_incoming ? 0 : 1, -most_recent_time.to_i ]
    end.to_h
  end

  def send_via_twilio!
    unless Setting.instance&.sms_configured?
      Rails.logger.error("Twilio credentials are not configured")
      update_column(:service_status, "failed")
      return
    end

    begin
      client.messages.create(
        from: from_number,
        to: phone,
        body: body
      )

      update_column(:service_status, "sent") # optional: mark status after send
    rescue => e
      Rails.logger.error("Twilio send failed: #{e}")
      Rails.error.report(e, handled: true, context: { phone: phone })
      update_column(:service_status, "failed") # optional: mark failure
    end
  end

  def client
    @client ||= Twilio::REST::Client.new(
      Setting.instance.twilio_account_sid,
      Setting.instance.twilio_auth_token
    )
  end

  def from_number
    Setting.instance.twilio_from_number
  end

  def send_outgoing!
    Rails.logger.info "SMS send_outgoing! called for phone: #{phone}"
    if Setting.instance.is_sms_enabled
      SendSmsJob.perform_later(self.id)
    else
      self.update_column(:service_status, "failed")
      Rails.logger.info("SMS is disabled, skipping send")
    end
  end

  def formatted_phone
    parsed_phone = Phonelib.parse(phone, Setting.instance&.phone_default_country.presence || "US")
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

  private

  def log_sms!
    Log.create(
      log_type: "sms",
      reservation: reservation_for_log,
      message: "#{incoming? ? "SMS received from" : "SMS sent to"} #{formatted_phone}: #{body}",
      context: { phone: phone, direction: direction }
    )
  rescue StandardError => e
    Rails.logger.error("SMS activity could not be logged: #{e.class}: #{e.message}")
  end

  def reservation_for_log
    reservations.order(created_at: :desc).first
  end

  def broadcast_sms_update!
    Rails.logger.info "Broadcasting SMS update for phone: #{phone}, id: #{id}"

    begin
      # Broadcast to the SMS index page
      broadcast_replace_to "smses",
        target: "sms_conversations",
        partial: "admin/sms/conversations",
        locals: { smses_by_phone: Sms.grouped_by_phone_for_index }

      # Broadcast to the specific thread if it exists. The thread partial is only
      # rendered on the conversation page, where it should stay expanded so the
      # newest message remains visible after the update.
      broadcast_replace_to "sms_thread_#{phone.gsub(/[^0-9]/, '')}",
        target: "sms-thread-#{phone.gsub(/[^0-9]/, '')}",
        partial: "admin/sms/thread",
        locals: {
          phone: phone,
          smses: Sms.includes(:user).where(phone: phone).order(:created_at),
          expanded: true,
          show_page: true
        }

      Rails.logger.info "SMS broadcast completed successfully"
    rescue => e
      Rails.logger.error "SMS broadcast failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Rails.error.report(e, handled: true, context: { phone: phone })
    end
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
