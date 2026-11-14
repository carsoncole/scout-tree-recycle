class AddEmailSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :email_from_address, :string
    add_column :settings, :smtp_address, :string
    add_column :settings, :smtp_port, :integer
    add_column :settings, :smtp_user_name, :string
    add_column :settings, :smtp_password, :string
    add_column :settings, :smtp_authentication, :string, default: "plain"
    add_column :settings, :smtp_encryption, :string, default: "starttls"
  end
end
