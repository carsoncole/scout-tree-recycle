namespace :marketing_email_templates do
  desc "Create or refresh the built-in marketing email templates"
  task install_defaults: :environment do
    templates = MarketingEmailTemplate.install_defaults!

    templates.each do |template|
      status = if template.draft_changes?
        "published; draft changes pending publish"
      elsif template.published?
        "published"
      else
        "draft"
      end
      puts "Loaded #{template.name} (#{status})"
    end
  end
end
