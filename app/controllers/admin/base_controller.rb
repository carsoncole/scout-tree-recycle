class Admin::BaseController < ApplicationController
  include Authentication
  layout "admin"
  include Pagy::Backend
end
