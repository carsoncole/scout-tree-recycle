class AddUrlToThanks < ActiveRecord::Migration[8.1]
  def change
    add_column :thanks, :url, :string
  end
end
