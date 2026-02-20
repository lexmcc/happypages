require "net/http"
require "json"

class ShopifyDiscountService
  API_VERSION = "2025-10"

  def initialize(shop)
    @shop = shop
    credentials = shop.shopify_credentials
    @shop_url = credentials[:url]
    @access_token = credentials[:token]
  end

  def register_webhook(callback_url:)
    mutation = <<~GRAPHQL
      mutation webhookSubscriptionCreate($topic: WebhookSubscriptionTopic!, $webhookSubscription: WebhookSubscriptionInput!) {
        webhookSubscriptionCreate(topic: $topic, webhookSubscription: $webhookSubscription) {
          webhookSubscription {
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    variables = {
      topic: "ORDERS_CREATE",
      webhookSubscription: {
        callbackUrl: callback_url,
        format: "JSON"
      }
    }

    execute_graphql(mutation, variables)
  end

  def lookup_customer_by_email(email)
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

    customer_id = result.dig("data", "customers", "edges", 0, "node", "id")
    customer_id
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

  def get_customer_note(customer_id)
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

  def update_customer_note(customer_id:, note:, append: false)
    final_note = if append
      existing_note = get_customer_note(customer_id)
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

    # If customer_id provided, restrict to that customer only
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

  def create_discount_code(referral_code:, discount_type:, discount_value:)
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
        title: "Referral: #{referral_code}",
        code: referral_code,
        startsAt: Time.current.iso8601,
        customerSelection: { all: true },
        customerGets: {
          value: value_input,
          items: { all: true }
        },
        appliesOncePerCustomer: true
      }
    }

    execute_graphql(mutation, variables)
  end

  # Shared Discount Methods for Mass Updates

  def get_or_create_shared_discount(discount_type:, discount_value:, initial_code:)
    shared = SharedDiscount.current(@shop)

    # If we have a shared discount, verify it still exists in Shopify
    if shared&.shopify_discount_id.present?
      if discount_exists?(shared.shopify_discount_id)
        return { success: true, discount_id: shared.shopify_discount_id, created: false }
      else
        # Discount was deleted in Shopify, clear our record
        shared.update!(shopify_discount_id: nil)
      end
    end

    # Create new shared discount with the first referral code
    result = create_shared_parent_discount(
      code: initial_code,
      discount_type: discount_type,
      discount_value: discount_value
    )

    discount_id = result.dig("data", "discountCodeBasicCreate", "codeDiscountNode", "id")
    errors = result.dig("data", "discountCodeBasicCreate", "userErrors")

    if discount_id.present?
      SharedDiscount.find_or_create_by!(discount_type: "referred") do |sd|
        sd.shopify_discount_id = discount_id
      end.update!(shopify_discount_id: discount_id)

      { success: true, discount_id: discount_id, created: true }
    else
      { success: false, errors: errors || result["errors"] }
    end
  rescue ActiveRecord::RecordNotUnique
    # Race condition - another process created it, retry
    retry
  end

  def add_code_to_shared_discount(code:, discount_type:, discount_value:)
    shared = SharedDiscount.current(@shop)

    # If no shared discount exists yet, create it with this code as the first
    unless shared&.shopify_discount_id.present?
      return get_or_create_shared_discount(
        discount_type: discount_type,
        discount_value: discount_value,
        initial_code: code
      )
    end

    # Add code to existing shared discount
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
      discountId: shared.shopify_discount_id,
      codes: [ { code: code } ]
    })

    errors = result.dig("data", "discountRedeemCodeBulkAdd", "userErrors")
    bulk_creation = result.dig("data", "discountRedeemCodeBulkAdd", "bulkCreation")

    if errors&.any?
      { success: false, errors: errors }
    elsif bulk_creation
      # Wait for bulk operation to complete (usually instant for single code)
      wait_for_bulk_completion(bulk_creation["id"]) if bulk_creation["id"] && !bulk_creation["done"]
      { success: true, discount_id: shared.shopify_discount_id }
    else
      { success: false, errors: result["errors"] }
    end
  end

  def update_shared_discount(discount_type:, discount_value:)
    shared = SharedDiscount.current(@shop)
    return { success: false, error: "No shared discount found" } unless shared&.shopify_discount_id.present?

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
      id: shared.shopify_discount_id,
      basicCodeDiscount: {
        customerGets: {
          value: value_input,
          items: { all: true }
        }
      }
    })

    errors = result.dig("data", "discountCodeBasicUpdate", "userErrors")

    if errors&.empty? || errors.nil?
      { success: true, discount_id: shared.shopify_discount_id }
    else
      { success: false, errors: errors }
    end
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

  def get_shared_discount_status
    group = SharedDiscount.current(@shop)
    generation = group&.current_generation
    return { exists: false, synced: false } unless generation&.shopify_discount_id.present?

    {
      exists: true,
      synced: discount_exists?(generation.shopify_discount_id),
      discount_id: generation.shopify_discount_id
    }
  end

  # Generation-based methods for new architecture

  def create_generation_discount(group:, initial_code:)
    # Use effective values (considers override if active)
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
    # If generation has no Shopify discount yet, create one
    unless generation.shopify_discount_id.present?
      group = generation.shared_discount
      result = create_generation_discount(group: group, initial_code: code)
      return result
    end

    # Add code to existing generation's Shopify discount
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
    uri = URI("https://#{@shop_url}/admin/api/#{API_VERSION}/graphql.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["X-Shopify-Access-Token"] = @access_token
    request.body = { query: query, variables: variables }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Shopify API error: #{e.message}"
    { "errors" => [ { "message" => e.message } ] }
  end
end
