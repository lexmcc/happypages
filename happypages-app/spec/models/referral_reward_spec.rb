require "rails_helper"

RSpec.describe ReferralReward, type: :model do
  let(:shop) { create(:shop) }
  let(:referral) { create(:referral, shop: shop) }

  describe "after_update callback" do
    it "enqueues RewardMetafieldSyncJob when status changes" do
      reward = referral.referral_rewards.create!(code: "R1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)

      expect {
        reward.mark_applied!(subscription_id: "sub_123", customer_id: "cust_123")
      }.to have_enqueued_job(RewardMetafieldSyncJob).with(referral.id)
    end

    it "does not enqueue when non-status attributes change" do
      reward = referral.referral_rewards.create!(code: "R1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)

      expect {
        reward.update!(expires_at: 60.days.from_now)
      }.not_to have_enqueued_job(RewardMetafieldSyncJob)
    end
  end
end
