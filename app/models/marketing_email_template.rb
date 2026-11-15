require "yaml"

class MarketingEmailTemplate < ApplicationRecord
  DEFAULTS_DIRECTORY = Rails.root.join("db/email_templates")
  IMAGES_DIRECTORY = Rails.root.join("app/assets/images")
  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp].freeze
  MARKETING_EMAIL_NAMES = %w[marketing_email_1 marketing_email_2].freeze

  BASE_VARIABLES = [
    { name: "contact.name", description: "Contact's full name (blank when the contact has no usable name).", example: "Susan Banks" },
    { name: "contact.first_name", description: "First word of the contact's name.", example: "Susan" },
    { name: "contact.has_name", description: "True when the contact has a usable name. Use it for optional greetings.", example: "true" },
    { name: "contact.email", description: "Contact's email address.", example: "susan@example.com" },
    { name: "contact.street", description: "Contact's street address.", example: "123 Main St" },
    { name: "contact.mobile", description: "Contact's mobile phone number.", example: "+11234567890" },
    { name: "setting.organization_name", description: "Organization name from Settings.", example: "Troop 100" },
    { name: "setting.organization_url", description: "Organization website from Settings. May be blank.", example: "https://example.org" },
    { name: "setting.home_page_header", description: "Home page header from Settings.", example: "Troop 100 Tree Recycle" },
    { name: "setting.suggested_donation", description: "Suggested donation amount as a number.", example: "25" },
    { name: "setting.suggested_donation_currency", description: "Suggested donation amount formatted as currency.", example: "$25" },
    { name: "event.pickup_start_date", description: "Pickup start date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_start_weekday", description: "Pickup start date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_start_short", description: "Pickup start month and day.", example: "January 6" },
    { name: "event.pickup_start_time", description: "Pickup start time.", example: "4:00 PM" },
    { name: "event.pickup_end_date", description: "Pickup end date including the weekday and year.", example: "Saturday, January 6, 2099" },
    { name: "event.pickup_end_weekday", description: "Pickup end date including the weekday.", example: "Saturday, January 6" },
    { name: "event.pickup_end_short", description: "Pickup end month and day.", example: "January 6" },
    { name: "event.pickup_end_time", description: "Pickup end time.", example: "11:00 PM" },
    { name: "event.sign_up_deadline_date", description: "Sign-up deadline including the weekday and year.", example: "Friday, January 5, 2099" },
    { name: "event.sign_up_deadline_weekday", description: "Sign-up deadline including the weekday.", example: "Friday, January 5" },
    { name: "event.sign_up_deadline_short", description: "Sign-up deadline month and day.", example: "January 5" },
    { name: "urls.registration", description: "Reservation page pre-filled with this contact's details.", example: "https://example.org/?contact_id=..." },
    { name: "urls.unsubscribe", description: "This contact's unsubscribe link. Blank when previewing without a saved contact.", example: "https://example.org/contacts/.../unsubscribe" },
    { name: "urls.home", description: "Site home page.", example: "https://example.org/" },
    { name: "urls.organization", description: "Organization website. Blank when none is configured.", example: "https://example.org" }
  ].freeze

  attr_readonly :name

  normalizes :name, with: ->(value) { value.to_s.strip.downcase }

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/, message: "may only contain lowercase letters, numbers, and underscores" }
  validates :subject, :body_html, presence: true
  validate :liquid_syntax_is_valid

  scope :published, -> { where.not(published_at: nil).where.not(published_body_html: [ nil, "" ]) }
  scope :ordered, -> { order(:name) }

  def self.default_config
    YAML.safe_load_file(DEFAULTS_DIRECTORY.join("templates.yml"))
  end

  def self.default_definitions
    default_config.map { |name, attributes| build_default_definition(name, attributes) }
  end

  def self.default_names
    default_config.keys
  end

  def self.default_definition(name)
    attributes = default_config[name.to_s]
    return if attributes.blank?

    build_default_definition(name.to_s, attributes)
  end

  def self.build_default_definition(name, attributes)
    {
      name: name,
      description: attributes["description"],
      from: attributes["from"].presence,
      subject: attributes.fetch("subject"),
      body_html: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("html_file"))),
      body_text: File.read(DEFAULTS_DIRECTORY.join(attributes.fetch("text_file")))
    }
  end
  private_class_method :build_default_definition

  # Creates any missing default templates and refreshes the working copy of
  # existing defaults. Published content is never overwritten: an admin must
  # review and publish the refreshed draft.
  def self.install_defaults!
    transaction do
      default_definitions.map do |definition|
        template = find_or_initialize_by(name: definition[:name])
        new_template = template.new_record?
        template.assign_attributes(definition.except(:name))

        if new_template
          template.published_from = template.from
          template.published_subject = template.subject
          template.published_body_html = template.body_html
          template.published_body_text = template.body_text
          template.published_at = Time.current
        end

        template.save!
        template
      end
    end
  end

  def self.available_variables
    BASE_VARIABLES + image_variables.map do |variable, filename|
      {
        name: "images.#{variable}",
        description: "Absolute URL for #{filename}.",
        example: "https://example.org/assets/#{filename}"
      }
    end
  end

  def self.available_images
    Dir.children(IMAGES_DIRECTORY)
      .select { |filename| File.file?(IMAGES_DIRECTORY.join(filename)) }
      .select { |filename| IMAGE_EXTENSIONS.include?(File.extname(filename).downcase) }
      .sort
  end

  def self.image_variables
    used_variables = []

    available_images.each_with_object({}) do |filename, variables|
      variable = unique_image_variable(image_key_for(filename), used_variables)
      used_variables << variable
      variables[variable] = filename
    end
  end

  def self.image_key_for(filename)
    basename = File.basename(filename, File.extname(filename))
    key = basename.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    key = "image" if key.blank?
    key = "image_#{key}" if key.match?(/\A\d/)
    key
  end

  def self.unique_image_variable(variable, used_variables)
    candidate = variable
    suffix = 2
    while used_variables.include?(candidate)
      candidate = "#{variable}_#{suffix}"
      suffix += 1
    end
    candidate
  end
  private_class_method :unique_image_variable

  def self.image_variable_for(filename)
    variable = image_variables.key(filename)
    "images.#{variable}" if variable
  end

  def self.sample_contact
    Contact.new(name: "Susan Banks", email: "susan@example.com", street: "123 Main St", mobile: "+11234567890")
  end

  def display_name
    name.to_s.titleize
  end

  def default?
    self.class.default_names.include?(name)
  end

  def published?
    published_at.present? && published_body_html.present?
  end

  def draft?
    !published?
  end

  def live_subject
    published? ? published_subject : subject
  end

  def draft_changes?
    published? && [ [ from.to_s, published_from.to_s ], [ subject, published_subject ], [ body_html, published_body_html ], [ body_text.to_s, published_body_text.to_s ] ].any? { |draft, live| draft.to_s != live.to_s }
  end

  def publish!
    assign_attributes(
      published_from: from,
      published_subject: subject,
      published_body_html: body_html,
      published_body_text: body_text,
      published_at: Time.current
    )
    save!
  end

  def unpublish!
    update!(published_at: nil)
  end

  def restore_default_content!
    definition = self.class.default_definition(name)
    return false unless definition

    assign_attributes(definition.slice(:description, :from, :subject, :body_html, :body_text))
    save
  end

  def render_subject(assigns = {}, source: :draft)
    render_liquid(source_content(:subject, source), assigns)
  end

  def render_body_html(assigns = {}, source: :draft)
    render_liquid(source_content(:body_html, source), assigns)
  end

  def render_body_text(assigns = {}, source: :draft)
    content = source_content(:body_text, source)
    return render_liquid(content, assigns) if content.present?

    plain_text_from_html(render_body_html(assigns, source: source))
  end

  def preview_html(assigns = {}, source: :draft)
    document = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f7fafc;">
          #{render_body_html(assigns, source: source)}
        </body>
      </html>
    HTML

    Premailer::Rails::CustomizedPremailer.new(document).to_inline_css
  end

  def plain_text_from_html(html)
    document = Nokogiri::HTML(html.to_s)
    document.css("style, script").remove
    document.css("a[href]").each { |link| link.replace("#{link.text.strip} (#{link['href']})") }

    body = document.at_css("body") || document
    block_selector = "p, li, h1, h2, h3, h4, h5, h6"
    blocks = []

    body.traverse do |node|
      if node.text?
        text = node.text.squish
        next if text.blank? || node.ancestors(block_selector).any?

        blocks << text
      elsif node.element? && %w[p li h1 h2 h3 h4 h5 h6].include?(node.name)
        next if node.ancestors(block_selector).any?

        text = node.text.squish
        blocks << text if text.present?
      end
    end

    blocks.join("\n\n")
  end

  private

  def source_content(attribute, source)
    source = source.to_sym
    raise ArgumentError, "Unknown template source: #{source}" unless %i[draft published].include?(source)

    public_send(source == :published ? "published_#{attribute}" : attribute)
  end

  def render_liquid(content, assigns)
    Liquid::Template.parse(content.to_s).render(assigns.stringify_keys)
  end

  def liquid_syntax_is_valid
    %i[subject body_html body_text].each do |attribute|
      value = public_send(attribute)
      next if value.blank?

      Liquid::Template.parse(value)
    rescue Liquid::SyntaxError => e
      errors.add(attribute, "has a Liquid syntax error: #{e.message}")
    end
  end
end
