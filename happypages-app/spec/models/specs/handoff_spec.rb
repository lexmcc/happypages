require "rails_helper"

RSpec.describe Specs::Handoff, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:session).class_name("Specs::Session").with_foreign_key(:specs_session_id) }
    it { is_expected.to belong_to(:from_user).class_name("User").optional }
    it { is_expected.to belong_to(:to_user).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:from_name) }
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_presence_of(:turn_number) }
    it { is_expected.to validate_inclusion_of(:to_role).in_array(Specs::Handoff::ROLES).allow_nil }

    it "validates invite_token uniqueness" do
      existing = create(:specs_handoff, :with_invite)
      duplicate = build(:specs_handoff, invite_token: existing.invite_token)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:invite_token]).to be_present
    end

    it "prevents multiple pending handoffs per session" do
      session = create(:specs_session)
      create(:specs_handoff, session: session, turn_number: 1)
      second = build(:specs_handoff, session: session, turn_number: 2)
      expect(second).not_to be_valid
      expect(second.errors[:base]).to include("session already has a pending handoff")
    end

    it "allows a new handoff when previous is accepted" do
      session = create(:specs_session)
      create(:specs_handoff, :accepted, session: session, turn_number: 1)
      second = build(:specs_handoff, session: session, turn_number: 5)
      expect(second).to be_valid
    end
  end

  describe "#generate_invite_token!" do
    it "creates token and sets 7-day expiry" do
      handoff = create(:specs_handoff)
      expect(handoff.invite_token).to be_nil

      handoff.generate_invite_token!
      handoff.reload

      expect(handoff.invite_token).to be_present
      expect(handoff.invite_token.length).to be >= 32
      expect(handoff.invite_expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end

  describe "#expired?" do
    it "returns false when no expiry set" do
      handoff = build(:specs_handoff)
      expect(handoff.expired?).to be false
    end

    it "returns false when expiry is in the future" do
      handoff = build(:specs_handoff, invite_expires_at: 1.day.from_now)
      expect(handoff.expired?).to be false
    end

    it "returns true when expiry is in the past" do
      handoff = build(:specs_handoff, invite_expires_at: 1.day.ago)
      expect(handoff.expired?).to be true
    end
  end

  describe "#accepted?" do
    it "returns true when invite_accepted_at is set" do
      handoff = build(:specs_handoff, invite_accepted_at: Time.current)
      expect(handoff.accepted?).to be true
    end

    it "returns false when invite_accepted_at is nil" do
      handoff = build(:specs_handoff)
      expect(handoff.accepted?).to be false
    end
  end

  describe "#pending?" do
    it "returns true when token exists but not accepted" do
      handoff = build(:specs_handoff, :with_invite, invite_accepted_at: nil)
      expect(handoff.pending?).to be true
    end

    it "returns false when accepted" do
      handoff = build(:specs_handoff, :accepted)
      expect(handoff.pending?).to be false
    end

    it "returns false when no token" do
      handoff = build(:specs_handoff)
      expect(handoff.pending?).to be false
    end
  end

  describe "#internal?" do
    it "returns true when to_user is set" do
      handoff = build(:specs_handoff, :internal)
      expect(handoff.internal?).to be true
    end

    it "returns false when to_user is nil" do
      handoff = build(:specs_handoff)
      expect(handoff.internal?).to be false
    end
  end

  describe "scopes" do
    let(:session) { create(:specs_session) }

    it ".pending returns handoffs with token but not accepted" do
      pending = create(:specs_handoff, :with_invite, session: session, invite_accepted_at: nil)
      create(:specs_handoff, :accepted, session: create(:specs_session), turn_number: 2)
      expect(Specs::Handoff.pending).to eq([pending])
    end

    it ".accepted returns handoffs that have been accepted" do
      create(:specs_handoff, :with_invite, session: session, invite_accepted_at: nil)
      accepted = create(:specs_handoff, :accepted, session: create(:specs_session), turn_number: 2)
      expect(Specs::Handoff.accepted).to eq([accepted])
    end

    it ".not_expired excludes expired handoffs" do
      valid = create(:specs_handoff, session: session, invite_expires_at: 1.day.from_now)
      create(:specs_handoff, :expired, session: create(:specs_session), turn_number: 2)
      no_expiry = create(:specs_handoff, session: create(:specs_session), turn_number: 3)
      expect(Specs::Handoff.not_expired).to contain_exactly(valid, no_expiry)
    end
  end
end
