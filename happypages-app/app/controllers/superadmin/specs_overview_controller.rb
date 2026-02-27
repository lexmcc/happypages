class Superadmin::SpecsOverviewController < Superadmin::BaseController
  def index
    @projects = Specs::Project.includes(:shop, :organisation, :sessions, :cards)
                              .order(created_at: :desc)

    @projects = @projects.where(shop_id: params[:shop_id]) if params[:shop_id].present?
    @projects = @projects.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?

    if params[:status] == "active"
      @projects = @projects.joins(:sessions).where(specs_sessions: { status: "active" }).distinct
    elsif params[:status] == "completed"
      @projects = @projects.joins(:sessions).where(specs_sessions: { status: "completed" }).distinct
    end

    @shops = Shop.where(id: Specs::Project.where.not(shop_id: nil).select(:shop_id)).order(:name)
    @organisations = Organisation.where(id: Specs::Project.where.not(organisation_id: nil).select(:organisation_id)).order(:name)
  end
end
