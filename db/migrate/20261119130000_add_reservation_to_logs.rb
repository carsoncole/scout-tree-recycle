class AddReservationToLogs < ActiveRecord::Migration[8.1]
  def change
    # Logs are an audit trail: keep the entry but detach it if its
    # reservation is ever destroyed.
    add_reference :logs, :reservation, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
  end
end
