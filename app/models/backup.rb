require "zip"

# Builds a zip containing the selected datasets (reservations, settings) and a
# manifest. Download, email, and the daily schedule all use this object so new
# datasets only need one registry entry. Restoring is handled per dataset so a
# backup can be restored piecemeal.
class Backup
  FORMAT = "tree-recycle-backup"
  VERSION = 1
  FALLBACK_SLUG = "scout-tree-recycle"
  MANIFEST_FILENAME = "manifest.json"

  class Error < StandardError; end

  Dataset = Struct.new(:key, :label, :description, :filename, :content, :count, keyword_init: true)

  DATASETS = {
    "reservations" => Dataset.new(
      key: "reservations",
      label: "Reservations",
      description: "Every reservation with its mapped fields, route name, and timestamps.",
      filename: "reservations.csv",
      content: ->(_setting) { Reservation.to_csv },
      count: ->(_setting) { Reservation.count }
    ),
    "settings" => Dataset.new(
      key: "settings",
      label: "Settings",
      description: "All settings, including credentials such as SMTP, Twilio, Stripe, AWS, and driver passwords.",
      filename: "settings.json",
      content: ->(setting) { SettingTransfer.export(setting) },
      count: ->(setting) { setting ? 1 : 0 }
    )
  }.freeze

  def self.dataset_keys
    DATASETS.keys
  end

  def self.sanitize_dataset_keys(keys)
    Array(keys).map(&:to_s).reject(&:blank?).uniq & dataset_keys
  end

  attr_reader :dataset_keys, :setting

  def initialize(datasets: self.class.dataset_keys, setting: Setting.instance)
    @dataset_keys = self.class.sanitize_dataset_keys(datasets)
    @setting = setting
  end

  def datasets
    DATASETS.values_at(*dataset_keys).compact
  end

  def empty?
    dataset_keys.empty?
  end

  def filename(timestamp = Time.current)
    slug = setting&.backup_slug.presence || FALLBACK_SLUG
    "#{slug}-backup-#{timestamp.strftime("%Y%m%d-%H%M%S")}.zip"
  end

  def contents
    datasets.each_with_object({}) do |dataset, files|
      files[dataset.filename] = dataset.content.call(setting)
    end
  end

  def manifest
    {
      "format" => FORMAT,
      "version" => VERSION,
      "exported_at" => Time.current.iso8601,
      "home_page_header" => setting&.home_page_header,
      "datasets" => datasets.map do |dataset|
        {
          "key" => dataset.key,
          "filename" => dataset.filename,
          "record_count" => dataset.count.call(setting)
        }
      end
    }
  end

  def to_zip
    raise Error, "Choose at least one dataset to back up." if empty?
    if dataset_keys.include?("settings") && setting.nil?
      raise Error, "Complete the initial settings before backing up settings."
    end

    buffer = Zip::OutputStream.write_buffer do |zip|
      add_entry(zip, MANIFEST_FILENAME, manifest.to_json)
      contents.each { |name, content| add_entry(zip, name, content) }
    end

    buffer.string
  end

  private

  def add_entry(zip, name, content)
    zip.put_next_entry(name)
    zip.write(content.to_s)
  end
end
