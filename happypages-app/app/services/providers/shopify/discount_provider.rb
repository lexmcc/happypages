require "net/http"
require "json"

module Providers
  module Shopify
    class DiscountProvider < Base::DiscountProvider
      API_VERSION = "2025-10"

      def create_generation_discount(group:, initial_code:)
        discount_type = group.effective_referred_type
        discount_value = group.effective_referred_value

        result = create_shared_parent_discount(
          code: initial_code,
          discount_type: discount_type,
          discount_value: discount_value,
          title: "#{group.name} - Referral Discounts",
          applies_on_subscription: group.applies_on_subscription,
          applies_on_one_time_purchase: group.applies_on_one_time_purchase
        )

        discount_id = result.dig("data", "discountCodeBasicCreate", "codeDiscountNode", "id")
        errors = result.dig("data", "discountCodeBasicCreate", "userErrors")

        if discount_id.present?
          generation = group.create_new_generation!(shopify_discount_id: discount_id)
          { success: true, discount_id: discount_id, generation: generation }
        else
          { success: false, errors: errors || result["errors"] }
        end
      end

      def add_code_to_generation(code:, generation:)
        unless generation.shopify_discount_id.present?
          group = generation.shared_discount
          return create_generation_discount(group: group, initial_code: code)
        end

        mutation = <<~GRAPHQL
          mutation discountRedeemCodeBulkAdd($discountId: ID!, $codes: [DiscountRedeemCodeInput!]!) {
            discountRedeemCodeBulkAdd(discountId: $discountId, codes: $codes) {
              bulkCreation {
                id
                done
              }
              userErrors {
                code
                field
                message
              }
            }
          }
        GRAPHQL

        result = execute_graphql(mutation, {
          discountId: generation.shopify_discount_id,
          codes: [ { code: code } ]
        })

        errors = result.dig("data", "discountRedeemCodeBulkAdd", "userErrors")
        bulk_creation = result.dig("data", "discountRedeemCodeBulkAdd", "bulkCreation")

        if errors&.any?
          { success: false, errors: errors }
        elsif bulk_creation
          wait_for_bulk_completion(bulk_creation["id"]) if bulk_creation["id"] && !bulk_creation["done"]
          { success: true, discount_id: generation.shopify_discount_id, generation: generation }
        else
          { success: false, errors: result["errors"] }
        end
      end

      def update_generation_discount(generation:, discount_type:, discount_value:)
        return { success: false, error: "No Shopify discount ID" } unless generation&.shopify_discount_id.present?

        mutation = <<~GRAPHQL
          mutation discountCodeBasicUpdate($id: ID!, $basicCodeDiscount: DiscountCodeBasicInput!) {
            discountCodeBasicUpdate(id: $id, basicCodeDiscount: $basicCodeDiscount) {
              codeDiscountNode {
                id
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        value_input = build_value_input(discount_type, discount_value)

        result = execute_graphql(mutation, {
          id: generation.shopify_discount_id,
          basicCodeDiscount: {
            customerGets: {
              value: value_input,
              items: { all: true }
            }
          }
        })

        errors = result.dig("data", "discountCodeBasicUpdate", "userErrors")

        if errors&.empty? || errors.nil?
          { success: true, discount_id: generation.shopify_discount_id }
        else
          { success: false, errors: errors }
        end
      end

      def create_referrer_reward(referral_code:, usage_number:, customer_id: nil, discount_type: "percentage", discount_value: 50)
        reward_code = "REWARD-#{referral_code}-#{usage_number}"

        mutation = <<~GRAPHQL
          mutation discountCodeBasicCreate($basicCodeDiscount: DiscountCodeBasicInput!) {
            discountCodeBasicCreate(basicCodeDiscount: $basicCodeDiscount) {
              codeDiscountNode {
                id
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        value_input = build_value_input(discount_type, discount_value)

        customer_selection = if customer_id.present?
          { customers: { add: [ customer_id ] } }
        else
          { all: true }
        end

        variables = {
          basicCodeDiscount: {
            title: "Referrer Reward: #{reward_code}",
            code: reward_code,
            startsAt: Time.current.iso8601,
            endsAt: (Time.current + 30.days).iso8601,
            customerSelection: customer_selection,
            customerGets: {
              value: value_input,
              items: { all: true },
              appliesOnSubscription: true,
              appliesOnOneTimePurchase: true
            },
            usageLimit: 1,
            appliesOncePerCustomer: true
          }
        }

        result = execute_graphql(mutation, variables)

        if result.dig("data", "discountCodeBasicCreate", "userErrors")&.empty? ||
           result.dig("data", "discountCodeBasicCreate", "userErrors").nil?
          { success: true, reward_code: reward_code, result: result }
        else
          { success: false, errors: result.dig("data", "discountCodeBasicCreate", "userErrors"), result: result }
        end
      end

      def get_discount_usage_count(code)
        query = <<~GRAPHQL
          query discountCodeUsage($code: String!) {
            codeDiscountNodeByCode(code: $code) {
              codeDiscount {
                ... on DiscountCodeBasic {
                  asyncUsageCount
                }
              }
            }
          }
        GRAPHQL

        result = execute_graphql(query, { code: code })
        result.dig("data", "codeDiscountNodeByCode", "codeDiscount", "asyncUsageCount")
      end

      def discount_exists?(discount_id)
        query = <<~GRAPHQL
          query discountNode($id: ID!) {
            discountNode(id: $id) {
              id
            }
          }
        GRAPHQL

        result = execute_graphql(query, { id: discount_id })
        result.dig("data", "discountNode", "id").present?
      end

      def get_generation_status(generation)
        return { exists: false, synced: false } unless generation&.shopify_discount_id.present?

        {
          exists: true,
          synced: discount_exists?(generation.shopify_discount_id),
          discount_id: generation.shopify_discount_id
        }
      end

      private

      def create_shared_parent_discount(code:, discount_type:, discount_value:, title: "Referral Program - Discounts",
                                        applies_on_subscription: true, applies_on_one_time_purchase: true)
        mutation = <<~GRAPHQL
          mutation discountCodeBasicCreate($basicCodeDiscount: DiscountCodeBasicInput!) {
            discountCodeBasicCreate(basicCodeDiscount: $basicCodeDiscount) {
              codeDiscountNode {
                id
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        value_input = build_value_input(discount_type, discount_value)

        variables = {
          basicCodeDiscount: {
            title: title,
            code: code,
            startsAt: Time.current.iso8601,
            customerSelection: { all: true },
            customerGets: {
              value: value_input,
              items: { all: true },
              appliesOnSubscription: applies_on_subscription,
              appliesOnOneTimePurchase: applies_on_one_time_purchase
            },
            appliesOncePerCustomer: true
          }
        }

        execute_graphql(mutation, variables)
      end

      def wait_for_bulk_completion(job_id, max_attempts: 10)
        query = <<~GRAPHQL
          query discountRedeemCodeBulkCreation($id: ID!) {
            discountRedeemCodeBulkCreation(id: $id) {
              id
              done
            }
          }
        GRAPHQL

        max_attempts.times do
          result = execute_graphql(query, { id: job_id })
          return true if result.dig("data", "discountRedeemCodeBulkCreation", "done")
          sleep 0.3
        end

        false
      end

      def build_value_input(discount_type, discount_value)
        if discount_type == "percentage"
          { percentage: discount_value.to_f / 100 }
        else
          { discountAmount: { amount: discount_value.to_s, appliesOnEachItem: false } }
        end
      end

      def execute_graphql(query, variables)
        credentials = shop.shopify_credentials
        shop_url = credentials[:url]
        access_token = credentials[:token]

        uri = URI("https://#{shop_url}/admin/api/#{API_VERSION}/graphql.json")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request["Content-Type"] = "application/json"
        request["X-Shopify-Access-Token"] = access_token
        request.body = { query: query, variables: variables }.to_json

        response = http.request(request)
        JSON.parse(response.body)
      rescue => e
        Rails.logger.error "Shopify API error: #{e.message}"
        { "errors" => [ { "message" => e.message } ] }
      end
    end
  end
end
