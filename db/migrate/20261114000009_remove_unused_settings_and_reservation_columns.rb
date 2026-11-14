class RemoveUnusedSettingsAndReservationColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :site_description, :text
    remove_column :settings, :facebook_page_id, :string
    remove_column :settings, :meta_site_name, :string
    remove_column :settings, :meta_title, :string
    remove_column :settings, :meta_description, :string
    remove_column :settings, :meta_image_filename, :string
    remove_column :settings, :driver_instructions, :text
    remove_column :reservations, :pickup_reminder_email_sent_at, :datetime
  end
end
