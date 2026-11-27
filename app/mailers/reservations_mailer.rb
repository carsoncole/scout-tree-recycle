class ReservationsMailer < ApplicationMailer
  before_action :set_context, except: :test_email
  after_deliver :mark_reservation_email_sent
  after_deliver :log_reservation_email
  after_deliver :mark_donation_receipt_sent
  after_deliver :log_donation_receipt_email

  def new_reservation_email(force: false)
    return suppress_delivery("Your tree pickup is confirmed") unless Setting.instance.is_emailing_enabled?
    return suppress_delivery("Your tree pickup is confirmed") if !force && @reservation.confirmed_reservation_email_sent_at?

    @sent_attribute = :confirmed_reservation_email_sent_at
    prepare_common_assigns
    deliver_template("new_reservation_email", fallback_subject: "Your tree pickup is confirmed")
  end

  def cancelled_reservation_email(force: false)
    return suppress_delivery("Your tree pickup reservation has been cancelled") if !force && @reservation.cancelled_reservation_email_sent_at?

    @sent_attribute = :cancelled_reservation_email_sent_at
    prepare_common_assigns
    deliver_template("cancelled_reservation_email", fallback_subject: "Your tree pickup reservation has been cancelled")
  end

  def missing_tree_email(force: false)
    return suppress_delivery(missing_tree_subject) unless Setting.instance.is_emailing_enabled?

    @sent_attribute = :missing_tree_email_sent_at
    prepare_common_assigns
    deliver_template("missing_tree_email", fallback_subject: missing_tree_subject)
  end

  def pickup_reminder_email(force: false)
    subject = "Reminder: Your upcoming tree pickup"
    return suppress_delivery(subject) unless Setting.instance.is_emailing_enabled?
    return suppress_delivery(subject) unless force || @reservation.pickup_reminder_eligible?
    return suppress_delivery(subject) if !force && @reservation.pickup_reminder_email_sent_at.present?

    @sent_attribute = :pickup_reminder_email_sent_at
    prepare_common_assigns
    deliver_template("pickup_reminder_email", fallback_subject: subject)
  end

  # Sends the saved draft (or published version) to an admin for review.
  # Test sends do not update the reservation's send timestamps.
  def test_email
    @template = ReservationEmailTemplate.find(params[:template_id])
    @reservation = Reservation.find_by(id: params[:reservation_id]) || ReservationEmailTemplate.sample_reservation
    @setting = Setting.instance
    source = params[:source].to_s == "published" ? :published : :draft
    follow_up = params.key?(:follow_up) ? params[:follow_up].to_s == "1" : nil
    subject = prepare_template_content(@template, source: source, follow_up: follow_up)

    mail(
      to: params[:email].presence || @reservation.email,
      subject: "[TEST] #{subject}",
      template_name: "templated_email"
    )
  end

  def donation_receipt_email(force: false)
    @donation = @donation || (@reservation ? @reservation.donations.order(created_at: :desc).first : nil)
    @reservation ||= @donation&.reservation

    subject = "Thank you for your donation"

    if @reservation.blank?
      return suppress_delivery(subject)
    end

    if (@donation&.email.presence || @reservation&.email).blank?
      return suppress_delivery(subject)
    end

    unless Setting.instance.is_emailing_enabled?
      return suppress_delivery(subject)
    end

    if !force && @donation&.receipt_email_sent_at.present?
      return suppress_delivery(subject)
    end

    @donation_to_update = @donation
    @sent_attribute = nil
    prepare_common_assigns
    deliver_template("donation_receipt_email", fallback_subject: subject)
  end
  alias_method :donation_email, :donation_receipt_email
  alias_method :donation_confirmed_email, :donation_receipt_email
  alias_method :donation_receipt, :donation_receipt_email

  private

  def set_context
    @reservation = Reservation.find_by(id: params[:reservation_id]) if params[:reservation_id].present?
    @donation = if params[:donation_id].present?
      Donation.find_by(id: params[:donation_id])
    else
      @reservation&.donations&.order(created_at: :desc)&.first
    end
    @reservation ||= @donation&.reservation
  end

  def suppress_delivery(subject)
    @delivery_suppressed = true
    recipient = (@donation&.email.presence || @reservation&.email)
    message = mail(to: recipient, subject: subject, body: "")
    message.perform_deliveries = false
    message
  end

  def prepare_common_assigns
    @setting = Setting.instance
    @email_footer = @setting.organization_name
  end

  def missing_tree_subject
    @reservation.missing_tree_email_sent_at.present? ?
      "Follow-up: We still cannot find your tree" :
      "We could not find your tree"
  end

  def deliver_template(template_name, fallback_subject:)
    @template = ReservationEmailTemplate.published.find_by(name: template_name)

    if @template.nil?
      Rails.logger.warn(
        "Reservation email template #{template_name} is missing or unpublished; skipping #{action_name} for reservation #{@reservation.id}"
      )
      return suppress_delivery(fallback_subject)
    end

    subject = prepare_template_content(@template, source: :published)

    mail(
      to: @reservation.email,
      subject: subject,
      template_name: "templated_email"
    )
  end

  def prepare_template_content(template, source:, follow_up: nil)
    donation_assigns = {}
    if @donation.present?
      brand = @donation.card_brand.presence || @donation.brand
      donation_assigns = {
        "amount" => @donation.amount,
        "amount_currency" => "$#{format('%.2f', @donation.amount || 0)}",
        "status" => @donation.status.to_s,
        "payment_status" => @donation.payment_status.to_s,
        "customer_name" => @donation.customer_name.to_s,
        "email" => @donation.email.to_s,
        "receipt_url" => @donation.receipt_url.to_s,
        "card_brand" => brand.to_s,
        "card_brand_capitalized" => brand.to_s.capitalize,
        "last4" => @donation.last4.to_s,
        "card_last4" => @donation.card_last4.to_s
      }
    end

    assigns = ReservationEmailTemplate::Renderer.new(
      reservation: @reservation,
      setting: @setting,
      follow_up: follow_up,
      extra_assigns: { "donation" => donation_assigns }
    ).assigns
    prefix = source == :published ? "published_" : ""

    @email_html = template.render_body_html(assigns, source: source)
    @email_text = template.render_body_text(assigns, source: source)
    @logo_src = email_logo_src(filename: template.public_send("#{prefix}logo_image"))
    @logo_width = 75
    @logo_alt = template.public_send("#{prefix}logo_alt").presence || template.logo_alt
    @email_footer = @setting.organization_name

    template.render_subject(assigns, source: source)
  end

  # An unpublished/missing template intentionally stops the email. Returning a
  # message with deliveries disabled keeps deliver_later from raising while
  # leaving the reservation's send timestamps untouched.
  def suppress_delivery(subject)
    @delivery_suppressed = true
    recipient = (@donation&.email.presence || @reservation&.email)
    message = mail(to: recipient, subject: subject, body: "")
    message.perform_deliveries = false
    message
  end

  def mark_reservation_email_sent
    return if @delivery_suppressed
    return if @sent_attribute.blank?
    return if @reservation.blank? || @reservation.id.blank?

    Reservation.where(id: @reservation.id).update_all(@sent_attribute => Time.current, updated_at: Time.current)
  end

  # Records an email log with the sent subject for the reservation's
  # activity history. Suppressed and test sends are not real activity, so
  # they are not logged. A logging failure must never break the delivery.
  def log_reservation_email
    return if @delivery_suppressed
    return if @sent_attribute.blank?

    Log.create(
      log_type: "email",
      reservation: @reservation,
      message: "Email sent to #{@reservation.email}: #{message.subject}",
      context: { to: @reservation.email, subject: message.subject }
    )
  rescue StandardError => e
    Rails.logger.error("Reservation email could not be logged: #{e.class}: #{e.message}")
  end

  def mark_donation_receipt_sent
    return if @delivery_suppressed
    return unless @donation_to_update&.id

    Donation.where(id: @donation_to_update.id).update_all(receipt_email_sent_at: Time.current, updated_at: Time.current)
  end

  def log_donation_receipt_email
    return if @delivery_suppressed
    return unless @donation_to_update&.id

    recipient = (@donation&.email.presence || @reservation&.email)
    return if recipient.blank?

    if @reservation.present?
      Log.create(
        log_type: "email",
        reservation: @reservation,
        message: "Email sent to #{recipient}: #{message.subject}",
        context: { to: recipient, subject: message.subject }
      )
    end
  rescue StandardError => e
    Rails.logger.error("Donation receipt email could not be logged: #{e.class}: #{e.message}")
  end
end
