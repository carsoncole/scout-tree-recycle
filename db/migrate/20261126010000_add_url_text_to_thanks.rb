class AddUrlTextToThanks < ActiveRecord::Migration[8.1]
  def change
    add_column :thanks, :url_text, :string
  end
end
