# Loads the example dataset in the background so the request does not time
# out behind proxies. Every run is recorded in the System Logs with the
# "job" log type.
class LoadSampleDataJob < ApplicationJob
  queue_as :default

  def perform(user: nil)
    SampleData.load!

    Log.create(
      log_type: "job",
      message: "Sample data load job completed: example zones, routes, route points, drivers, reservations, and contacts were created.",
      error_type: "LoadSampleDataJob",
      severity: "info",
      handled: true,
      skip_notification: true,
      context: {
        user: user&.email,
        zones: Zone.count,
        routes: Route.count,
        reservations: Reservation.count,
        contacts: Contact.count
      }
    )
  end
end
