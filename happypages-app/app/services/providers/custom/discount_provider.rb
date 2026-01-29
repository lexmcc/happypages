module Providers
  module Custom
    class DiscountProvider < Base::DiscountProvider
      def create_generation_discount(group:, initial_code:)
        raise NotImplementedError, "Custom platform discount creation not yet implemented. Code: #{initial_code}"
      end

      def add_code_to_generation(code:, generation:)
        raise NotImplementedError, "Custom platform discount code addition not yet implemented. Code: #{code}"
      end

      def update_generation_discount(generation:, discount_type:, discount_value:)
        raise NotImplementedError, "Custom platform discount update not yet implemented"
      end

      def create_referrer_reward(referral_code:, usage_number:, customer_id: nil, discount_type: "percentage", discount_value: 50)
        raise NotImplementedError, "Custom platform reward creation not yet implemented. Code: REWARD-#{referral_code}-#{usage_number}"
      end

      def get_discount_usage_count(code)
        raise NotImplementedError, "Custom platform usage count not yet implemented. Code: #{code}"
      end

      def discount_exists?(discount_id)
        raise NotImplementedError, "Custom platform discount check not yet implemented. ID: #{discount_id}"
      end

      def get_generation_status(generation)
        { exists: false, synced: false, message: "Custom platform not yet implemented" }
      end
    end
  end
end
