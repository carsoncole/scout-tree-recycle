class AddMailerLogoToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :mailer_logo, :string, default: "fleur-de-lis-2024-logo-4c-bc-small.png", null: false
  end
end
