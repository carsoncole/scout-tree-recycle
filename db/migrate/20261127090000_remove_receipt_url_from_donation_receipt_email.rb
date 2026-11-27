require "yaml"

class RemoveReceiptUrlFromDonationReceiptEmail < ActiveRecord::Migration[8.1]
  class MigrationReservationEmailTemplate < ActiveRecord::Base
    self.table_name = "reservation_email_templates"
  end

  def up
    template = MigrationReservationEmailTemplate.find_by(name: "donation_receipt_email")
    return if template.nil?

    directory = Rails.root.join("db/reservation_email_templates")
    attributes = YAML.safe_load_file(directory.join("templates.yml")).fetch("donation_receipt_email")
    body_html = File.read(directory.join(attributes.fetch("html_file")))
    body_text = File.read(directory.join(attributes.fetch("text_file")))

    template.update!(
      body_html: body_html,
      body_text: body_text,
      published_body_html: body_html,
      published_body_text: body_text,
      updated_at: Time.current
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
