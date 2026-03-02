require "rails_helper"

RSpec.describe "Webhooks multi-app HMAC verification", type: :request do
  let(:shop) { create(:shop) }
  let(:order_payload) do
    {
      id: "123456",
      customer: { email: "buyer@example.com", first_name: "Test", id: "gid://shopify/Customer/1" },
      discount_codes: [],
      total_price: "29.99",
      shipping_address: {},
      billing_address: {}
    }.to_json
  end

  def shopify_hmac(body, secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, body))
  end

  def post_order(body, secret)
    headers = {
      "X-Shopify-Shop-Domain" => shop.domain,
      "X-Shopify-Hmac-Sha256" => shopify_hmac(body, secret),
      "Content-Type" => "application/json"
    }
    post "/webhooks/orders", params: body, headers: headers
  end

  context "shop with app_client_secret set" do
    let!(:integration) do
      create(:shop_integration, :with_token, :with_custom_app, shop: shop, shopify_domain: shop.domain)
    end

    it "verifies HMAC against the per-shop app_client_secret" do
      post_order(order_payload, integration.app_client_secret)
      expect(response).to have_http_status(:ok)
    end

    it "rejects HMAC signed with the global secret" do
      post_order(order_payload, "global-secret")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "shop with null app_client_secret" do
    let!(:integration) do
      create(:shop_integration, :with_token, shop: shop, shopify_domain: shop.domain)
    end

    it "verifies HMAC against the global ENV secret" do
      post_order(order_payload, ENV.fetch("SHOPIFY_CLIENT_SECRET"))
      expect(response).to have_http_status(:ok)
    end
  end

  context "unknown shop" do
    it "falls back to global ENV secret" do
      body = order_payload
      secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
      headers = {
        "X-Shopify-Shop-Domain" => "unknown-shop.myshopify.com",
        "X-Shopify-Hmac-Sha256" => shopify_hmac(body, secret),
        "Content-Type" => "application/json"
      }
      post "/webhooks/orders", params: body, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
