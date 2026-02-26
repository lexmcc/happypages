require "rails_helper"

RSpec.describe Specs::Client, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "validates email uniqueness per organisation" do
      org = create(:organisation)
      create(:specs_client, organisation: org, email: "test@example.com")
      dup = build(:specs_client, organisation: org, email: "test@example.com")
      expect(dup).not_to be_valid
    end

    it "allows same email in different organisations" do
      org1 = create(:organisation, name: "Org A")
      org2 = create(:organisation, name: "Org B")
      create(:specs_client, organisation: org1, email: "test@example.com")
      client2 = build(:specs_client, organisation: org2, email: "test@example.com")
      expect(client2).to be_valid
    end
  end

  describe "slack_user_id uniqueness" do
    it "enforces uniqueness per organisation" do
      org = create(:organisation)
      create(:specs_client, organisation: org, slack_user_id: "U123")
      dup = build(:specs_client, organisation: org, slack_user_id: "U123")
      expect(dup).not_to be_valid
    end

    it "allows same slack_user_id in different organisations" do
      org1 = create(:organisation, name: "Org A")
      org2 = create(:organisation, name: "Org B")
      create(:specs_client, organisation: org1, slack_user_id: "U123")
      client2 = build(:specs_client, organisation: org2, slack_user_id: "U123")
      expect(client2).to be_valid
    end

    it "allows multiple clients without slack_user_id" do
      org = create(:organisation)
      create(:specs_client, organisation: org, slack_user_id: nil)
      client2 = build(:specs_client, organisation: org, slack_user_id: nil)
      expect(client2).to be_valid
    end
  end

  describe "authenticatable" do
    it "authenticates with correct password" do
      client = create(:specs_client, :with_password)
      expect(client.authenticate("SecurePass123!")).to be_truthy
    end

    it "rejects incorrect password" do
      client = create(:specs_client, :with_password)
      expect(client.authenticate("wrong")).to be_falsy
    end
  end

  describe "invite helpers" do
    it "#invite_pending? returns true when token set but not accepted" do
      client = build(:specs_client, :invited)
      expect(client.invite_pending?).to be true
    end

    it "#invite_pending? returns false when accepted" do
      client = build(:specs_client, :accepted)
      expect(client.invite_pending?).to be false
    end

    it "#invite_accepted? returns true when accepted" do
      client = build(:specs_client, :accepted)
      expect(client.invite_accepted?).to be true
    end
  end
end
