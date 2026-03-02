class Superadmin::OrganisationsController < Superadmin::BaseController
  before_action :set_organisation, only: [:manage, :update_specs_usage]

  def index
    @organisations = Organisation.order(created_at: :desc)
  end

  def create
    @organisation = Organisation.new(organisation_params)

    if @organisation.save
      redirect_to manage_superadmin_organisation_path(@organisation), notice: "Organisation created."
    else
      @organisations = Organisation.order(created_at: :desc)
      flash.now[:alert] = @organisation.errors.full_messages.join(", ")
      render :index, status: :unprocessable_entity
    end
  end

  def manage
    @clients = @organisation.specs_clients.order(:email)
    @projects = @organisation.specs_projects.order(created_at: :desc)
  end

  def update_specs_usage
    @organisation.specs_tier = params[:tier].presence
    @organisation.specs_monthly_limit = params[:monthly_limit].present? ? params[:monthly_limit].to_i : nil
    @organisation.specs_billing_cycle_anchor = params[:billing_cycle_anchor].presence

    if @organisation.specs_tier.present? && @organisation.specs_monthly_limit.nil?
      tier_config = Specs::UsageChecker::TIERS[@organisation.specs_tier]
      @organisation.specs_monthly_limit = tier_config[:default_limit] if tier_config
    end

    @organisation.save!
    redirect_to manage_superadmin_organisation_path(@organisation), notice: "Specs usage limits updated"
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
