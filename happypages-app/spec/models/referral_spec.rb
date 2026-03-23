require "rails_helper"

RSpec.describe Referral, type: :model do
  let(:shop) { create(:shop, slug: "test-shop", domain: "test-shop.myshopify.com") }

  describe "#referral_page_url" do
    it "returns the full referral page URL" do
      referral = build(:referral, shop: shop, referral_code: "Alex042")
      expect(referral.referral_page_url).to eq("https://test-shop.myshopify.com/test-shop/refer?code=Alex042")
    end

    it "uses customer_facing_url (storefront_url when set)" do
      shop.update!(storefront_url: "https://store.example.com")
      referral = build(:referral, shop: shop, referral_code: "Alex042")
      expect(referral.referral_page_url).to eq("https://store.example.com/test-shop/refer?code=Alex042")
    end

    it "returns nil when shop has no slug" do
      referral = build(:referral, shop: shop, referral_code: "Alex042")
      allow(shop).to receive(:slug).and_return(nil)
      expect(referral.referral_page_url).to be_nil
    end
  end

  describe "#actionable_reward" do
    let(:referral) { create(:referral, shop: shop) }

    it "returns nil when no rewards exist" do
      expect(referral.actionable_reward).to be_nil
    end

    it "prefers applied_to_subscription over created" do
      created = referral.referral_rewards.create!(code: "R1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)
      applied = referral.referral_rewards.create!(code: "R2", status: "applied_to_subscription", usage_number: 2, shop: shop, expires_at: 30.days.from_now)

      expect(referral.actionable_reward).to eq(applied)
    end

    it "returns oldest applied_to_subscription reward" do
      older = referral.referral_rewards.create!(code: "R1", status: "applied_to_subscription", usage_number: 1, shop: shop, expires_at: 30.days.from_now, created_at: 2.days.ago)
      newer = referral.referral_rewards.create!(code: "R2", status: "applied_to_subscription", usage_number: 2, shop: shop, expires_at: 30.days.from_now, created_at: 1.day.ago)

      expect(referral.actionable_reward).to eq(older)
    end

    it "returns created reward when no applied exists" do
      created = referral.referral_rewards.create!(code: "R1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)

      expect(referral.actionable_reward).to eq(created)
    end

    it "skips expired rewards for applied and created tiers" do
      expired_applied = referral.referral_rewards.create!(code: "R1", status: "applied_to_subscription", usage_number: 1, shop: shop, expires_at: 1.day.ago)
      created = referral.referral_rewards.create!(code: "R2", status: "created", usage_number: 2, shop: shop, expires_at: 30.days.from_now)

      expect(referral.actionable_reward).to eq(created)
    end

    it "falls back to most recent reward when all are terminal" do
      consumed = referral.referral_rewards.create!(code: "R1", status: "consumed", usage_number: 1, shop: shop, created_at: 2.days.ago)
      expired = referral.referral_rewards.create!(code: "R2", status: "expired", usage_number: 2, shop: shop, created_at: 1.day.ago)

      expect(referral.actionable_reward).to eq(expired)
    end
  end
end
