class Admin::MarketingImagesController < Admin::BaseController
  def index
    @image_filenames = MarketingEmailTemplate.available_images
  end
end
