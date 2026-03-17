require "net/http"
require "json"

class ShopMetafieldWriter
  API_VERSION = "2025-10"

  def initialize(shop)
    @shop = shop
  end

  def write_slug
    return unless @shop.shopify? && @shop.slug.present?

    credentials = @shop.shopify_credentials
    return unless credentials[:token].present?

    shop_gid = fetch_shop_gid(credentials)
    return unless shop_gid

    set_metafield(
      credentials: credentials,
      owner_id: shop_gid,
      namespace: @shop.metafield_namespace,
      key: "shop_slug",
      value: @shop.slug
    )
  end

  CUSTOMER_METAFIELD_DEFINITIONS = [
    { key: "referral_code", name: "Referral Code" },
    { key: "referral_page_url", name: "Referral Page URL" },
    { key: "reward_discount_code", name: "Reward Discount Code" },
    { key: "reward_status", name: "Reward Status" }
  ].freeze

  def create_customer_metafield_definitions
    return unless @shop.shopify?

    credentials = @shop.shopify_credentials
    return unless credentials[:token].present?

    namespace = @shop.metafield_namespace

    CUSTOMER_METAFIELD_DEFINITIONS.each do |defn|
      create_metafield_definition(
        credentials: credentials,
        namespace: namespace,
        key: defn[:key],
        name: defn[:name]
      )
    end
  end

  private

  def fetch_shop_gid(credentials)
    query = <<~GRAPHQL
      query {
        shop { id }
      }
    GRAPHQL

    result = execute_graphql(credentials, query, {})
    result.dig("data", "shop", "id")
  end

  def set_metafield(credentials:, owner_id:, namespace:, key:, value:)
    mutation = <<~GRAPHQL
      mutation metafieldsSet($metafields: [MetafieldsSetInput!]!) {
        metafieldsSet(metafields: $metafields) {
          metafields { id }
          userErrors { field message }
        }
      }
    GRAPHQL

    variables = {
      metafields: [ {
        namespace: namespace,
        key: key,
        value: value,
        type: "single_line_text_field",
        ownerId: owner_id
      } ]
    }

    result = execute_graphql(credentials, mutation, variables)
    errors = result.dig("data", "metafieldsSet", "userErrors")

    if errors.present?
      Rails.logger.error "Shop metafield write failed: #{errors.inspect}"
    end

    result
  end

  def create_metafield_definition(credentials:, namespace:, key:, name:)
    mutation = <<~GRAPHQL
      mutation metafieldDefinitionCreate($definition: MetafieldDefinitionInput!) {
        metafieldDefinitionCreate(definition: $definition) {
          createdDefinition { id }
          userErrors { field message }
        }
      }
    GRAPHQL

    variables = {
      definition: {
        name: name,
        namespace: namespace,
        key: key,
        type: "single_line_text_field",
        ownerType: "CUSTOMER",
        pin: true
      }
    }

    result = execute_graphql(credentials, mutation, variables)
    errors = result.dig("data", "metafieldDefinitionCreate", "userErrors")

    if errors.present?
      Rails.logger.info "Metafield definition #{namespace}.#{key}: #{errors.inspect}"
    end
  end

  def execute_graphql(credentials, query, variables)
    uri = URI("https://#{credentials[:url]}/admin/api/#{API_VERSION}/graphql.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["X-Shopify-Access-Token"] = credentials[:token]
    request.body = { query: query, variables: variables }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Shop metafield API error: #{e.message}"
    { "errors" => [ { "message" => e.message } ] }
  end
end
