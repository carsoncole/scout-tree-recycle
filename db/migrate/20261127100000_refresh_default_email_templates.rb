require "yaml"

# Copies the built-in email files onto both the draft and the published
# snapshot. Load Default Templates leaves published mail alone, so template
# edits since the last refresh would not go out until an admin published them.
class RefreshDefaultEmailTemplates < ActiveRecord::Migration[8.1]
  class MigrationMarketingEmailTemplate < ActiveRecord::Base
    self.table_name = "marketing_email_templates"
  end

  class MigrationReservationEmailTemplate < ActiveRecord::Base
    self.table_name = "reservation_email_templates"
  end

  def up
    now = Time.current
    refresh_marketing(now)
    refresh_reservation(now)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def refresh_marketing(now)
    directory = Rails.root.join("db/email_templates")

    YAML.safe_load_file(directory.join("templates.yml")).each do |name, attributes|
      template = MigrationMarketingEmailTemplate.find_by(name: name)
      next if template.nil?

      from = attributes["from"].presence
      subject = attributes.fetch("subject")
      image = attributes["image"].presence
      image_alt = attributes["image_alt"]
      body_html = File.read(directory.join(attributes.fetch("html_file")))
      body_text = File.read(directory.join(attributes.fetch("text_file")))

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

  def refresh_reservation(now)
    directory = Rails.root.join("db/reservation_email_templates")

    YAML.safe_load_file(directory.join("templates.yml")).each do |name, attributes|
      template = MigrationReservationEmailTemplate.find_by(name: name)
      next if template.nil?

      subject = attributes.fetch("subject")
      logo_image = attributes["logo_image"].presence
      logo_alt = attributes["logo_alt"]
      body_html = File.read(directory.join(attributes.fetch("html_file")))
      body_text = File.read(directory.join(attributes.fetch("text_file")))

      template.update!(
        description: attributes["description"],
        subject: subject,
        logo_image: logo_image,
        logo_alt: logo_alt,
        body_html: body_html,
        body_text: body_text,
        published_subject: subject,
        published_logo_image: logo_image,
        published_logo_alt: logo_alt,
        published_body_html: body_html,
        published_body_text: body_text,
        updated_at: now
      )
    end
  end
end
