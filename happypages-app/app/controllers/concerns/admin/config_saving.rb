module Admin::ConfigSaving
  private

  def load_configs
    @configs = DiscountConfig.where(shop: Current.shop).index_by(&:config_key)
  end

  def save_configs(permitted_keys, blank_keys = [])
    (params[:configs] || {}).each do |key, value|
      next unless permitted_keys.include?(key.to_s)
      next if value.blank? && !blank_keys.include?(key.to_s)

      config = DiscountConfig.where(shop: Current.shop).find_or_initialize_by(config_key: key)
      config.shop ||= Current.shop
      config.config_value = value
      config.save!
    end
  end
end
