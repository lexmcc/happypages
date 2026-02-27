module Specs
  class NotifyJob < ApplicationJob
    queue_as :default

    def perform(action:, notifiable_type:, notifiable_id:, data: {}, shop_id: nil, exclude_user_id: nil)
      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      return unless notifiable

      shop = shop_id ? Shop.find_by(id: shop_id) : nil
      return unless shop

      shop.users.find_each do |user|
        next if exclude_user_id && user.id == exclude_user_id
        Notification.notify(
          recipient: user,
          notifiable: notifiable,
          action: action,
          data: data
        )
      end
    end
  end
end
