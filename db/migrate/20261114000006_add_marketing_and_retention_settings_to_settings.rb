class AddMarketingAndRetentionSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :marketing_email_cooldown_days, :integer, default: 7
    add_column :settings, :prior_reservation_retention_months, :integer, default: 24
  end
end
