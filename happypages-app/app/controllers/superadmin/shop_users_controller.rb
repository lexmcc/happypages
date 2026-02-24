class Superadmin::ShopUsersController < Superadmin::BaseController
  before_action :set_shop

  def create
    user = @shop.users.build(user_params)
    user.invite_token = SecureRandom.urlsafe_base64(32)
    user.invite_sent_at = Time.current

    if user.save
      InviteMailer.invite_email(user).deliver_later
      audit!(action: "create", shop: @shop, details: { email: user.email, role: user.role })
      redirect_to manage_superadmin_shop_path(@shop), notice: "User created and invite sent to #{user.email}"
    else
      redirect_to manage_superadmin_shop_path(@shop), alert: user.errors.full_messages.join(", ")
    end
  end

  def send_invite
    user = @shop.users.find(params[:id])
    user.update!(
      invite_token: SecureRandom.urlsafe_base64(32),
      invite_sent_at: Time.current
    )
    InviteMailer.invite_email(user).deliver_later
    audit!(action: "update", shop: @shop, details: { email: user.email, change: "invite_sent" })
    redirect_to manage_superadmin_shop_path(@shop), notice: "Invite sent to #{user.email}"
  end

  private

  def set_shop
    @shop = Shop.find(params[:shop_id])
  end

  def user_params
    params.require(:user).permit(:email, :role)
  end
end
