# Exports and restores the singleton Setting as a portable JSON file.
# Used by /admin/data so settings can be backed up and restored on a fresh install.
class SettingsRestore
  FORMAT = "tree-recycle-settings"
  VERSION = 1
  MAX_FILE_SIZE = 1.megabyte
  EXCLUDED_ATTRIBUTES = %w[id created_at updated_at backup_last_sent_at].freeze

  # Older exports used the reservations-export column names. Keep accepting
  # those keys so backups made before the backups section still restore.
  LEGACY_ATTRIBUTE_NAMES = {
    "is_reservations_export_schedule_enabled" => "is_backup_schedule_enabled",
    "reservations_export_email" => "backup_email",
    "reservations_export_time" => "backup_time",
    "reservations_export_last_sent_at" => "backup_last_sent_at"
  }.freeze

  Result = Struct.new(:setting, :errors, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  def self.exportable_attributes
    Setting.column_names - EXCLUDED_ATTRIBUTES
  end

  def self.export(setting)
    attrs = exportable_attributes.index_with { |attribute| setting.public_send(attribute) }

    {
      "format" => FORMAT,
      "version" => VERSION,
      "exported_at" => Time.current.iso8601,
      "setting" => attrs
    }.to_json
  end

  def initialize(json:, user: nil)
    @json = json.to_s
    @user = user
  end

  def perform
    return failure([ "Please choose a settings JSON file to restore." ]) if @json.strip.empty?
    return failure([ "Settings file is too large (maximum 1 MB)." ]) if @json.bytesize > MAX_FILE_SIZE

    payload = parse_payload
    return payload if payload.is_a?(Result)

    setting_attrs = payload["setting"]
    unless setting_attrs.is_a?(Hash)
      return failure([ "Settings file is invalid: missing setting data." ])
    end

    setting_attrs = normalize_legacy_attributes(setting_attrs)
    attrs = setting_attrs.slice(*self.class.exportable_attributes)
    setting = Setting.instance || Setting.new

    if setting.update(attrs)
      Result.new(setting: setting, errors: [])
    else
      Result.new(setting: setting, errors: setting.errors.full_messages)
    end
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { user: @user&.email })
    failure([ "Settings could not be restored: #{e.message}" ])
  end

  private

  def normalize_legacy_attributes(setting_attrs)
    return setting_attrs unless setting_attrs.is_a?(Hash)

    setting_attrs.dup.tap do |attrs|
      LEGACY_ATTRIBUTE_NAMES.each do |legacy, current|
        attrs[current] = attrs[legacy] if attrs.key?(legacy) && !attrs.key?(current)
        attrs.delete(legacy)
      end
    end
  end

  def parse_payload
    payload = JSON.parse(@json)
    unless payload.is_a?(Hash)
      return failure([ "Settings file is invalid: expected a JSON object." ])
    end

    unless payload["format"] == FORMAT
      return failure([ "Settings file is not a recognized Tree Recycle settings export." ])
    end

    version = payload["version"]
    unless version == VERSION
      return failure([ "Settings file version #{version.inspect} is not supported." ])
    end

    payload
  rescue JSON::ParserError
    failure([ "Settings file is not valid JSON." ])
  end

  def failure(errors)
    Result.new(setting: nil, errors: Array(errors))
  end
end
