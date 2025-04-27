class Admin::BaseController < ApplicationController
  layout 'admin'
  include Pagy::Backend
end
