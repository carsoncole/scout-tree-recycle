# Loads the example dataset in the background so the request does not time
# out behind proxies. Every run is recorded in the System Logs with the
# "job" log type.
class LoadSampleDataJob < ApplicationJob
  queue_as :default

  def perform(user: nil)
    loaded = SampleData.load!
    message = if loaded
      "Sample data load job completed: example zones, routes, route points, drivers, reservations, and contacts were created."
    else
      "Sample data was not loaded because reservations, contacts, routes, zones, or drivers already have records."
    end

    Log.create(
      log_type: "job",
      message: message,
      error_type: "LoadSampleDataJob",
      severity: loaded ? "info" : "warning",
      handled: true,
      skip_notification: true,
      context: {
        user: user&.email,
        loaded: loaded,
        zones: Zone.count,
        routes: Route.count,
        drivers: Driver.count,
        reservations: Reservation.count,
        contacts: Contact.count
      }
    )
  end
end
