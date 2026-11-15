require "yaml"

class CreateMarketingEmailTemplates < ActiveRecord::Migration[8.1]
  class MigrationMarketingEmailTemplate < ActiveRecord::Base
    self.table_name = "marketing_email_templates"
  end

  def up
    create_table :marketing_email_templates do |t|
      t.string :name, null: false
      t.text :description
      t.string :from
      t.string :subject, null: false
      t.text :body_html, null: false
      t.text :body_text
      t.string :published_from
      t.string :published_subject
      t.text :published_body_html
      t.text :published_body_text
      t.datetime :published_at
      t.timestamps
    end

    add_index :marketing_email_templates, :name, unique: true

    install_default_templates
  end

  def down
    drop_table :marketing_email_templates
  end

  private

  def install_default_templates
    directory = Rails.root.join("db/email_templates")
    definitions = YAML.safe_load_file(directory.join("templates.yml"))
    now = Time.current

    definitions.each do |name, attributes|
      subject = attributes.fetch("subject")
      body_html = File.read(directory.join(attributes.fetch("html_file")))
      body_text = File.read(directory.join(attributes.fetch("text_file")))

      MigrationMarketingEmailTemplate.create!(
        name: name,
        description: attributes["description"],
        from: attributes["from"].presence,
        subject: subject,
        body_html: body_html,
        body_text: body_text,
        published_from: attributes["from"].presence,
        published_subject: subject,
        published_body_html: body_html,
        published_body_text: body_text,
        published_at: now,
        created_at: now,
        updated_at: now
      )
    end
  end
end
