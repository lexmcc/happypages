require "net/http"
require "json"

class CustomerImportJob < ApplicationJob
  queue_as :default

  API_VERSION = "2025-10"
  CUSTOMERS_PER_PAGE = 50
  METAFIELD_BATCH_SIZE = 25

  def perform(customer_import_id)
    import = CustomerImport.find_by(id: customer_import_id)
    return unless import
    return unless import.status.in?(%w[pending running])

    shop = import.shop
    return unless shop&.shopify?

    Current.shop = shop
    credentials = shop.shopify_credentials
    return unless credentials[:token].present?

    import.update!(status: "running", started_at: Time.current) if import.pending?

    total_fetched = import.total_fetched
    total_created = import.total_created
    total_skipped = import.total_skipped
    cursor = import.last_cursor
    metafield_batch = []

    loop do
      result = fetch_customers(credentials, cursor)
      edges = result.dig("data", "customers", "edges") || []
      break if edges.empty?

      edges.each do |edge|
        node = edge["node"]
        cursor = edge["cursor"]
        total_fetched += 1

        email = node["email"]
        if email.blank?
          total_skipped += 1
          next
        end

        first_name = node["firstName"].presence || email.split("@").first

        if Referral.where(shop: shop, email: email).exists?
          total_skipped += 1
          next
        end

        referral = Referral.create(
          shop: shop,
          email: email,
          first_name: first_name
        )

        unless referral.persisted?
          total_skipped += 1
          next
        end

        total_created += 1
        customer_gid = node["id"]

        metafield_batch << {
          ownerId: customer_gid,
          namespace: "app--happypages-friendly-referrals",
          key: "referral_code",
          value: referral.referral_code,
          type: "single_line_text_field"
        }

        if metafield_batch.size >= METAFIELD_BATCH_SIZE
          flush_metafields(credentials, metafield_batch)
          metafield_batch = []
        end
      end

      # Checkpoint progress after each page
      import.update!(
        total_fetched: total_fetched,
        total_created: total_created,
        total_skipped: total_skipped,
        last_cursor: cursor
      )

      has_next = result.dig("data", "customers", "pageInfo", "hasNextPage")
      break unless has_next
    end

    # Flush remaining metafields
    flush_metafields(credentials, metafield_batch) if metafield_batch.any?

    import.update!(
      status: "completed",
      total_fetched: total_fetched,
      total_created: total_created,
      total_skipped: total_skipped,
      completed_at: Time.current
    )
  rescue => e
    Rails.logger.error "CustomerImportJob failed: #{e.class} - #{e.message}"
    import&.update(
      status: "failed",
      error_message: e.message,
      total_fetched: total_fetched || import.total_fetched,
      total_created: total_created || import.total_created,
      total_skipped: total_skipped || import.total_skipped
    )
  end

  private

  def fetch_customers(credentials, cursor)
    after_clause = cursor ? ", after: \"#{cursor}\"" : ""

    query = <<~GRAPHQL
      query {
        customers(first: #{CUSTOMERS_PER_PAGE}, query: "orders_count:>0"#{after_clause}) {
          edges {
            cursor
            node {
              id
              email
              firstName
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    GRAPHQL

    execute_graphql(credentials, query)
  end

  def flush_metafields(credentials, batch)
    return if batch.empty?

    mutation = <<~GRAPHQL
      mutation metafieldsSet($metafields: [MetafieldsSetInput!]!) {
        metafieldsSet(metafields: $metafields) {
          metafields { id }
          userErrors { field message }
        }
      }
    GRAPHQL

    result = execute_graphql(credentials, mutation, { metafields: batch })
    errors = result.dig("data", "metafieldsSet", "userErrors")
    if errors.present? && errors.any?
      Rails.logger.warn "Metafield batch write had errors: #{errors.inspect}"
    end
  end

  def execute_graphql(credentials, query, variables = {})
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
    Rails.logger.error "CustomerImportJob Shopify API error: #{e.message}"
    { "errors" => [ { "message" => e.message } ] }
  end
end
