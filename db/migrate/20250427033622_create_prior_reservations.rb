class CreatePriorReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :prior_reservations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.string :street
      t.string :email
      t.string :mobile
      t.datetime :marketing_1_email_sent_at
      t.datetime :marketing_2_email_sent_at
      t.index [ "email" ], name: "index_prior_reservations_on_email"
      t.index [ "marketing_1_email_sent_at" ], name: "index_prior_reserations_on_marketing_1_email_sent_at"
      t.timestamps
    end
  end
end
