module PickupsHelper
  # Label for links that open the driver selection page.
  def driver_selection_label
    selected_driver ? "Driver: #{selected_driver.name}" : "Select Driver"
  end
end
