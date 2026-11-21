require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TreeRecycle
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Fallback for console/rake contexts. Requests, jobs, and mailers use the
    # Time Zone configured in /admin/settings.
    config.time_zone = "Pacific Time (US & Canada)"

    # This app does not generate Active Storage variants; disable the processor
    # so deploys don't require the image_processing gem or image libraries.
    config.active_storage.variant_processor = :disabled

    # Keep received raw messages. The default incinerates them after 30 days.
    config.action_mailbox.incinerate = false
    # Raw inbound mail is stored in Postgres, same as other Active Storage bytes.
    config.action_mailbox.storage_service = :db
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
