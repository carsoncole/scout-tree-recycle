class Admin::AnalyticsController < Admin::BaseController
  def show
    @analytics = Analytics.new(period: params[:period])
    @reservation_chart = Analytics::Chart.new(@analytics.reservation_series, scale: :count)
    @donation_chart = Analytics::Chart.new(@analytics.donation_series, scale: :currency)
  end
end
