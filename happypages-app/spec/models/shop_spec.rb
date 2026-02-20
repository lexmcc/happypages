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
    it "returns credentials hash for shopify shop with credential" do
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

  describe "slug generation" do
    it "auto-generates slug from name" do
      shop = create(:shop, name: "My Test Shop")
      expect(shop.slug).to eq("my-test-shop")
    end
  end
end
