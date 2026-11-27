class Admin::ReservationEmailTemplatesController < Admin::BaseController
  include EmailTemplateResponses

  before_action :set_template, only: [ :edit, :update, :preview, :send_test, :publish, :unpublish, :restore_default ]
  before_action :prevent_pickup_reminder_editing, only: [ :edit, :update, :publish, :unpublish, :restore_default ]

  def index
    @templates = ReservationEmailTemplate.where(name: ReservationEmailTemplate::NAMES).index_by(&:name)
    @missing_default_names = ReservationEmailTemplate::NAMES - @templates.keys
    @reservations = Reservation.order(updated_at: :desc).limit(200)
  end

  def edit
    prepare_edit
  end

  def update
    if @template.update(template_params)
      redirect_to edit_admin_reservation_email_template_path(@template), notice: "Reservation email template was saved as a draft. Publish it to make the changes live."
    else
      prepare_edit
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    set_preview_headers
    reservation = find_reservation(params[:reservation_id]) || ReservationEmailTemplate.sample_reservation
    source = preview_source
    assigns = preview_assigns(reservation)
    @body_html = @template.render_body_html(assigns, source: source)
    @logo_src = EmailImageLibrary.data_uri(source_logo_image(source))
    @logo_width = ReservationEmailTemplate::LOGO_WIDTH
    @logo_alt = source_logo_alt(source)
    @email_footer = Setting.instance.organization_name

    html = render_to_string(template: "admin/reservation_email_templates/preview", layout: false)
    render html: @template.inline_css(html).html_safe, layout: false
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { template_id: @template.id, source: params[:source] })
    render html: preview_error_html(e).html_safe, layout: false, status: :unprocessable_entity
  end

  def send_test
    email = validated_test_email(send_test_redirect_path)
    return unless email

    source = params[:source].to_s == "published" ? :published : :draft
    if source == :published && !@template.published?
      redirect_to send_test_redirect_path, alert: "This template has not been published yet. Choose the draft version or publish it first."
      return
    end

    reservation = find_reservation(params[:reservation_id]) || ReservationEmailTemplate.sample_reservation

    ReservationsMailer.with(
      template_id: @template.id,
      reservation_id: reservation.id,
      email: email,
      source: source,
      follow_up: follow_up? ? "1" : "0"
    ).test_email.deliver_now

    redirect_to send_test_redirect_path, notice: "Test email sent to #{email}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { template_id: @template.id, email: email })
    redirect_to send_test_redirect_path, alert: "Test email could not be sent: #{e.message}"
  end

  def publish
    @template.publish!
    redirect_to edit_admin_reservation_email_template_path(@template), notice: "Template published. New reservation emails will use this version."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_admin_reservation_email_template_path(@template), alert: "Template could not be published: #{e.record.errors.full_messages.to_sentence}."
  end

  def unpublish
    @template.unpublish!
    redirect_to edit_admin_reservation_email_template_path(@template), notice: "Template unpublished. Reservation emails using it will not send until it is published again."
  end

  def restore_default
    if @template.restore_default_content!
      redirect_to edit_admin_reservation_email_template_path(@template), notice: "Default content was restored as a draft. Review it, then publish when ready."
    else
      redirect_to edit_admin_reservation_email_template_path(@template), alert: "No default content is available for this template."
    end
  end

  def install_defaults
    ReservationEmailTemplate.install_defaults!
    redirect_to admin_reservation_email_templates_path, notice: "Default reservation email templates were loaded. Existing templates were refreshed as drafts; review and publish them when ready."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning)
    redirect_to admin_reservation_email_templates_path, alert: "Default reservation email templates could not be loaded: #{e.message}"
  end

  private

  def prevent_pickup_reminder_editing
    return unless @template&.name == "pickup_reminder_email"

    redirect_to admin_reservation_email_templates_path, alert: "The pickup reminder email template cannot be edited."
  end

  def set_template
    @template = ReservationEmailTemplate.find(params[:id])
  end

  def send_test_redirect_path
    case params[:return_to].to_s
    when "index"
      admin_reservation_email_templates_path
    when "reservations"
      admin_reservations_path
    else
      edit_admin_reservation_email_template_path(@template)
    end
  end

  def template_params
    params.require(:reservation_email_template).permit(
      :description,
      :subject,
      :logo_image,
      :logo_alt,
      :body_html,
      :body_text
    )
  end

  def prepare_edit
    @reservations = Reservation.order(updated_at: :desc).limit(200)
    @selected_reservation = find_reservation(params[:reservation_id]) || @reservations.first || ReservationEmailTemplate.sample_reservation
    @preview_source = preview_source
    @follow_up = follow_up?
    @preview_subject = @template.render_subject(preview_assigns(@selected_reservation), source: @preview_source)
    @preview_text = @template.render_body_text(preview_assigns(@selected_reservation), source: @preview_source)
  rescue Liquid::Error => e
    @preview_error = e.message
    @preview_subject = ""
    @preview_text = ""
  end

  def find_reservation(id)
    return if id.blank?

    Reservation.find_by(id: id)
  rescue ActiveRecord::StatementInvalid
    nil
  end

  def preview_source
    params[:source].to_s == "published" && @template.published? ? :published : :draft
  end

  def follow_up?
    params[:follow_up].to_s == "1"
  end

  def preview_assigns(reservation)
    ReservationEmailTemplate::Renderer.new(
      reservation: reservation,
      follow_up: follow_up?
    ).assigns
  end

  def source_logo_image(source)
    image = source == :published ? @template.published_logo_image : @template.logo_image
    image.presence || ReservationEmailTemplate::DEFAULT_LOGO
  end

  def source_logo_alt(source)
    alt = source == :published ? @template.published_logo_alt : @template.logo_alt
    alt.presence || @template.logo_alt
  end
end
