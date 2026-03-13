require "rails_helper"

RSpec.describe "Webhook self-referral prevention", type: :request do
  let(:shop) { create(:shop) }
  let!(:integration) { create(:shop_integration, :with_token, shop: shop, shopify_domain: shop.domain) }

  let!(:referral) do
    Referral.create!(
      shop: shop,
      email: "alice@example.com",
      first_name: "Alice",
      referral_code: "Alice123"
    )
  end

  def shopify_hmac(body, secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, body))
  end

  def post_order(payload_json)
    secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
    headers = {
      "X-Shopify-Shop-Domain" => shop.domain,
      "X-Shopify-Hmac-Sha256" => shopify_hmac(payload_json, secret),
      "Content-Type" => "application/json"
    }
    post "/webhooks/orders", params: payload_json, headers: headers
  end

  before do
    discount_provider = instance_double(Providers::Shopify::DiscountProvider)
    allow(discount_provider).to receive(:create_referrer_reward).and_return({
      success: true,
      reward_code: "REWARD-Alice123-1",
      result: { "data" => { "discountCodeBasicCreate" => { "codeDiscountNode" => { "id" => "gid://shopify/Discount/1" } } } }
    })

    customer_provider = instance_double(Providers::Shopify::CustomerProvider)
    allow(customer_provider).to receive(:lookup_by_email).and_return(nil)
    allow(customer_provider).to receive(:update_note).and_return({ success: true })

    allow_any_instance_of(Shop).to receive(:discount_provider).and_return(discount_provider)
    allow_any_instance_of(Shop).to receive(:customer_provider).and_return(customer_provider)

    allow(SharedDiscount).to receive(:current).and_return(nil)
  end

  context "when buyer uses their own referral code" do
    let(:self_referral_payload) do
      {
        id: "ORDER_SELF_1",
        customer: { email: "alice@example.com", first_name: "Alice", id: "gid://shopify/Customer/1" },
        discount_codes: [{ code: "Alice123", amount: "10.00", type: "percentage" }],
        total_price: "49.95",
        shipping_address: {},
        billing_address: {}
      }.to_json
    end

    it "does not create a reward" do
      post_order(self_referral_payload)

      expect(response).to have_http_status(:ok)
      expect(referral.referral_rewards.count).to eq(0)
    end

    it "does not increment usage_count" do
      expect { post_order(self_referral_payload) }.not_to change { referral.reload.usage_count }
    end

    it "detects self-referral case-insensitively" do
      payload = {
        id: "ORDER_SELF_2",
        customer: { email: "ALICE@Example.COM", first_name: "Alice", id: "gid://shopify/Customer/1" },
        discount_codes: [{ code: "Alice123", amount: "10.00", type: "percentage" }],
        total_price: "49.95",
        shipping_address: {},
        billing_address: {}
      }.to_json

      post_order(payload)

      expect(response).to have_http_status(:ok)
      expect(referral.referral_rewards.count).to eq(0)
    end
  end

  context "when a different buyer uses the referral code" do
    let(:normal_referral_payload) do
      {
        id: "ORDER_NORMAL_1",
        customer: { email: "bob@example.com", first_name: "Bob", id: "gid://shopify/Customer/2" },
        discount_codes: [{ code: "Alice123", amount: "10.00", type: "percentage" }],
        total_price: "49.95",
        shipping_address: {},
        billing_address: {}
      }.to_json
    end

    it "creates a reward normally" do
      post_order(normal_referral_payload)

      expect(response).to have_http_status(:ok)
      expect(referral.referral_rewards.count).to eq(1)
    end

    it "increments usage_count" do
      expect { post_order(normal_referral_payload) }.to change { referral.reload.usage_count }.by(1)
    end
  end
end
