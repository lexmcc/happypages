class Superadmin::ImpersonationsController < Superadmin::BaseController
  def destroy
    shop_id = session.delete(:impersonating_shop_id)
    session.delete(:impersonation_started_at)

    if shop_id
      redirect_to manage_superadmin_shop_path(shop_id), notice: "Exited impersonation"
    else
      redirect_to superadmin_root_path
    end
  end
end
