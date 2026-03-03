require "rails_helper"

RSpec.describe "Webhook order total persistence", type: :request do
  let(:shop) { create(:shop) }
  let!(:integration) { create(:shop_integration, :with_token, shop: shop, shopify_domain: shop.domain) }

  let(:referral) do
    Referral.create!(
      shop: shop,
      email: "referrer@example.com",
      first_name: "Jane",
      referral_code: "Jane001"
    )
  end

  let(:order_payload) do
    {
      id: "ORDER_789",
      customer: { email: "buyer@example.com", first_name: "Buyer", id: "gid://shopify/Customer/99" },
      discount_codes: [ { code: referral.referral_code, amount: "10.00", type: "percentage" } ],
      total_price: "49.95",
      shipping_address: {},
      billing_address: {}
    }.to_json
  end

  def shopify_hmac(body, secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, body))
  end

  before do
    # Stub discount provider to avoid Shopify API calls
    discount_provider = instance_double(Providers::Shopify::DiscountProvider)
    allow(discount_provider).to receive(:create_referrer_reward).and_return({
      success: true,
      reward_code: "REWARD-Jane001-1",
      result: { "data" => { "discountCodeBasicCreate" => { "codeDiscountNode" => { "id" => "gid://shopify/Discount/1" } } } }
    })

    customer_provider = instance_double(Providers::Shopify::CustomerProvider)
    allow(customer_provider).to receive(:lookup_by_email).and_return(nil)
    allow(customer_provider).to receive(:update_note).and_return({ success: true })

    allow_any_instance_of(Shop).to receive(:discount_provider).and_return(discount_provider)
    allow_any_instance_of(Shop).to receive(:customer_provider).and_return(customer_provider)

    # Stub SharedDiscount.current
    allow(SharedDiscount).to receive(:current).and_return(nil)
  end

  it "persists order_total_cents on the referral reward" do
    secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
    headers = {
      "X-Shopify-Shop-Domain" => shop.domain,
      "X-Shopify-Hmac-Sha256" => shopify_hmac(order_payload, secret),
      "Content-Type" => "application/json"
    }

    post "/webhooks/orders", params: order_payload, headers: headers

    expect(response).to have_http_status(:ok)

    reward = referral.referral_rewards.last
    expect(reward).to be_present
    expect(reward.order_total_cents).to eq(4995)
    expect(reward.shopify_order_id).to eq("ORDER_789")
  end

  it "stores 0 for a free order (total_price nil)" do
    payload = {
      id: "ORDER_790",
      customer: { email: "buyer2@example.com", first_name: "Buyer2", id: "gid://shopify/Customer/100" },
      discount_codes: [ { code: referral.referral_code, amount: "10.00", type: "percentage" } ],
      total_price: nil,
      shipping_address: {},
      billing_address: {}
    }.to_json

    secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
    headers = {
      "X-Shopify-Shop-Domain" => shop.domain,
      "X-Shopify-Hmac-Sha256" => shopify_hmac(payload, secret),
      "Content-Type" => "application/json"
    }

    # First order increments usage_count, so set it for the second
    referral.update!(usage_count: 1)

    post "/webhooks/orders", params: payload, headers: headers

    expect(response).to have_http_status(:ok)

    reward = referral.referral_rewards.last
    expect(reward).to be_present
    expect(reward.order_total_cents).to eq(0)
  end
end
