class Admin::NotificationsController < Admin::BaseController
  def index
    unless current_user
      respond_to do |format|
        format.html { redirect_to admin_dashboard_path }
        format.json { render json: { unread_count: 0 } }
      end
      return
    end

    @notifications = current_user.notifications.order(created_at: :desc).limit(50)

    respond_to do |format|
      format.html
      format.json { render json: { unread_count: current_user.unread_notification_count } }
    end
  end

  def mark_read
    return redirect_to admin_dashboard_path unless current_user

    notification = current_user.notifications.find(params[:id])
    notification.mark_read!
    redirect_to notification_target_path(notification) || admin_notifications_path
  end

  def mark_all_read
    return redirect_to admin_dashboard_path unless current_user

    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to admin_notifications_path, notice: "All notifications marked as read."
  end

  def update_preferences
    return redirect_to admin_dashboard_path unless current_user

    current_user.update!(notification_preferences: preference_params)
    redirect_to admin_notifications_path, notice: "Notification preferences saved."
  end

  private

  def notification_target_path(notification)
    case notification.notifiable_type
    when "Specs::Session", "Specs::Card"
      admin_spec_path(notification.data["project_id"]) if notification.data["project_id"]
    when "Specs::Project"
      admin_spec_path(notification.notifiable_id)
    end
  end

  def preference_params
    Notification::ACTIONS.each_with_object({}) do |action, hash|
      hash[action] = params.dig(:preferences, action) != "0"
    end
  end
end
