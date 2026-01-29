module Providers
  module Custom
    class CustomerProvider < Base::CustomerProvider
      def lookup_by_email(email)
        raise NotImplementedError, "Custom platform customer lookup not yet implemented. Email: #{email}"
      end

      def get_note(customer_id)
        raise NotImplementedError, "Custom platform customer note retrieval not yet implemented. ID: #{customer_id}"
      end

      def update_note(customer_id:, note:, append: false)
        raise NotImplementedError, "Custom platform customer note update not yet implemented. ID: #{customer_id}"
      end
    end
  end
end
