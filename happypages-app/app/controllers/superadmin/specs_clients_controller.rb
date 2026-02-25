class Superadmin::SpecsClientsController < Superadmin::BaseController
  before_action :set_organisation

  def create
    client = @organisation.specs_clients.build(client_params)
    client.invite_token = SecureRandom.urlsafe_base64(32)
    client.invite_sent_at = Time.current
    client.invite_expires_at = 7.days.from_now

    if client.save
      SpecsClientMailer.invite_email(client).deliver_later
      redirect_to manage_superadmin_organisation_path(@organisation), notice: "Client created and invite sent to #{client.email}"
    else
      redirect_to manage_superadmin_organisation_path(@organisation), alert: client.errors.full_messages.join(", ")
    end
  end

  def send_invite
    client = @organisation.specs_clients.find(params[:id])
    client.update!(
      invite_token: SecureRandom.urlsafe_base64(32),
      invite_sent_at: Time.current,
      invite_expires_at: 7.days.from_now
    )
    SpecsClientMailer.invite_email(client).deliver_later
    redirect_to manage_superadmin_organisation_path(@organisation), notice: "Invite sent to #{client.email}"
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def client_params
    params.require(:specs_client).permit(:email, :name)
  end
end
