class AddContactSmsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :contact_sms, :string
  end
end
