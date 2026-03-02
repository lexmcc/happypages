require "rails_helper"

RSpec.describe Specs::UsageChecker do
  describe "shop-scoped" do
    let(:shop) { create(:shop) }
    let!(:specs_feature) { create(:shop_feature, shop: shop, feature: "specs", status: "active") }

    it "returns unlimited when no limit set (nil)" do
      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:unlimited]).to be true
    end

    it "returns unlimited when limit is 0" do
      specs_feature.update!(metadata: { "monthly_limit" => 0 })
      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:unlimited]).to be true
    end

    it "can_create_session? returns true when under limit" do
      specs_feature.update!(metadata: { "monthly_limit" => 5 })
      project = create(:specs_project, shop: shop)
      create(:specs_session, project: project, shop: shop, status: "completed")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:used]).to eq(1)
      expect(checker.usage[:limit]).to eq(5)
    end

    it "can_create_session? returns false when at limit" do
      specs_feature.update!(metadata: { "monthly_limit" => 2 })
      project = create(:specs_project, shop: shop)
      create(:specs_session, project: project, shop: shop, status: "completed")
      create(:specs_session, project: project, shop: shop, status: "completed")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.can_create_session?).to be false
    end

    it "counts only completed sessions (not active)" do
      specs_feature.update!(metadata: { "monthly_limit" => 2 })
      project = create(:specs_project, shop: shop)
      create(:specs_session, project: project, shop: shop, status: "completed")
      create(:specs_session, project: project, shop: shop, status: "active")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.usage[:used]).to eq(1)
      expect(checker.can_create_session?).to be true
    end

    it "does not count archived sessions" do
      specs_feature.update!(metadata: { "monthly_limit" => 2 })
      project = create(:specs_project, shop: shop)
      create(:specs_session, project: project, shop: shop, status: "completed")
      create(:specs_session, project: project, shop: shop, status: "archived")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.usage[:used]).to eq(1)
      expect(checker.can_create_session?).to be true
    end

    it "counts only sessions within current billing cycle" do
      specs_feature.update!(metadata: { "monthly_limit" => 2 })
      project = create(:specs_project, shop: shop)

      # Old session from last month
      old_session = create(:specs_session, project: project, shop: shop, status: "completed")
      old_session.update_column(:created_at, 2.months.ago)

      # Current session
      create(:specs_session, project: project, shop: shop, status: "completed")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.usage[:used]).to eq(1)
    end

    it "uses billing_cycle_anchor when set" do
      specs_feature.update!(metadata: { "monthly_limit" => 5, "billing_cycle_anchor" => "2026-01-15" })

      checker = Specs::UsageChecker.new(shop: shop)
      cycle_start = checker.usage[:cycle_start]
      expect(cycle_start.day).to eq(15).or eq([15, Date.current.end_of_month.day].min)
    end

    it "defaults to 1st of month when no anchor" do
      specs_feature.update!(metadata: { "monthly_limit" => 5 })

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.usage[:cycle_start]).to eq(Date.current.beginning_of_month)
    end

    it "returns a limit_message when at limit" do
      specs_feature.update!(metadata: { "monthly_limit" => 1 })
      project = create(:specs_project, shop: shop)
      create(:specs_session, project: project, shop: shop, status: "completed")

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.limit_message).to include("1/1")
    end

    it "returns nil limit_message when under limit" do
      specs_feature.update!(metadata: { "monthly_limit" => 5 })

      checker = Specs::UsageChecker.new(shop: shop)
      expect(checker.limit_message).to be_nil
    end
  end

  describe "organisation-scoped" do
    let(:org) { create(:organisation) }

    it "returns unlimited when no limit set" do
      checker = Specs::UsageChecker.new(organisation: org)
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:unlimited]).to be true
    end

    it "can_create_session? returns true when under limit" do
      org.update!(specs_monthly_limit: 5)
      project = create(:specs_project, :org_scoped, organisation: org)
      create(:specs_session, :org_scoped, project: project, status: "completed")

      checker = Specs::UsageChecker.new(organisation: org)
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:used]).to eq(1)
    end

    it "can_create_session? returns false when at limit" do
      org.update!(specs_monthly_limit: 1)
      project = create(:specs_project, :org_scoped, organisation: org)
      create(:specs_session, :org_scoped, project: project, status: "completed")

      checker = Specs::UsageChecker.new(organisation: org)
      expect(checker.can_create_session?).to be false
    end

    it "uses specs_billing_cycle_anchor when set" do
      org.update!(specs_monthly_limit: 5, specs_billing_cycle_anchor: Date.new(2026, 1, 15))

      checker = Specs::UsageChecker.new(organisation: org)
      cycle_start = checker.usage[:cycle_start]
      expect(cycle_start.day).to eq(15).or eq([15, Date.current.end_of_month.day].min)
    end
  end

  describe "no owner" do
    it "returns 0 used with no shop or organisation" do
      checker = Specs::UsageChecker.new
      expect(checker.can_create_session?).to be true
      expect(checker.usage[:used]).to eq(0)
    end
  end
end
