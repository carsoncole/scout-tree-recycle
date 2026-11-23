class AddResendCredentialsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :resend_api_key, :string
    add_column :settings, :resend_signing_secret, :string
  end
end
