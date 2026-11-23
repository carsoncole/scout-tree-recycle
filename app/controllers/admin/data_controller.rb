class Admin::DataController < Admin::BaseController
  def show
    @setting = Setting.instance
    @database_overview = DatabaseOverview.new
    @reservations_count = Reservation.count
    @contacts_count = Contact.count
  end
end
