class Admin::DataController < Admin::BaseController
  def show
    @setting = Setting.instance
    @database_overview = DatabaseOverview.new
    @reservations_count = Reservation.count
    @contacts_count = Contact.count
    @zones_count = Zone.count
    @routes_count = Route.count
    @drivers_count = Driver.count
  end
end
