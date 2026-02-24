require "rails_helper"

RSpec.describe Specs::Message, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:session).class_name("Specs::Session").with_foreign_key(:specs_session_id) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[user assistant]) }
    it { is_expected.to validate_presence_of(:turn_number) }
  end

  describe "table name" do
    it "uses specs_messages table" do
      expect(described_class.table_name).to eq("specs_messages")
    end
  end

  describe "timestamps" do
    it "does not auto-update updated_at" do
      expect(described_class.record_timestamps).to be false
    end

    it "sets created_at on create" do
      session = create(:specs_session)
      message = session.messages.create!(role: "user", content: "test", turn_number: 1)
      expect(message.created_at).to be_present
    end
  end

  describe "#sender_name" do
    let(:session) { create(:specs_session) }

    it "returns nil for assistant messages" do
      message = build(:specs_message, :assistant, session: session)
      expect(message.sender_name).to be_nil
    end

    it "returns user email when user is present" do
      user = create(:user, shop: session.shop, email: "alice@example.com")
      message = build(:specs_message, session: session, role: "user", user: user, turn_number: 1)
      expect(message.sender_name).to eq("alice@example.com")
    end

    it "returns guest name from accepted handoff" do
      handoff = create(:specs_handoff, :accepted, session: session, to_name: "Bob Client", turn_number: 1)
      message = build(:specs_message, session: session, role: "user", user: nil, turn_number: 2)
      expect(message.sender_name([handoff])).to eq("Bob Client")
    end

    it "returns 'Guest' as fallback when no handoff matches" do
      message = build(:specs_message, session: session, role: "user", user: nil, turn_number: 1)
      expect(message.sender_name([])).to eq("Guest")
    end
  end
end
