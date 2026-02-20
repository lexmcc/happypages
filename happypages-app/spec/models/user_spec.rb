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

  describe "role" do
    it "defaults to owner" do
      user = create(:user)
      expect(user.role).to eq("owner")
    end

    it "validates role inclusion" do
      user = build(:user, role: "supervillain")
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("is not included in the list")
    end

    it "allows valid roles" do
      %w[owner admin member].each do |role|
        user = build(:user, role: role)
        expect(user).to be_valid
      end
    end

    it "allows nil role" do
      user = build(:user, role: nil)
      expect(user).to be_valid
    end
  end

  describe "invite_token" do
    it "can be set and cleared" do
      user = create(:user, invite_token: "abc123")
      expect(user.invite_token).to eq("abc123")
      user.update!(invite_token: nil)
      expect(user.reload.invite_token).to be_nil
    end
  end
end
