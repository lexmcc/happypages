require "rails_helper"

RSpec.describe Referrals::PerformanceQueryService do
  let(:shop) { create(:shop) }
  let(:period_range) { 7.days.ago..Time.current }
  let(:comparison_range) { 14.days.ago..7.days.ago }

  subject(:service) { described_class.new(shop: shop, period_range: period_range) }

  def create_event(event_type:, source: ReferralEvent::CHECKOUT_EXTENSION, created_at: 1.day.ago)
    ReferralEvent.create!(
      shop: shop,
      event_type: event_type,
      source: source,
      created_at: created_at
    )
  end

  def create_reward(referral:, order_total_cents: 5000, created_at: 1.day.ago)
    referral.referral_rewards.create!(
      shop: shop,
      code: "REWARD-#{SecureRandom.hex(4)}",
      shopify_order_id: "ORDER-#{SecureRandom.hex(4)}",
      order_total_cents: order_total_cents,
      status: "created",
      usage_number: referral.usage_count,
      expires_at: 30.days.from_now,
      created_at: created_at
    )
  end

  describe ".period_to_range" do
    it "returns today range" do
      range = described_class.period_to_range("today")
      expect(range.first).to be_within(1.second).of(Date.current.beginning_of_day)
      expect(range.last).to be_within(1.second).of(Time.current)
    end

    it "returns 7d range" do
      range = described_class.period_to_range("7d")
      expect(range.first).to be_within(1.second).of(7.days.ago)
    end

    it "returns 30d range" do
      range = described_class.period_to_range("30d")
      expect(range.first).to be_within(1.second).of(30.days.ago)
    end

    it "returns 90d range" do
      range = described_class.period_to_range("90d")
      expect(range.first).to be_within(1.second).of(90.days.ago)
    end

    it "returns custom range from parsed dates" do
      range = described_class.period_to_range("custom", from: "2026-01-01", to: "2026-01-31")
      expect(range.first).to eq(Date.parse("2026-01-01").beginning_of_day)
      expect(range.last).to eq(Date.parse("2026-01-31").end_of_day)
    end

    it "falls back to 30d for unknown period" do
      range = described_class.period_to_range("unknown")
      expect(range.first).to be_within(1.second).of(30.days.ago)
    end
  end

  describe ".comparison_range_for" do
    it "returns previous period of equal duration" do
      range = 7.days.ago..Time.current
      comp = described_class.comparison_range_for(range)
      expect(comp.first).to be_within(1.second).of(14.days.ago)
      expect(comp.last).to be_within(1.second).of(7.days.ago)
    end
  end

  describe "#call" do
    it "returns all sections" do
      result = service.call
      expect(result.keys).to contain_exactly(:kpis, :sparklines, :time_series, :funnel, :source_breakdown, :top_referrers)
    end
  end

  describe "KPIs" do
    context "with data" do
      let!(:referral) do
        Referral.create!(shop: shop, email: "ref@example.com", first_name: "Jane", referral_code: "Jane001", usage_count: 2)
      end

      before do
        # 10 extension loads
        10.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD) }
        # 5 page visits
        5.times { create_event(event_type: ReferralEvent::PAGE_LOAD) }
        # 3 share clicks + 1 copy click = 4 shares
        3.times { create_event(event_type: ReferralEvent::SHARE_CLICK) }
        create_event(event_type: ReferralEvent::COPY_CLICK)
        # 2 referred orders ($50 + $30)
        create_reward(referral: referral, order_total_cents: 5000)
        create_reward(referral: referral, order_total_cents: 3000)
      end

      it "computes extension_loads" do
        expect(service.call[:kpis][:extension_loads][:value]).to eq(10)
      end

      it "computes page_visits" do
        expect(service.call[:kpis][:page_visits][:value]).to eq(5)
      end

      it "computes share_rate as shares / extension loads" do
        # 4 shares / 10 loads = 40%
        expect(service.call[:kpis][:share_rate][:value]).to eq(40.0)
      end

      it "computes referred_orders" do
        expect(service.call[:kpis][:referred_orders][:value]).to eq(2)
      end

      it "computes conversion_rate as orders / extension loads" do
        # 2 orders / 10 loads = 20%
        expect(service.call[:kpis][:conversion_rate][:value]).to eq(20.0)
      end

      it "computes referred_revenue in dollars" do
        # 5000 + 3000 = 8000 cents = $80
        expect(service.call[:kpis][:referred_revenue][:value]).to eq(80.0)
      end
    end

    context "with zero data" do
      it "returns zeroes for all KPIs" do
        kpis = service.call[:kpis]
        expect(kpis[:extension_loads][:value]).to eq(0)
        expect(kpis[:page_visits][:value]).to eq(0)
        expect(kpis[:share_rate][:value]).to eq(0)
        expect(kpis[:referred_orders][:value]).to eq(0)
        expect(kpis[:conversion_rate][:value]).to eq(0)
        expect(kpis[:referred_revenue][:value]).to eq(0.0)
      end
    end

    context "with period comparison" do
      let!(:referral) do
        Referral.create!(shop: shop, email: "ref@example.com", first_name: "Jane", referral_code: "Jane001", usage_count: 1)
      end

      subject(:service) do
        described_class.new(shop: shop, period_range: period_range, comparison_range: comparison_range)
      end

      before do
        # Current period: 15 extension loads
        15.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 2.days.ago) }
        # Previous period: 20 extension loads
        20.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 10.days.ago) }
      end

      it "computes percentage change when previous value > 10" do
        change = service.call[:kpis][:extension_loads][:change]
        # 15 vs 20 = -25%
        expect(change[:type]).to eq(:percentage)
        expect(change[:value]).to eq(-25.0)
      end
    end

    context "with small-number comparison" do
      subject(:service) do
        described_class.new(shop: shop, period_range: period_range, comparison_range: comparison_range)
      end

      before do
        # Current: 3 loads, Previous: 2 loads
        3.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 2.days.ago) }
        2.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 10.days.ago) }
      end

      it "shows absolute change when previous value <= 10" do
        change = service.call[:kpis][:extension_loads][:change]
        expect(change[:type]).to eq(:absolute)
        expect(change[:value]).to eq(1)
      end
    end
  end

  describe "funnel" do
    let!(:referral) do
      Referral.create!(shop: shop, email: "ref@example.com", first_name: "Jane", referral_code: "Jane001", usage_count: 1)
    end

    before do
      20.times { create_event(event_type: ReferralEvent::EXTENSION_LOAD) }
      10.times { create_event(event_type: ReferralEvent::PAGE_LOAD) }
      4.times { create_event(event_type: ReferralEvent::SHARE_CLICK) }
      2.times { create_event(event_type: ReferralEvent::COPY_CLICK) }
      create_reward(referral: referral)
    end

    it "returns 4 stages with correct values" do
      funnel = service.call[:funnel]
      stages = funnel[:stages]
      expect(stages.length).to eq(4)
      expect(stages[0][:value]).to eq(20)  # extension loads
      expect(stages[1][:value]).to eq(10)  # page visits
      expect(stages[2][:value]).to eq(6)   # shares + copies
      expect(stages[3][:value]).to eq(1)   # referred orders
    end

    it "computes step-to-step conversion rates" do
      rates = service.call[:funnel][:conversion_rates]
      expect(rates[:load_to_visit]).to eq(50.0)   # 10/20
      expect(rates[:visit_to_share]).to eq(60.0)   # 6/10
      expect(rates[:share_to_order]).to eq(16.7)   # 1/6
      expect(rates[:overall]).to eq(5.0)            # 1/20
    end

    it "handles zero denominators gracefully" do
      # No events at all for a different shop
      other_shop = create(:shop)
      empty_service = described_class.new(shop: other_shop, period_range: period_range)
      rates = empty_service.call[:funnel][:conversion_rates]
      expect(rates[:load_to_visit]).to eq(0)
      expect(rates[:overall]).to eq(0)
    end
  end

  describe "source breakdown" do
    before do
      7.times { create_event(event_type: ReferralEvent::PAGE_LOAD, source: ReferralEvent::CHECKOUT_EXTENSION) }
      3.times { create_event(event_type: ReferralEvent::PAGE_LOAD, source: ReferralEvent::REFERRAL_PAGE) }
    end

    it "shows page visits by source" do
      breakdown = service.call[:source_breakdown]
      ext = breakdown.find { |s| s[:source] == "checkout_extension" }
      direct = breakdown.find { |s| s[:source] == "referral_page" }

      expect(ext[:count]).to eq(7)
      expect(ext[:pct]).to eq(70.0)
      expect(direct[:count]).to eq(3)
      expect(direct[:pct]).to eq(30.0)
    end

    it "returns zero percentages when no page visits" do
      other_shop = create(:shop)
      empty_service = described_class.new(shop: other_shop, period_range: period_range)
      breakdown = empty_service.call[:source_breakdown]
      expect(breakdown.all? { |s| s[:pct] == 0 }).to be true
    end
  end

  describe "top referrers" do
    it "returns referrers ranked by usage_count" do
      top = Referral.create!(shop: shop, email: "top@ex.com", first_name: "Top", referral_code: "Top001", usage_count: 5)
      mid = Referral.create!(shop: shop, email: "mid@ex.com", first_name: "Mid", referral_code: "Mid001", usage_count: 3)
      _zero = Referral.create!(shop: shop, email: "zero@ex.com", first_name: "Zero", referral_code: "Zero001", usage_count: 0)

      create_reward(referral: top, order_total_cents: 10000)
      create_reward(referral: mid, order_total_cents: 5000)

      referrers = service.call[:top_referrers]
      expect(referrers.length).to eq(2)
      expect(referrers[0][:referral_code]).to eq("Top001")
      expect(referrers[0][:usage_count]).to eq(5)
      expect(referrers[0][:revenue]).to eq(100.0)
      expect(referrers[1][:referral_code]).to eq("Mid001")
    end

    it "excludes referrers with zero usage" do
      Referral.create!(shop: shop, email: "zero@ex.com", first_name: "Zero", referral_code: "Zero001", usage_count: 0)
      expect(service.call[:top_referrers]).to be_empty
    end
  end

  describe "sparklines" do
    it "returns daily arrays matching the date series" do
      sparklines = service.call[:sparklines]
      expected_days = (period_range.first.to_date..period_range.last.to_date).count

      expect(sparklines[:extension_loads].length).to eq(expected_days)
      expect(sparklines[:page_visits].length).to eq(expected_days)
      expect(sparklines[:shares].length).to eq(expected_days)
      expect(sparklines[:referred_orders].length).to eq(expected_days)
      expect(sparklines[:referred_revenue].length).to eq(expected_days)
    end

    it "populates correct day with event data" do
      create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 1.hour.ago)
      sparklines = service.call[:sparklines]
      expect(sparklines[:extension_loads].last).to eq(1)
    end
  end

  describe "time series" do
    it "returns dates and metric arrays" do
      ts = service.call[:time_series]
      expect(ts[:dates]).to be_an(Array)
      expect(ts[:extension_loads]).to be_an(Array)
      expect(ts[:referred_revenue]).to be_an(Array)
    end

    it "includes comparison data when comparison_range provided" do
      service_with_comp = described_class.new(
        shop: shop, period_range: period_range, comparison_range: comparison_range
      )
      ts = service_with_comp.call[:time_series]
      expect(ts[:comparison]).to be_present
      expect(ts[:comparison][:dates]).to be_an(Array)
    end

    it "omits comparison when no comparison_range" do
      ts = service.call[:time_series]
      expect(ts).not_to have_key(:comparison)
    end
  end

  describe "data isolation" do
    it "does not include events from other shops" do
      other_shop = create(:shop)
      ReferralEvent.create!(
        shop: other_shop,
        event_type: ReferralEvent::EXTENSION_LOAD,
        source: ReferralEvent::CHECKOUT_EXTENSION,
        created_at: 1.day.ago
      )
      create_event(event_type: ReferralEvent::EXTENSION_LOAD)

      expect(service.call[:kpis][:extension_loads][:value]).to eq(1)
    end

    it "does not include events outside the period" do
      create_event(event_type: ReferralEvent::EXTENSION_LOAD, created_at: 30.days.ago)
      expect(service.call[:kpis][:extension_loads][:value]).to eq(0)
    end
  end
end
