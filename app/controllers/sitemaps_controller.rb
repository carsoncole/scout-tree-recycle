class SitemapsController < ApplicationController
  def show
    options = Setting.instance&.site_url_options || {}

    @urls = [
      root_url(**options),
      about_url(**options),
      thanks_url(**options),
      privacy_url(**options),
      credits_url(**options)
    ]
  end
end
