# Seed default application data.
# Run with: bin/rails db:seed

# Marketing email templates (built-in defaults)
MarketingEmailTemplate.install_defaults!

puts "\nInstalled default marketing email templates."
puts "For example Bainbridge Island, Washington zones/routes and sample records, run: bin/rails sample_data:load"
puts "\n"

puts "Run with /bin/dev"
puts "loads at localhost:3000"
