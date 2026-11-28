namespace :sample_data do
  desc "Load example Bainbridge Island data when reservations, contacts, routes, zones, and drivers are all empty"
  task load: :environment do
    if SampleData.load!
      puts "Loaded example Bainbridge Island, Washington sample data (zones, routes, points, drivers, reservations, contacts)."
    else
      abort "Sample data was not loaded. Reservations, contacts, routes, zones, and drivers must all be empty."
    end
  end
end
