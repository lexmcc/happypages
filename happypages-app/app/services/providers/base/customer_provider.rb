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

      protected

      attr_reader :shop
    end
  end
end
