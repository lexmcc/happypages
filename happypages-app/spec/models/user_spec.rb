require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:shop_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:shop) }
  end

  describe "#shopify_user?" do
    it "returns true when shopify_user_id present" do
      user = build(:user, :shopify_user)
      expect(user).to be_shopify_user
    end

    it "returns false when no shopify_user_id" do
      user = build(:user)
      expect(user).not_to be_shopify_user
    end
  end
end
