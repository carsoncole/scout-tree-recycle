require "test_helper"

class DatabaseOverviewTest < ActiveSupport::TestCase
  class FakeConfig < Struct.new(:name, :configuration_hash)
  end

  class FakeConfigurations
    def initialize(configs)
      @configs = configs
    end

    def configs_for(env_name:)
      @configs
    end
  end

  test "reports the current environment's databases" do
    databases = DatabaseOverview.new.databases

    assert databases.present?
    database = databases.first
    assert_equal "primary", database.name

    labels = database.entries.map(&:label)
    assert_includes labels, "Adapter"
    assert_includes labels, "Database"
    assert_includes labels, "Pool"
  end

  test "marks secret settings so views can mask them" do
    configurations = FakeConfigurations.new([
      FakeConfig.new("primary", {
        "adapter" => "postgresql",
        "database" => "example_production",
        "username" => "owner",
        "password" => "sensitive-value"
      })
    ])

    entries = DatabaseOverview.new(configurations: configurations).databases.first.entries
    password_entry = entries.find { |entry| entry.attribute == :password }

    assert password_entry.secret
    assert_equal "sensitive-value", password_entry.value

    refute entries.find { |entry| entry.attribute == :adapter }.secret
    refute entries.find { |entry| entry.attribute == :username }.secret
  end

  test "does not mark blank secrets" do
    configurations = FakeConfigurations.new([
      FakeConfig.new("primary", { "adapter" => "postgresql", "password" => nil })
    ])

    entry = DatabaseOverview.new(configurations: configurations).databases.first.entries
      .find { |candidate| candidate.attribute == :password }

    refute entry.secret
    assert_nil entry.value
  end

  test "flattens nested settings into readable values" do
    configurations = FakeConfigurations.new([
      FakeConfig.new("queue", {
        "adapter" => "sqlite3",
        "pragmas" => { "journal_mode" => "wal", "synchronous" => "normal" },
        "migrations_paths" => [ "db/queue_migrate" ]
      })
    ])

    entries = DatabaseOverview.new(configurations: configurations).databases.first.entries

    assert_equal "journal_mode: wal, synchronous: normal",
                 entries.find { |entry| entry.attribute == :pragmas }.value
    assert_equal "db/queue_migrate",
                 entries.find { |entry| entry.attribute == :migrations_paths }.value
  end

  test "reports each configured database role separately" do
    configurations = FakeConfigurations.new([
      FakeConfig.new("primary", { "adapter" => "postgresql" }),
      FakeConfig.new("queue", { "adapter" => "sqlite3" })
    ])

    databases = DatabaseOverview.new(configurations: configurations).databases

    assert_equal %w[primary queue], databases.map(&:name)
    assert_equal "sqlite3", databases.second.entries.first.value
  end
end
