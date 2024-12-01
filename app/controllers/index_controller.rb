class IndexController < ApplicationController
  skip_before_action :admin_only
  def index
  end
end
