module Specs
  class DashboardController < ApplicationController
    layout "client"
    skip_before_action :set_current_shop
    include Specs::ClientAuthenticatable

    def index
      @organisation = current_specs_client.organisation
      @projects = @organisation.specs_projects.order(created_at: :desc)
    end
  end
end
