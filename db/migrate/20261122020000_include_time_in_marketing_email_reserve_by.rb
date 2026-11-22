require "yaml"

class IncludeTimeInMarketingEmailReserveBy < ActiveRecord::Migration[8.1]
  class MigrationMarketingEmailTemplate < ActiveRecord::Base
    self.table_name = "marketing_email_templates"
  end

  def up
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

      template.update!(
        description: attributes["description"],
        from: from,
        subject: subject,
        body_html: body_html,
        body_text: body_text,
        published_from: from,
        published_subject: subject,
        published_body_html: body_html,
        published_body_text: body_text,
        updated_at: now
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
