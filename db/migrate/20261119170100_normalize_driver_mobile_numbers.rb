class NormalizeDriverMobileNumbers < ActiveRecord::Migration[8.1]
  def up
    country = if Setting.column_names.include?("phone_default_country")
      Setting.limit(1).pick(:phone_default_country).presence || "US"
    else
      "US"
    end

    Driver.find_each do |driver|
      normalized = Phonelib.parse(driver.mobile, country).full_e164.presence
      next if normalized.blank? || normalized == driver.mobile

      driver.update_columns(mobile: normalized)
    end
  end

  def down
  end
end
