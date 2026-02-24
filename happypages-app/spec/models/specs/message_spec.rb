require "rails_helper"

RSpec.describe Specs::Message, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:session).class_name("Specs::Session").with_foreign_key(:specs_session_id) }
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
end
