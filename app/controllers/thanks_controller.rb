class ThanksController < ApplicationController
  def index
    @thanks = Thank.recent
  end

  def image
    @thank = Thank.find(params[:id])

    expires_in 1.year, public: true
    response.headers["X-Content-Type-Options"] = "nosniff"

    send_data @thank.image, type: @thank.image_content_type, disposition: :inline
  end
end
