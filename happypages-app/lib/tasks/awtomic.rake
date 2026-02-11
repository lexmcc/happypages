namespace :awtomic do
  desc "Register Awtomic webhooks for reward lifecycle tracking (SHOP_DOMAIN required)"
  task register_webhooks: :environment do
    shop = Shop.find_by!(domain: ENV.fetch("SHOP_DOMAIN"))
    awtomic = AwtomicService.new(shop.awtomic_credentials[:api_key])
    base_url = ENV.fetch("WEBHOOK_BASE_URL") { raise "WEBHOOK_BASE_URL environment variable required" }
    url = "#{base_url}/webhooks/awtomic"

    actions = %w[baSuccess baFailure scUpdated]

    puts "Registering Awtomic webhooks to: #{url}"
    puts "Actions: #{actions.join(', ')}"
    puts

    begin
      result = awtomic.register_webhook(url: url, actions: actions)
      puts "Done! Webhook ID: #{result['webhookId'] || 'unknown'}"
    rescue => e
      puts "Error: #{e.message}"
    end

    puts
    puts "Next steps:"
    puts "1. Run `rails awtomic:list_webhooks` to see the webhooksSecret"
    puts "2. Set AWTOMIC_WEBHOOK_SECRET environment variable"
    puts "3. Deploy the application"
  end

  desc "List registered Awtomic webhooks (SHOP_DOMAIN required)"
  task list_webhooks: :environment do
    shop = Shop.find_by!(domain: ENV.fetch("SHOP_DOMAIN"))
    awtomic = AwtomicService.new(shop.awtomic_credentials[:api_key])

    puts "Fetching registered webhooks..."
    begin
      webhooks = awtomic.list_webhooks
      items = webhooks["Items"] || webhooks["webhooks"] || []

      if items.empty?
        puts "No webhooks registered."
      else
        puts "Registered webhooks:"
        items.each do |webhook|
          puts "  - #{webhook['EventType'] || webhook['eventType']}: #{webhook['CallbackUrl'] || webhook['callbackUrl']}"
        end
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  desc "Test webhook endpoint locally"
  task :test_webhook, [:event_type] => :environment do |_t, args|
    event_type = args[:event_type] || "baSuccess"

    test_payloads = {
      "baSuccess" => {
        "EventType" => "baSuccess",
        "SubscriptionId" => "gid://shopify/SubscriptionContract/123456",
        "CustomerId" => "123456",
        "BillingAttemptId" => "ba_test_123"
      },
      "scUpdated" => {
        "EventType" => "scUpdated",
        "SubscriptionId" => "gid://shopify/SubscriptionContract/123456",
        "SubscriptionStatus" => "CANCELLED",
        "CustomerId" => "123456"
      }
    }

    payload = test_payloads[event_type]
    unless payload
      puts "Unknown event type: #{event_type}"
      puts "Available: #{test_payloads.keys.join(', ')}"
      exit 1
    end

    puts "Test payload for #{event_type}:"
    puts JSON.pretty_generate(payload)
  end
end
