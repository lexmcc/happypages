module Providers
  module Base
    class OrderHandler
      def initialize(shop)
        @shop = shop
      end

      # Parse platform-specific order payload into normalized format
      # Returns: { order_id:, customer_email:, customer_id:, customer_first_name:,
      #            discount_codes_used:, total:, raw_payload: }
      def parse_order(payload)
        raise NotImplementedError
      end

      # Verify webhook signature
      def verify_signature(request, secret)
        raise NotImplementedError
      end

      # Extract shop identifier from webhook request (class method)
      def self.extract_shop_domain(request)
        raise NotImplementedError
      end

      protected

      attr_reader :shop
    end
  end
end
