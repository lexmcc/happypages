require "rails_helper"

RSpec.describe Specs::NotifyJob, type: :job do
  let(:shop) { create(:shop) }
  let(:user1) { create(:user, shop: shop) }
  let(:user2) { create(:user, shop: shop) }
  let(:project) { create(:specs_project, shop: shop) }
  let(:session) { create(:specs_session, project: project, shop: shop) }

  before do
    user1
    user2
  end

  it "creates notifications for all shop users" do
    expect {
      described_class.new.perform(
        action: "spec_completed",
        notifiable_type: "Specs::Session",
        notifiable_id: session.id,
        shop_id: shop.id,
        data: { project_name: project.name }
      )
    }.to change(Notification, :count).by(2)
  end

  it "excludes specified user" do
    expect {
      described_class.new.perform(
        action: "spec_completed",
        notifiable_type: "Specs::Session",
        notifiable_id: session.id,
        shop_id: shop.id,
        exclude_user_id: user1.id,
        data: { project_name: project.name }
      )
    }.to change(Notification, :count).by(1)

    expect(Notification.last.recipient).to eq(user2)
  end

  it "skips when shop not found" do
    expect {
      described_class.new.perform(
        action: "spec_completed",
        notifiable_type: "Specs::Session",
        notifiable_id: session.id,
        shop_id: 0,
        data: {}
      )
    }.not_to change(Notification, :count)
  end

  it "skips when notifiable not found" do
    expect {
      described_class.new.perform(
        action: "spec_completed",
        notifiable_type: "Specs::Session",
        notifiable_id: 0,
        shop_id: shop.id,
        data: {}
      )
    }.not_to change(Notification, :count)
  end

  it "respects notification preferences" do
    user1.update!(notification_preferences: { "spec_completed" => false })

    expect {
      described_class.new.perform(
        action: "spec_completed",
        notifiable_type: "Specs::Session",
        notifiable_id: session.id,
        shop_id: shop.id,
        data: { project_name: project.name }
      )
    }.to change(Notification, :count).by(1)

    expect(Notification.last.recipient).to eq(user2)
  end
end
