module Providers
  module Base
    class DiscountProvider
      def initialize(shop)
        @shop = shop
      end

      # Create the parent discount for a generation (with first referral code)
      def create_generation_discount(group:, initial_code:)
        raise NotImplementedError
      end

      # Add a referral code to an existing generation's discount
      def add_code_to_generation(code:, generation:)
        raise NotImplementedError
      end

      # Update discount value for a generation (for overrides/boosts)
      def update_generation_discount(generation:, discount_type:, discount_value:)
        raise NotImplementedError
      end

      # Create a reward discount for referrer
      def create_referrer_reward(referral_code:, usage_number:, customer_id:, discount_type:, discount_value:)
        raise NotImplementedError
      end

      # Get usage count for a discount code
      def get_discount_usage_count(code)
        raise NotImplementedError
      end

      # Check if a discount exists
      def discount_exists?(discount_id)
        raise NotImplementedError
      end

      # Get generation status (exists, synced)
      def get_generation_status(generation)
        raise NotImplementedError
      end

      protected

      attr_reader :shop
    end
  end
end
