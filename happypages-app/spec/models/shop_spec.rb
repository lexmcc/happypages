require "rails_helper"

RSpec.describe Shop, type: :model do
  describe "validations" do
    subject { build(:shop) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:platform_type) }

    it "validates uniqueness of domain" do
      create(:shop, domain: "duplicate.myshopify.com")
      shop = build(:shop, domain: "duplicate.myshopify.com")
      expect(shop).not_to be_valid
      expect(shop.errors[:domain]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:shop_credential).dependent(:destroy) }
    it { is_expected.to have_many(:shop_features).dependent(:destroy) }
    it { is_expected.to have_many(:shop_integrations).dependent(:destroy) }
    it { is_expected.to have_many(:users).dependent(:destroy) }
  end

  describe "#shopify?" do
    it "returns true for shopify shops" do
      shop = build(:shop, platform_type: "shopify")
      expect(shop).to be_shopify
    end

    it "returns false for custom shops" do
      shop = build(:shop, platform_type: "custom")
      expect(shop).not_to be_shopify
    end
  end

  describe "#shopify_credentials" do
    it "returns credentials from ShopIntegration when present" do
      shop = create(:shop)
      integration = create(:shop_integration, :with_token, shop: shop)
      creds = shop.shopify_credentials
      expect(creds[:url]).to eq(integration.shopify_domain)
      expect(creds[:token]).to eq(integration.shopify_access_token)
    end

    it "falls back to ShopCredential when no integration" do
      shop = create(:shop, :with_credential)
      creds = shop.shopify_credentials
      expect(creds[:url]).to eq(shop.domain)
      expect(creds[:token]).to be_present
    end

    it "returns nil for non-shopify shops" do
      shop = build(:shop, :custom)
      expect(shop.shopify_credentials).to be_nil
    end
  end

  describe "#feature_enabled?" do
    it "returns true for active features" do
      shop = create(:shop)
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      expect(shop.feature_enabled?("referrals")).to be true
    end

    it "returns false for locked features" do
      shop = create(:shop)
      create(:shop_feature, shop: shop, feature: "referrals", status: "locked")
      expect(shop.feature_enabled?("referrals")).to be false
    end

    it "returns false for missing features" do
      shop = create(:shop)
      expect(shop.feature_enabled?("referrals")).to be false
    end
  end

  describe "#integration_for" do
    it "returns active integration for provider" do
      shop = create(:shop)
      integration = create(:shop_integration, shop: shop, provider: "shopify")
      expect(shop.integration_for("shopify")).to eq(integration)
    end

    it "returns nil for revoked integration" do
      shop = create(:shop)
      create(:shop_integration, shop: shop, provider: "shopify", status: "revoked")
      expect(shop.integration_for("shopify")).to be_nil
    end

    it "returns nil when no integration exists" do
      shop = create(:shop)
      expect(shop.integration_for("shopify")).to be_nil
    end
  end

  describe ".find_by_shopify_domain" do
    it "finds shop by shopify domain on integration" do
      shop = create(:shop)
      create(:shop_integration, shop: shop, provider: "shopify", shopify_domain: "test.myshopify.com")
      expect(Shop.find_by_shopify_domain("test.myshopify.com")).to eq(shop)
    end

    it "returns nil when no match" do
      expect(Shop.find_by_shopify_domain("nonexistent.myshopify.com")).to be_nil
    end
  end

  describe "slug generation" do
    it "auto-generates slug from name" do
      shop = create(:shop, name: "My Test Shop")
      expect(shop.slug).to eq("my-test-shop")
    end
  end
end
