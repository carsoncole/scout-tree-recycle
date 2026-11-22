require "test_helper"

class BackupTest < ActiveSupport::TestCase
  test "registry exposes reservations and settings" do
    assert_equal %w[reservations settings], Backup.dataset_keys
    assert_equal "reservations.csv", Backup::DATASETS.fetch("reservations").filename
    assert_equal "settings.json", Backup::DATASETS.fetch("settings").filename
  end

  test "sanitizes dataset keys" do
    assert_equal %w[settings], Backup.sanitize_dataset_keys([ "settings", "unknown", "", "settings" ])
  end

  test "filename uses the home page header" do
    backup = Backup.new(datasets: [ "reservations" ], setting: Setting.new(home_page_header: "Troop 100 Tree Recycle"))

    assert_equal "troop-100-tree-recycle-backup-20260102-030405.zip",
      backup.filename(Time.zone.local(2026, 1, 2, 3, 4, 5))
  end

  test "filename falls back when the home page header is blank" do
    backup = Backup.new(datasets: [ "reservations" ], setting: Setting.new(home_page_header: ""))

    assert_match(/\Ascout-tree-recycle-backup-\d{8}-\d{6}\.zip\z/, backup.filename)
  end

  test "zip contains a manifest and the selected dataset files" do
    files = zip_entries(Backup.new(datasets: %w[reservations settings]).to_zip)

    assert_equal %w[manifest.json reservations.csv settings.json], files.keys.sort

    manifest = JSON.parse(files.fetch("manifest.json"))
    assert_equal Backup::FORMAT, manifest["format"]
    assert_equal Backup::VERSION, manifest["version"]
    assert_equal "Troop 100 Tree Recycle", manifest["home_page_header"]
    assert_equal %w[reservations settings], manifest["datasets"].map { |dataset| dataset["key"] }
    assert_equal Reservation.count, manifest.dig("datasets", 0, "record_count")

    assert_includes files.fetch("reservations.csv"), reservations(:pending_pickup_1).email
    assert_equal Setting.instance.organization_name, JSON.parse(files.fetch("settings.json")).dig("setting", "organization_name")
  end

  test "zip can contain only one dataset" do
    files = zip_entries(Backup.new(datasets: [ "settings" ]).to_zip)

    assert_equal %w[manifest.json settings.json], files.keys.sort
  end

  test "requires at least one dataset" do
    error = assert_raises(Backup::Error) { Backup.new(datasets: []).to_zip }

    assert_equal "Choose at least one dataset to back up.", error.message
  end

  test "requires settings when backing up settings" do
    error = assert_raises(Backup::Error) { Backup.new(datasets: [ "settings" ], setting: nil).to_zip }

    assert_equal "Complete the initial settings before backing up settings.", error.message
  end

  private

  def zip_entries(body)
    entries = {}
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end
end
