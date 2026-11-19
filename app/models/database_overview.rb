# Read-only report of the database configurations for the current Rails
# environment. Mirrors ConfigurationOverview: secret values are marked so the
# admin_configuration_value helper masks them in views.
class DatabaseOverview
  Entry = Struct.new(:attribute, :label, :note, :secret, :value, keyword_init: true)
  Database = Struct.new(:name, :entries, keyword_init: true)

  SECRET_KEY_PATTERN = /password|secret|passphrase|token/i

  def initialize(env_name: Rails.env, configurations: ActiveRecord::Base.configurations)
    @env_name = env_name.to_s
    @configurations = configurations
  end

  def databases
    configs.map do |config|
      Database.new(
        name: config.name,
        entries: config.configuration_hash.map { |key, value| build_entry(key, value) }
      )
    end
  end

  private

  def configs
    @configurations.configs_for(env_name: @env_name)
  end

  def build_entry(key, value)
    Entry.new(
      attribute: key.to_s.to_sym,
      label: key.to_s.humanize,
      note: nil,
      secret: secret?(key, value),
      value: format_value(value)
    )
  end

  def secret?(key, value)
    value.present? && key.to_s.match?(SECRET_KEY_PATTERN)
  end

  def format_value(value)
    case value
    when Hash
      value.map { |key, item| "#{key}: #{item}" }.join(", ")
    when Array
      value.join(", ")
    else
      value
    end
  end
end
