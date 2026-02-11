namespace :shopify do
  desc "Register webhook for orders/create (SHOP_DOMAIN required)"
  task register_webhook: :environment do
    shop = Shop.find_by!(domain: ENV.fetch("SHOP_DOMAIN"))

    callback_url = ENV.fetch("WEBHOOK_CALLBACK_URL") do
      "https://app.happypages.co/webhooks/orders"
    end

    puts "Registering webhook for orders/create..."
    puts "Shop: #{shop.domain}"
    puts "Callback URL: #{callback_url}"

    service = ShopifyDiscountService.new(shop)
    result = service.register_webhook(callback_url: callback_url)

    if result.dig("data", "webhookSubscriptionCreate", "userErrors")&.any?
      puts "Error registering webhook:"
      result["data"]["webhookSubscriptionCreate"]["userErrors"].each do |error|
        puts "  - #{error['field']}: #{error['message']}"
      end
    elsif result["errors"]
      puts "GraphQL errors:"
      result["errors"].each { |e| puts "  - #{e['message']}" }
    else
      webhook_id = result.dig("data", "webhookSubscriptionCreate", "webhookSubscription", "id")
      puts "Webhook registered successfully!"
      puts "Webhook ID: #{webhook_id}"
    end
  end

  desc "List all webhooks (SHOP_DOMAIN required)"
  task list_webhooks: :environment do
    shop = Shop.find_by!(domain: ENV.fetch("SHOP_DOMAIN"))
    service = ShopifyDiscountService.new(shop)

    query = <<~GRAPHQL
      query {
        webhookSubscriptions(first: 10) {
          edges {
            node {
              id
              topic
              endpoint {
                ... on WebhookHttpEndpoint {
                  callbackUrl
                }
              }
            }
          }
        }
      }
    GRAPHQL

    result = service.send(:execute_graphql, query, {})

    puts "Registered webhooks:"
    webhooks = result.dig("data", "webhookSubscriptions", "edges") || []
    if webhooks.empty?
      puts "  (none)"
    else
      webhooks.each do |edge|
        node = edge["node"]
        puts "  - #{node['topic']}: #{node.dig('endpoint', 'callbackUrl')}"
        puts "    ID: #{node['id']}"
      end
    end
  end
end
