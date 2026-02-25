class Superadmin::OrganisationsController < Superadmin::BaseController
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
    @organisation = Organisation.find(params[:id])
    @clients = @organisation.specs_clients.order(:email)
    @projects = @organisation.specs_projects.order(created_at: :desc)
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
