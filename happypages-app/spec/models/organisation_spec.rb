require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:specs_clients).class_name("Specs::Client").dependent(:destroy) }
    it { is_expected.to have_many(:specs_projects).class_name("Specs::Project").dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_presence_of(:slug) }

    it "validates slug uniqueness" do
      create(:organisation, slug: "test-org")
      org = build(:organisation, slug: "test-org")
      expect(org).not_to be_valid
    end

    it "validates slug format" do
      org = build(:organisation, slug: "INVALID SLUG!")
      expect(org).not_to be_valid
      expect(org.errors[:slug]).to include("only allows lowercase letters, numbers, and hyphens")
    end

    it "validates slug length" do
      org = build(:organisation, slug: "ab")
      expect(org).not_to be_valid

      org = build(:organisation, slug: "a" * 51)
      expect(org).not_to be_valid
    end
  end

  describe "encryption" do
    it "encrypts slack_bot_token" do
      org = create(:organisation, :with_slack)
      expect(org.slack_bot_token).to start_with("xoxb-test-")
      # Verify the raw DB value is not the plaintext
      raw = Organisation.connection.select_value(
        "SELECT slack_bot_token FROM organisations WHERE id = #{org.id}"
      )
      expect(raw).not_to start_with("xoxb-") if raw.present?
    end
  end

  describe "#slack_connected?" do
    it "returns true when bot token present" do
      org = build(:organisation, :with_slack)
      expect(org.slack_connected?).to be true
    end

    it "returns false when bot token absent" do
      org = build(:organisation)
      expect(org.slack_connected?).to be false
    end
  end

  describe "#slack_client" do
    it "returns a Slack::Web::Client with the bot token" do
      org = build(:organisation, :with_slack)
      client = org.slack_client
      expect(client).to be_a(::Slack::Web::Client)
    end
  end

  describe "slug generation" do
    it "auto-generates slug from name" do
      org = create(:organisation, name: "My Company")
      expect(org.slug).to eq("my-company")
    end

    it "handles duplicate slugs with counter" do
      create(:organisation, name: "Acme Corp")
      org = create(:organisation, name: "Acme Corp")
      expect(org.slug).to eq("acme-corp-1")
    end

    it "does not overwrite existing slug" do
      org = create(:organisation, name: "Test", slug: "custom-slug")
      expect(org.slug).to eq("custom-slug")
    end
  end
end
