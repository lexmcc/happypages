module Providers
  module Base
    class CustomerProvider
      def initialize(shop)
        @shop = shop
      end

      # Look up customer by email
      def lookup_by_email(email)
        raise NotImplementedError
      end

      # Update customer note
      def update_note(customer_id:, note:, append: false)
        raise NotImplementedError
      end

      # Get customer note
      def get_note(customer_id)
        raise NotImplementedError
      end

      # Set a metafield on a customer
      def set_metafield(customer_id:, namespace:, key:, value:, type: "single_line_text_field")
        raise NotImplementedError
      end

      # Set multiple metafields on a customer in a single API call
      def set_metafields(customer_id:, metafields:)
        raise NotImplementedError
      end

      protected

      attr_reader :shop
    end
  end
end
