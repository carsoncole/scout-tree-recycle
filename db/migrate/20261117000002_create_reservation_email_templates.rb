require "yaml"

class CreateReservationEmailTemplates < ActiveRecord::Migration[8.1]
  class MigrationReservationEmailTemplate < ActiveRecord::Base
    self.table_name = "reservation_email_templates"
  end

  def up
    create_table :reservation_email_templates do |t|
      t.string :name, null: false
      t.text :description
      t.string :subject, null: false
      t.string :logo_image
      t.integer :logo_width, null: false, default: 140
      t.string :logo_alt
      t.text :body_html, null: false
      t.text :body_text
      t.string :published_subject
      t.string :published_logo_image
      t.integer :published_logo_width
      t.string :published_logo_alt
      t.text :published_body_html
      t.text :published_body_text
      t.datetime :published_at
      t.timestamps
    end

    add_index :reservation_email_templates, :name, unique: true

    install_default_templates
  end

  def down
    drop_table :reservation_email_templates
  end

  private

  def install_default_templates
    directory = Rails.root.join("db/reservation_email_templates")
    definitions = YAML.safe_load_file(directory.join("templates.yml"))
    now = Time.current

    definitions.each do |name, attributes|
      subject = attributes.fetch("subject")
      logo_image = attributes["logo_image"].presence
      logo_width = attributes.fetch("logo_width", 140)
      logo_alt = attributes["logo_alt"]
      body_html = File.read(directory.join(attributes.fetch("html_file")))
      body_text = File.read(directory.join(attributes.fetch("text_file")))

      MigrationReservationEmailTemplate.create!(
        name: name,
        description: attributes["description"],
        subject: subject,
        logo_image: logo_image,
        logo_width: logo_width,
        logo_alt: logo_alt,
        body_html: body_html,
        body_text: body_text,
        published_subject: subject,
        published_logo_image: logo_image,
        published_logo_width: logo_width,
        published_logo_alt: logo_alt,
        published_body_html: body_html,
        published_body_text: body_text,
        published_at: now,
        created_at: now,
        updated_at: now
      )
    end
  end
end
