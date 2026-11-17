class CreateThanks < ActiveRecord::Migration[8.1]
  def change
    create_table :thanks do |t|
      t.binary :image, null: false
      t.string :image_content_type, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
