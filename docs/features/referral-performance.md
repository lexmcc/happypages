# Referral Performance

## Goal

Give merchants a dedicated, zero-setup referral performance page with funnel visualisation, KPI cards with period comparison, and time series charts — so they can see how their referral program is performing without installing any tracking script.

## Approach

Add a new "Performance" page under the Referrals section in the admin sidebar. This page pulls from existing data sources (ReferralEvent + Referral model) plus a small migration to persist order revenue. The existing Analytics feature (web analytics) gets hidden from the sidebar for now and will be built out as a separate, deeper feature later.

### The referral journey

The funnel reflects the actual user journey:

1. **Extension Load** — customer sees the thank-you page widget after purchase
2. **Referral Page Visit** — customer clicks through to `/:slug/refer` (from extension, customer account link, or email)
3. **Share / Copy** — customer shares their code (social share or code copy)
4. **Referred Order** — a friend uses the code and places an order

The extension is the primary entry point driving traffic to the referral page. The referral page can also be reached directly (customer account link, future email campaigns). A source breakdown shows how customers arrive at the referral page.

### Data sources

- **Top/mid funnel**: `ReferralEvent` — extension loads (`EXTENSION_LOAD`), page visits (`PAGE_LOAD`), share clicks (`SHARE_CLICK`), code copies (`COPY_CLICK`). Already tracked with `source` column (checkout_extension vs referral_page).
- **Bottom of funnel**: `Referral` model — referred orders via `usage_count`. `ReferralReward` for order revenue (requires new `order_total_cents` column — see chunk 0).

### Key UX decisions

- **KPI cards** show real-time counts + period-over-period comparison percentage. Computed rates (share rate, conversion rate) promoted to headline KPIs.
- **Funnel visualisation** — 4 horizontal stages with raw counts AND step-to-step conversion rates annotated between stages. Overall conversion rate (extension loads → referred orders) shown at the bottom.
- **Source breakdown** — shows how customers reach the referral page (from extension vs direct). Extensible for future channels (email).
- **Time series chart** — click a KPI card to switch the chart to that metric's trend. Single metric at a time with previous-period comparison as a dashed overlay line. Reuses existing `analytics_chart_controller.js`.
- **Period selector**: Today / 7d / 30d / 90d / Custom (native HTML date inputs for custom range).
- **Period comparison**: current period vs previous equivalent. Show percentage when base > 10, absolute change when base <= 10 (avoids wild swings like "0 → 1 = +inf%").
- **Top referrers table** — ranked list of top referral codes by usage. Reuses existing `_referral_performance.html.erb` pattern.
- **Empty state** — new merchants with zero data see a sketch of what the dashboard will look like, plus a setup checklist (create campaign, install extension, wait for first share).
- **Dashboard keeps** its light "Today's Activity" counters as a quick glance — Performance is the deep-dive.
- **Existing Analytics page** hidden from sidebar (still accessible by URL for merchants who already use it).
- **Org clients** can use the web analytics system when the Analytics feature is built out later — not part of this work.

### KPI cards (6)

1. **Extension Loads** — total reach (top of funnel)
2. **Share Rate %** — share clicks / extension loads (advocacy efficiency, healthy range 5-15%)
3. **Page Visits** — referral page visits (customer engagement)
4. **Referred Orders** — orders placed using a referral code (conversion)
5. **Conversion Rate %** — referred orders / extension loads (overall program efficiency)
6. **Referred Revenue $** — total revenue from referred orders (bottom line)

Each card: big number, sparkline, period comparison badge (% or absolute), clickable to switch chart.

### Funnel stages (4)

```
Extension Loads ──(X% clicked through)──> Page Visits ──(Y% took action)──> Shares + Copies ──(Z% converted)──> Referred Orders
```

Between each stage: conversion rate annotation. Below funnel: source breakdown (how customers reached the referral page).

## Chunks

