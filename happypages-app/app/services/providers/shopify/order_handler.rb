module Providers
  module Shopify
    class OrderHandler < Base::OrderHandler
      def parse_order(payload)
        {
          order_id: payload["id"].to_s,
          customer_email: payload.dig("customer", "email"),
          customer_id: normalize_gid(payload.dig("customer", "id")),
          customer_first_name: payload.dig("customer", "first_name"),
          discount_codes_used: payload["discount_codes"]&.map { |d| d["code"] } || [],
          total: payload["total_price"].to_f,
          raw_payload: payload
        }
      end

      def verify_signature(request, secret)
        hmac_header = request.headers["X-Shopify-Hmac-Sha256"]
        return false if hmac_header.blank?

        request.body.rewind
        data = request.body.read

        calculated_hmac = Base64.strict_encode64(
          OpenSSL::HMAC.digest("sha256", secret, data)
        )

        ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
      end

      def self.extract_shop_domain(request)
        request.headers["X-Shopify-Shop-Domain"]
      end

      private

      def normalize_gid(id)
        return nil unless id
        id.to_s.include?("gid://") ? id.to_s : "gid://shopify/Customer/#{id}"
      end
    end
  end
end
