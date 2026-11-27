class ChangeDefaultReservationLogoWidthTo75 < ActiveRecord::Migration[8.1]
  def up
    change_column_default :reservation_email_templates, :logo_width, 75
  end

  def down
    change_column_default :reservation_email_templates, :logo_width, 140
  end
end
