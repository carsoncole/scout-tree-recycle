namespace :sample_data do
  desc "Load example Bainbridge Island zones, routes, route points, and sample records"
  task load: :environment do
    SampleData.load!
    puts "Loaded example Bainbridge Island, Washington sample data (zones, routes, points, drivers, reservations, contacts)."
  end
end
