class Admin::MarketingEmailTemplatesController < Admin::BaseController
  include EmailTemplateResponses

  before_action :set_template, only: [ :edit, :update, :destroy, :preview, :send_test, :publish, :unpublish, :restore_default ]

  def index
    @templates = MarketingEmailTemplate.ordered
    @missing_default_names = MarketingEmailTemplate.default_names - @templates.pluck(:name)
  end

  def new
    @template = MarketingEmailTemplate.new
  end

  def edit
    @contacts = Contact.order(:name)
    @selected_contact = find_contact(params[:contact_id]) || @contacts.first || MarketingEmailTemplate.sample_contact
    @preview_source = params[:source].to_s == "published" && @template.published? ? :published : :draft
    @preview_subject = @template.render_subject(preview_assigns, source: @preview_source)
    @preview_text = @template.render_message_text(preview_assigns, source: @preview_source)
  rescue Liquid::Error => e
    @preview_error = e.message
    @preview_subject = ""
    @preview_text = ""
  end

  def create
    @template = MarketingEmailTemplate.new(template_params)

    if @template.save
      redirect_to edit_admin_marketing_email_template_path(@template), notice: "Email template was created as a draft. Preview it, then publish it when it is ready to send."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(template_params.except(:name))
      redirect_to edit_admin_marketing_email_template_path(@template), notice: "Email template was saved as a draft. Publish it to make the changes live."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @template.default?
      redirect_to admin_marketing_email_templates_path, alert: "Default templates cannot be deleted. Restore the default content instead."
    else
      @template.destroy
      redirect_to admin_marketing_email_templates_path, notice: "Email template was successfully deleted."
    end
  end

  def preview
    set_preview_headers
    contact = find_contact(params[:contact_id]) || MarketingEmailTemplate.sample_contact
    source = preview_source
    html = @template.preview_html(preview_assigns(contact), source: source)

    render html: html.html_safe, layout: false
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { template_id: @template.id, source: params[:source] })
    render html: preview_error_html(e).html_safe, layout: false, status: :unprocessable_entity
  end

  def send_test
    email = validated_test_email(edit_admin_marketing_email_template_path(@template))
    return unless email

    source = params[:source].to_s == "published" ? :published : :draft
    if source == :published && @template.published_body_html.blank?
      redirect_to edit_admin_marketing_email_template_path(@template), alert: "This template has not been published yet. Choose the draft version or publish it first."
      return
    end

    contact = find_contact(params[:contact_id]) || Contact.order(:name).first || MarketingEmailTemplate.sample_contact

    MarketingMailer.with(
      template_id: @template.id,
      contact_id: contact.id,
      email: email,
      source: source
    ).test_email.deliver_now

    redirect_to edit_admin_marketing_email_template_path(@template), notice: "Test email sent to #{email}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { template_id: @template.id, email: email })
    redirect_to edit_admin_marketing_email_template_path(@template), alert: "Test email could not be sent: #{e.message}"
  end

  def publish
    @template.publish!
    redirect_to edit_admin_marketing_email_template_path(@template), notice: "Template published. New marketing emails will use this version."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_admin_marketing_email_template_path(@template), alert: "Template could not be published: #{e.record.errors.full_messages.to_sentence}."
  end

  def unpublish
    @template.unpublish!
    redirect_to edit_admin_marketing_email_template_path(@template), notice: "Template unpublished. Marketing emails using this template will not send until it is published again."
  end

  def restore_default
    if @template.restore_default_content!
      redirect_to edit_admin_marketing_email_template_path(@template), notice: "Default content was restored as a draft. Review it, then publish when ready."
    else
      redirect_to edit_admin_marketing_email_template_path(@template), alert: "No default content is available for this template."
    end
  end

  def install_defaults
    MarketingEmailTemplate.install_defaults!
    redirect_to admin_marketing_email_templates_path, notice: "Default templates were loaded. Existing templates were refreshed as drafts; review and publish them when ready."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning)
    redirect_to admin_marketing_email_templates_path, alert: "Default templates could not be loaded: #{e.message}"
  end

  private

  def set_template
    @template = MarketingEmailTemplate.find(params[:id])
  end

  def template_params
    params.require(:marketing_email_template).permit(:name, :description, :from, :subject, :body_html, :body_text)
  end

  def find_contact(id)
    return if id.blank?

    Contact.find_by(id: id)
  rescue ActiveRecord::StatementInvalid
    nil
  end

  def preview_source
    params[:source].to_s == "published" && @template.published_body_html.present? ? :published : :draft
  end

  def preview_assigns(contact = @selected_contact)
    MarketingEmailTemplate::Renderer.new(contact: contact).assigns
  end
end
