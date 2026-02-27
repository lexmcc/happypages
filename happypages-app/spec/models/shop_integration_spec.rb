require "rails_helper"

RSpec.describe ShopIntegration, type: :model do
  describe "validations" do
    subject { build(:shop_integration) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:provider).scoped_to(:shop_id) }

    it "validates provider inclusion" do
      integration = build(:shop_integration, provider: "invalid")
      expect(integration).not_to be_valid
      expect(integration.errors[:provider]).to include("is not included in the list")
    end

    it "validates status inclusion" do
      integration = build(:shop_integration, status: "invalid")
      expect(integration).not_to be_valid
      expect(integration.errors[:status]).to include("is not included in the list")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:shop) }
  end

  describe "encryption" do
    it "encrypts shopify_access_token" do
      integration = create(:shop_integration, :with_token)
      raw_value = ShopIntegration.connection.select_value(
        "SELECT shopify_access_token FROM shop_integrations WHERE id = #{integration.id}"
      )
      expect(raw_value).not_to eq(integration.shopify_access_token)
    end
  end

  describe "scopes" do
    let(:shop) { create(:shop) }

    it ".active returns only active integrations" do
      active = create(:shop_integration, shop: shop, provider: "shopify", status: "active")
      create(:shop_integration, shop: shop, provider: "custom", status: "revoked")
      expect(ShopIntegration.active).to eq([active])
    end
  end

  describe "helpers" do
    it "#shopify? returns true for shopify provider" do
      expect(build(:shop_integration, provider: "shopify")).to be_shopify
    end

    it "#custom? returns true for custom provider" do
      expect(build(:shop_integration, :custom)).to be_custom
    end

    it "#linear? returns true for linear provider" do
      expect(build(:shop_integration, :linear)).to be_linear
    end

    it "#linear_connected? returns true when linear with token" do
      integration = build(:shop_integration, :linear)
      expect(integration).to be_linear_connected
    end

    it "#linear_connected? returns false without token" do
      integration = build(:shop_integration, provider: "linear", linear_access_token: nil)
      expect(integration).not_to be_linear_connected
    end
  end

  describe "linear encryption" do
    it "encrypts linear_access_token" do
      integration = create(:shop_integration, :linear)
      raw_value = ShopIntegration.connection.select_value(
        "SELECT linear_access_token FROM shop_integrations WHERE id = #{integration.id}"
      )
      expect(raw_value).not_to eq(integration.linear_access_token)
    end
  end
end
