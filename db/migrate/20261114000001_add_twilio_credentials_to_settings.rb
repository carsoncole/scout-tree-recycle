class AddTwilioCredentialsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :twilio_account_sid, :string
    add_column :settings, :twilio_auth_token, :string
    add_column :settings, :twilio_from_number, :string
  end
end
