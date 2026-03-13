require "rails_helper"

RSpec.describe Referral, type: :model do
  describe "#referral_page_url" do
    let(:shop) { create(:shop, slug: "fielddoctor") }

    it "returns the referral page URL with shop slug and referral code" do
      referral = Referral.create!(shop: shop, first_name: "John", email: "john@example.com")

      expect(referral.referral_page_url).to eq(
        "https://app.happypages.co/fielddoctor/refer?ref=#{referral.referral_code}"
      )
    end

    it "returns nil when shop has blank slug" do
      shop.update_column(:slug, "")
      referral = Referral.create!(shop: shop, first_name: "Jane", email: "jane@example.com")

      expect(referral.referral_page_url).to be_nil
    end
  end
end
