require "net/http"
require "json"

module Providers
  module Shopify
    class CustomerProvider < Base::CustomerProvider
      API_VERSION = "2025-10"

      def lookup_by_email(email)
        query = <<~GRAPHQL
          query customerByEmail($query: String!) {
            customers(first: 1, query: $query) {
              edges {
                node {
                  id
                }
              }
            }
          }
        GRAPHQL

        variables = { query: "email:#{email}" }
        result = execute_graphql(query, variables)

        result.dig("data", "customers", "edges", 0, "node", "id")
      end

      def get_note(customer_id)
        query = <<~GRAPHQL
          query customer($id: ID!) {
            customer(id: $id) {
              note
            }
          }
        GRAPHQL

        result = execute_graphql(query, { id: customer_id })
        result.dig("data", "customer", "note") || ""
      end

      def update_note(customer_id:, note:, append: false)
        final_note = if append
          existing_note = get_note(customer_id)
          existing_note.present? ? "#{existing_note}\n#{note}" : note
        else
          note
        end

        mutation = <<~GRAPHQL
          mutation customerUpdate($input: CustomerInput!) {
            customerUpdate(input: $input) {
              customer {
                id
                note
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        variables = {
          input: {
            id: customer_id,
            note: final_note
          }
        }

        result = execute_graphql(mutation, variables)

        if result.dig("data", "customerUpdate", "userErrors")&.empty? ||
           result.dig("data", "customerUpdate", "userErrors").nil?
          { success: true, note: final_note }
        else
          { success: false, errors: result.dig("data", "customerUpdate", "userErrors") }
        end
      end

      def set_metafield(customer_id:, namespace:, key:, value:, type: "single_line_text_field")
        mutation = <<~GRAPHQL
          mutation customerUpdate($input: CustomerInput!) {
            customerUpdate(input: $input) {
              customer { id }
              userErrors { field message }
            }
          }
        GRAPHQL

        variables = {
          input: {
            id: customer_id,
            metafields: [ { namespace: namespace, key: key, value: value, type: type } ]
          }
        }

        result = execute_graphql(mutation, variables)
        errors = result.dig("data", "customerUpdate", "userErrors")
        if errors.blank?
          { success: true }
        else
          { success: false, errors: errors }
        end
      end

      private

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
