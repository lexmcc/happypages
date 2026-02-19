class Admin::CustomerImportsController < Admin::BaseController
  def create
    existing = Current.shop.customer_imports.where(status: %w[pending running]).first
    if existing
      redirect_to edit_admin_settings_path, alert: "An import is already in progress."
      return
    end

    import = Current.shop.customer_imports.create!(status: "pending")
    CustomerImportJob.perform_later(import.id)

    redirect_to edit_admin_settings_path, notice: "Customer import started."
  end

  def status
    import = Current.shop.customer_imports.recent.first

    if import
      render json: {
        status: import.status,
        total_fetched: import.total_fetched,
        total_created: import.total_created,
        total_skipped: import.total_skipped,
        error_message: import.error_message,
        started_at: import.started_at,
        completed_at: import.completed_at
      }
    else
      render json: { status: "none" }
    end
  end
end
