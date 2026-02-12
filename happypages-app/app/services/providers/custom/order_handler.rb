module Providers
  module Custom
    class OrderHandler < Base::OrderHandler
      # Expects a standardized format from custom platforms:
      # { order_id:, email:, customer_id:, first_name:, discount_codes:[], total: }
      def parse_order(payload)
        {
          order_id: payload["order_id"],
          customer_email: payload["email"],
          customer_id: payload["customer_id"],
          customer_first_name: payload["first_name"],
          discount_codes_used: payload["discount_codes"] || [],
          total: payload["total"].to_f,
          raw_payload: payload
        }
      end

      def verify_signature(request, secret)
        signature_header = request.headers["X-Webhook-Signature"]
        return false if signature_header.blank?

        request.body.rewind
        data = request.body.read

        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, data)
        ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
      end

      def self.extract_shop_domain(request)
        request.headers["X-Shop-Domain"]
      end
    end
  end
end
