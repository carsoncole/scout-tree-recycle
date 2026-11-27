class ChangeDefaultMailerLogoToIcon < ActiveRecord::Migration[8.1]
  def up
    change_column_default :settings, :mailer_logo, "fleur-de-lis-2024-logo-4c-bc-icon.png"
  end

  def down
    change_column_default :settings, :mailer_logo, "fleur-de-lis-2024-logo-4c-bc-small.png"
  end
end
