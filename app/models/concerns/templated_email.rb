require "yaml"

# Shared behaviour for admin-editable email templates. A template keeps a
# working draft (subject/body/logo) plus a published snapshot that mailers
# send. The snapshot is only replaced when an admin publishes.
module TemplatedEmail
  extend ActiveSupport::Concern

  included do
    attr_readonly :name

    normalizes :name, with: ->(value) { value.to_s.strip.downcase }

    validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/, message: "may only contain lowercase letters, numbers, and underscores" }
    validates :subject, :body_html, presence: true
    validate :liquid_syntax_is_valid

    scope :published, -> { where.not(published_at: nil).where.not(published_body_html: [ nil, "" ]) }
    scope :ordered, -> { order(:name) }
  end

  class_methods do
    def default_config
      YAML.safe_load_file(defaults_directory.join("templates.yml"))
    end

    def default_definitions
      default_config.map { |name, attributes| build_default_definition(name, attributes) }
    end

    def default_names
      default_config.keys
    end

    def default_definition(name)
      attributes = default_config[name.to_s]
      return if attributes.blank?

      build_default_definition(name.to_s, attributes)
    end

    # Creates missing default templates and refreshes the working draft of
    # existing defaults. Published content is never overwritten: an admin must
    # review and publish the refreshed draft.
    def install_defaults!
      transaction do
        default_definitions.map do |definition|
          template = find_or_initialize_by(name: definition[:name])
          new_template = template.new_record?
          template.assign_attributes(definition.except(:name))

          if new_template
            template_attributes.each do |attribute|
              template.public_send("published_#{attribute}=", template.public_send(attribute))
            end
            template.published_at = Time.current
          end

          template.save!
          template
        end
      end
    end

    # Subclasses define these.
    def defaults_directory
      raise NotImplementedError, "#{name} must define defaults_directory"
    end

    def template_attributes
      raise NotImplementedError, "#{name} must define template_attributes"
    end

    def build_default_definition(_name, _attributes)
      raise NotImplementedError, "#{name} must define build_default_definition"
    end
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
    published? && self.class.template_attributes.any? do |attribute|
      public_send(attribute).to_s != public_send("published_#{attribute}").to_s
    end
  end

  def publish!
    self.class.template_attributes.each do |attribute|
      public_send("published_#{attribute}=", public_send(attribute))
    end
    self.published_at = Time.current
    save!
  end

  def unpublish!
    update!(published_at: nil)
  end

  def restore_default_content!
    definition = self.class.default_definition(name)
    return false unless definition

    assign_attributes(definition.slice(:description, *self.class.template_attributes))
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

  def inline_css(document)
    Premailer::Rails::CustomizedPremailer.new(document).to_inline_css
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
