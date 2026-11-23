class ChangeLocationProviderDefaultToPlacesV2 < ActiveRecord::Migration[8.1]
  def up
    change_column_default :settings, :location_provider, from: "places_v1", to: "places_v2"

    # Existing installs that already have a Places v2 key can move to the new
    # default safely. Leave installs without a key on the legacy provider so a
    # deploy does not break geocoding before an admin configures Places v2.
    execute <<~SQL.squish
      UPDATE settings
      SET location_provider = 'places_v2'
      WHERE location_provider = 'places_v1'
        AND aws_location_api_key IS NOT NULL
        AND aws_location_api_key <> ''
        AND aws_region IS NOT NULL
        AND aws_region <> ''
    SQL
  end

  def down
    change_column_default :settings, :location_provider, from: "places_v2", to: "places_v1"
  end
end
