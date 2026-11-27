class RemoveLogoWidthFromReservationEmailTemplates < ActiveRecord::Migration[8.1]
  def up
    remove_column :reservation_email_templates, :logo_width, :integer
    remove_column :reservation_email_templates, :published_logo_width, :integer
  end

  def down
    add_column :reservation_email_templates, :logo_width, :integer, null: false, default: 75
    add_column :reservation_email_templates, :published_logo_width, :integer
  end
end
