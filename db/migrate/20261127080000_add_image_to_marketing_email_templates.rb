require "yaml"

class AddImageToMarketingEmailTemplates < ActiveRecord::Migration[8.1]
  class MigrationMarketingEmailTemplate < ActiveRecord::Base
    self.table_name = "marketing_email_templates"
  end

  def up
    add_column :marketing_email_templates, :image, :string
    add_column :marketing_email_templates, :image_alt, :string
    add_column :marketing_email_templates, :published_image, :string
    add_column :marketing_email_templates, :published_image_alt, :string

    refresh_default_templates
  end

  def down
    remove_column :marketing_email_templates, :published_image_alt
    remove_column :marketing_email_templates, :published_image
    remove_column :marketing_email_templates, :image_alt
    remove_column :marketing_email_templates, :image
  end

  private

  def refresh_default_templates
    directory = Rails.root.join("db/email_templates")
    definitions = YAML.safe_load_file(directory.join("templates.yml"))
    now = Time.current

    definitions.each do |name, attributes|
      template = MigrationMarketingEmailTemplate.find_by(name: name)
      next if template.nil?

      subject = attributes.fetch("subject")
      body_html = File.read(directory.join(attributes.fetch("html_file")))
      body_text = File.read(directory.join(attributes.fetch("text_file")))
      from = attributes["from"].presence
      image = attributes["image"].presence
      image_alt = attributes["image_alt"]

      template.update!(
        description: attributes["description"],
        from: from,
        subject: subject,
        image: image,
        image_alt: image_alt,
        body_html: body_html,
        body_text: body_text,
        published_from: from,
        published_subject: subject,
        published_image: image,
        published_image_alt: image_alt,
        published_body_html: body_html,
        published_body_text: body_text,
        updated_at: now
      )
    end
  end
end
