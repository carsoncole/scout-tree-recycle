require "yaml"

class AddDonationReceiptEmailTemplate < ActiveRecord::Migration[8.1]
  class MigrationReservationEmailTemplate < ActiveRecord::Base
    self.table_name = "reservation_email_templates"
  end

  def up
    return if MigrationReservationEmailTemplate.exists?(name: "donation_receipt_email")

    directory = Rails.root.join("db/reservation_email_templates")
    attributes = YAML.safe_load_file(directory.join("templates.yml")).fetch("donation_receipt_email")
    now = Time.current
    content = {
      description: attributes["description"],
      subject: attributes.fetch("subject"),
      logo_image: attributes["logo_image"].presence,
      logo_alt: attributes["logo_alt"],
      body_html: File.read(directory.join(attributes.fetch("html_file"))),
      body_text: File.read(directory.join(attributes.fetch("text_file")))
    }

    MigrationReservationEmailTemplate.create!(
      name: "donation_receipt_email",
      **content,
      published_subject: content[:subject],
      published_logo_image: content[:logo_image],
      published_logo_alt: content[:logo_alt],
      published_body_html: content[:body_html],
      published_body_text: content[:body_text],
      published_at: now,
      created_at: now,
      updated_at: now
    )
  end

  def down
    MigrationReservationEmailTemplate.where(name: "donation_receipt_email").delete_all
  end
end
