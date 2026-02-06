class PagesController < ApplicationController
  layout "public"
  skip_before_action :set_current_shop

  def privacy
  end
end
