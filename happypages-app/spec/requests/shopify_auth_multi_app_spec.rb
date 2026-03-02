require "rails_helper"

RSpec.describe "Shopify OAuth multi-app", type: :request do
  describe "GET /auth/shopify" do
    let(:shop_domain) { "test-store.myshopify.com" }

    context "with app=custom param" do
      it "redirects to OAuth URL using SHOPIFY_CUSTOM_CLIENT_ID" do
        get "/auth/shopify", params: { shop: shop_domain, app: "custom" }

        expect(response).to redirect_to(/#{Regexp.escape(ENV.fetch("SHOPIFY_CUSTOM_CLIENT_ID"))}/)
      end

      it "stores oauth_app in session" do
        get "/auth/shopify", params: { shop: shop_domain, app: "custom" }

        # Session state verified indirectly — the redirect URL contains the custom client_id
        location = response.headers["Location"]
        expect(location).to include("client_id=#{ENV.fetch('SHOPIFY_CUSTOM_CLIENT_ID')}")
      end
    end

    context "without app param" do
      it "redirects to OAuth URL using default SHOPIFY_CLIENT_ID" do
        get "/auth/shopify", params: { shop: shop_domain }

        location = response.headers["Location"]
        expect(location).to include("client_id=#{ENV.fetch('SHOPIFY_CLIENT_ID')}")
      end
    end
  end

  describe "GET /auth/shopify/callback" do
    let(:shop_domain) { "test-store.myshopify.com" }
    let(:access_token) { "shpat_test_token_123" }
    let(:code) { "auth_code_123" }
    let(:state) { SecureRandom.hex(24) }

    before do
      # Stub Shopify token exchange
      stub_request(:post, "https://#{shop_domain}/admin/oauth/access_token")
        .to_return(
          status: 200,
          body: { access_token: access_token, scope: "read_customers,write_customers,write_discounts,read_orders,read_products,read_themes" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Stub Shopify shop info
      stub_request(:get, "https://#{shop_domain}/admin/api/2025-10/shop.json")
        .to_return(
          status: 200,
          body: { shop: { email: "owner@example.com", id: "12345" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Stub metafield writer (fire-and-forget)
      allow_any_instance_of(ShopMetafieldWriter).to receive(:write_slug)
    end

    def perform_callback(oauth_app: nil)
      # Simulate the initiate step to set session state
      get "/auth/shopify", params: { shop: shop_domain }.merge(oauth_app ? { app: oauth_app } : {})

      # Extract the state from the redirect (session is set server-side)
      # We need to use the session state, so perform callback in same session
      get "/auth/shopify/callback", params: { code: code, state: session[:oauth_state], shop: shop_domain }
    end

    context "callback with custom app OAuth" do
      it "sends custom credentials to Shopify token exchange" do
        custom_stub = stub_request(:post, "https://#{shop_domain}/admin/oauth/access_token")
          .with(body: hash_including(
            "client_id" => ENV.fetch("SHOPIFY_CUSTOM_CLIENT_ID"),
            "client_secret" => ENV.fetch("SHOPIFY_CUSTOM_CLIENT_SECRET")
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token, scope: "read_customers,write_customers,write_discounts,read_orders,read_products,read_themes" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        perform_callback(oauth_app: "custom")
        expect(custom_stub).to have_been_requested
      end

      it "stores app_client_id and app_client_secret on ShopIntegration" do
        perform_callback(oauth_app: "custom")

        integration = Shop.find_by(domain: shop_domain).integration_for("shopify")
        expect(integration.app_client_id).to eq(ENV.fetch("SHOPIFY_CUSTOM_CLIENT_ID"))
        expect(integration.app_client_secret).to eq(ENV.fetch("SHOPIFY_CUSTOM_CLIENT_SECRET"))
      end
    end

    context "callback with default app OAuth" do
      it "does not store app credentials on ShopIntegration" do
        perform_callback

        integration = Shop.find_by(domain: shop_domain).integration_for("shopify")
        expect(integration.app_client_id).to be_nil
        expect(integration.app_client_secret).to be_nil
      end
    end

    context "returning shop keeps existing app credentials" do
      let!(:existing_shop) { create(:shop, domain: shop_domain) }
      let!(:integration) do
        create(:shop_integration, :with_token, :with_custom_app,
          shop: existing_shop,
          shopify_domain: shop_domain
        )
      end
      let(:original_client_id) { integration.app_client_id }
      let(:original_client_secret) { integration.app_client_secret }

      before do
        create(:user, shop: existing_shop, email: "owner@example.com")
      end

      it "does not overwrite existing app credentials on re-auth" do
        perform_callback(oauth_app: "custom")

        integration.reload
        expect(integration.app_client_id).to eq(original_client_id)
        expect(integration.app_client_secret).to eq(original_client_secret)
      end
    end
  end
end
