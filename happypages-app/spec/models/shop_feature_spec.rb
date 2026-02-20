require "rails_helper"

RSpec.describe ShopFeature, type: :model do
  describe "validations" do
    subject { build(:shop_feature) }

    it { is_expected.to validate_presence_of(:feature) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:feature).scoped_to(:shop_id) }

    it "validates feature inclusion" do
      feature = build(:shop_feature, feature: "invalid_feature")
      expect(feature).not_to be_valid
      expect(feature.errors[:feature]).to include("is not included in the list")
    end

    it "validates status inclusion" do
      feature = build(:shop_feature, status: "invalid_status")
      expect(feature).not_to be_valid
      expect(feature.errors[:status]).to include("is not included in the list")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:shop) }
  end

  describe "scopes" do
    let(:shop) { create(:shop) }

    it ".active returns only active features" do
      active = create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      create(:shop_feature, shop: shop, feature: "analytics", status: "locked")
      expect(ShopFeature.active).to eq([active])
    end

    it ".locked returns only locked features" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      locked = create(:shop_feature, shop: shop, feature: "analytics", status: "locked")
      expect(ShopFeature.locked).to eq([locked])
    end
  end

  describe "helpers" do
    it "#active? returns true for active status" do
      expect(build(:shop_feature, status: "active")).to be_active
    end

    it "#locked? returns true for locked status" do
      expect(build(:shop_feature, :locked)).to be_locked
    end

    it "#trial? returns true for trial status" do
      expect(build(:shop_feature, :trial)).to be_trial
    end
  end
end
