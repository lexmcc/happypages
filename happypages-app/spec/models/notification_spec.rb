require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_inclusion_of(:action).in_array(Notification::ACTIONS) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:recipient) }
    it { is_expected.to belong_to(:notifiable) }
  end

  describe "scopes" do
    it ".unread returns only unread notifications" do
      unread = create(:notification)
      _read = create(:notification, :read)
      expect(Notification.unread).to eq([unread])
    end

    it ".recent returns ordered and limited" do
      old = create(:notification, created_at: 2.days.ago)
      recent = create(:notification, created_at: 1.hour.ago)
      expect(Notification.recent.first).to eq(recent)
    end
  end

  describe "#mark_read!" do
    it "sets read_at" do
      notification = create(:notification)
      expect { notification.mark_read! }.to change { notification.reload.read_at }.from(nil)
    end

    it "does not update if already read" do
      notification = create(:notification, :read)
      original_read_at = notification.read_at
      notification.mark_read!
      expect(notification.reload.read_at).to eq(original_read_at)
    end
  end

  describe ".notify" do
    let(:user) { create(:user) }
    let(:session) { create(:specs_session) }

    it "creates a notification" do
      expect {
        Notification.notify(recipient: user, notifiable: session, action: "spec_completed")
      }.to change(Notification, :count).by(1)
    end

    it "skips when preference is muted" do
      user.update!(notification_preferences: { "spec_completed" => false })
      expect {
        Notification.notify(recipient: user, notifiable: session, action: "spec_completed")
      }.not_to change(Notification, :count)
    end

    it "uses create (no bang) — does not raise on failure" do
      expect {
        Notification.notify(recipient: user, notifiable: session, action: "invalid_action")
      }.not_to raise_error
    end
  end
end
