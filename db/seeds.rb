# Seed default application data.
# Run with: bin/rails db:seed

# Marketing email templates (built-in defaults)
MarketingEmailTemplate.install_defaults!

# Reservation email templates (built-in defaults)
ReservationEmailTemplate.install_defaults!

puts "\nInstalled default marketing and reservation email templates."
puts "For example Bainbridge Island, Washington zones/routes and sample records, run: bin/rails sample_data:load"
puts "\n"

puts "Run with /bin/dev"
puts "loads at localhost:3000"
