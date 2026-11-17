class AllowBlankThanksContent < ActiveRecord::Migration[8.1]
  def change
    change_column_null :thanks, :content, true
  end
end