0. [ ] **Revenue migration** — Add `order_total_cents` (integer) column to `referral_rewards`. Persist `total_price` from the Shopify webhook payload in the order handler. This is a blocker — without it, referred revenue (the #1 merchant metric) can't be shown.

1. [ ] **Performance query service** — `Referrals::PerformanceQueryService` that computes all metrics from ReferralEvent + Referral + ReferralReward. Accepts `shop:` and period params (today/7d/30d/90d/custom). Returns structured hash with: KPI values + comparison percentages, funnel stage counts + step-to-step conversion rates, daily time series per metric, source breakdown (extension vs direct), top referrers (top 10 by usage count). Handles empty data gracefully.

2. [ ] **Performance controller + route** — `Admin::PerformanceController#index` at `/admin/performance`. Period filtering via query params. Loads `@data` from query service. Add "Performance" to sidebar nav under Referrals section.

3. [ ] **Performance page UI** — KPI cards row (6 cards with sparklines + comparison badges). Time series chart (click KPI to switch, comparison overlay). Funnel visualisation (4 horizontal bars with conversion rates). Source breakdown (extension vs direct). Top referrers table. Empty state for new merchants. Period selector (today/7d/30d/90d/custom with native date inputs). Mobile: 2-column KPI grid, vertical funnel stack. [UI: Run `/frontend-spec` for detailed visual spec]

4. [ ] **Hide Analytics from sidebar** — Remove the Analytics nav item from sidebar feature groups. Keep routes and controller intact (accessible by URL). No data migration or deletion.

5. [ ] **Tests** — Request specs for performance controller (period filtering, empty data, data structure). Service specs for query service (funnel calculations, conversion rates, period comparisons, source breakdown, edge cases with zero data, small-number comparison handling).

## First Step

Chunk 0: the revenue migration. It's a 10-minute change but it's a blocker for the most important metric on the page.

## Open Questions

- Should the source breakdown be a simple two-row table, or a visual element (e.g., stacked bar or mini donut)?
- Top referrers table: should it show revenue per referrer (requires the revenue migration), or just usage count for V1?

## Technical Notes

- `ReferralEvent` has `event_type` constants: `EXTENSION_LOAD`, `SHARE_CLICK`, `PAGE_LOAD`, `COPY_CLICK` with `source` column (`checkout_extension` / `referral_page`). Group by `DATE(created_at)` for time series.
- `Referral` has `usage_count`. `ReferralReward` has `shopify_order_id` and will have `order_total_cents` after migration. Group by `DATE(created_at)` on ReferralReward for bottom-of-funnel time series.
- Period comparison: today vs yesterday, 7d vs previous 7d, 30d vs previous 30d, 90d vs previous 90d, custom vs equal-length period immediately before.
- Small-number comparison: when previous period value <= 10, show absolute change ("+3") instead of percentage ("+300%") to avoid misleading spikes.
- Reuse `analytics_sparkline_controller.js` and `analytics_chart_controller.js` Stimulus controllers — they already handle clickable KPI → chart switching and comparison overlay.
- Reuse `_control_bar.html.erb` pattern for period selector (add 90d button, add custom date inputs that appear on selection).
- Sidebar feature groups in `sidebar_helper.rb` — add "Performance" as a nav item under the referrals feature group. Remove Analytics from groups (keep routes).
- Source breakdown: group `ReferralEvent.where(event_type: PAGE_LOAD)` by `source` column.
- Top referrers: `Referral.where(shop_id: ...).where("usage_count > 0").order(usage_count: :desc).limit(10)`.
- Empty state: check if shop has any ReferralEvents. If zero, render empty state with setup checklist instead of dashboard.

## Future (V2+)

- Top referrers leaderboard with revenue per referrer
- Reward status breakdown (created/applied/expired donut chart)
- Time-to-convert distribution (days between share and order)
- Referred vs non-referred AOV comparison
- Cross-shop benchmarks ("your share rate is above the 5% median")
- CSV/data export
- Email as a referral page entry channel
- A/B testing for referral offers
