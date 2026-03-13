# PostHog Evaluation — Research Report

## Goal
Evaluate whether PostHog should replace our custom Analytics:: system as the analytics/event tracking backbone for HappyPages — and whether it opens up a service offering for agency clients.

## Verdict: Yes, adopt — but additive first, replace later

PostHog is free at our scale, gives us capabilities we'd never build (session replay, heatmaps, funnels, A/B testing), has solid Rails support, and the migration risk is low. The MCP/AI angle is real but not the main draw — the product itself is.

---

## Cost

| What | Volume | Cost |
|------|--------|------|
| Product analytics | 1M events/month free (we'd use 10-500k) | **$0** |
| Session replay | 5,000 recordings/month free | **$0** |
| Feature flags | 1M requests/month free | **$0** |
| Error tracking | 100K events/month free | **$0** |
| Per-seat fees | None | **$0** |
| **Total at current scale** | | **$0/month** |

At 2M events/month (well beyond current needs): ~$50/month. Hard billing caps available. Startup program offers $50K credits if eligible (<2 years old, <$5M raised).

Self-hosted is deprecated for scale use — cloud is the only real option.

---

## What We Gain vs What We Lose

### Gains

| Capability | Value |
|-----------|-------|
| **Session replay** (5K/month free) | Watch real user sessions — invaluable for debugging storefront widget issues, referral flow drop-offs |
| **Heatmaps** | Click maps, scroll depth, rage click detection |
| **Funnels** | Visual multi-step conversion analysis with auto-correlation |
| **A/B testing** | Native experimentation with statistical significance |
| **Feature flags** (1M req/month free) | Gradual rollout per shop without deploy |
| **Retention/cohort analysis** | Behavioural cohorts, stickiness metrics |
| **Error tracking** (100K/month free) | Rails middleware + ActiveJob auto-capture |
| **GeoIP built-in** | Replaces MaxMind entirely — no license key, no boot-time download |
| **User path analysis** | Visualize actual navigation sequences up to 20 steps |
| **MCP integration** | 27 tools — natural language queries, dashboard creation, feature flag management |
| **Less code to maintain** | Remove: `/s.js`, `/collect`, `EventIngester`, `DashboardQueryService`, MaxMind setup |

### Losses

| What we lose | Severity | Mitigation |
|-------------|----------|------------|
| Full data model control | Low | PostHog's property-based model is more flexible; batch export to Postgres for custom queries |
| Zero external dependencies | Medium | Batch export to own Postgres from day one = safety net. Current system restorable from git. |
| Custom bot/crawler filtering | Low | PostHog has built-in bot detection + filter transformation |
| Custom device detection | None | PostHog's client-side detection is more accurate than server-side DeviceDetector |
| Data locality (our Postgres) | Medium | PostHog Cloud (US or EU). Batch export back to Postgres is free and continuous. |
| Simple SQL queries | Low | HogQL is SQL-like (ClickHouse). Or just query the batch-exported Postgres copy. |
| Tailored `/collect` endpoint | None | PostHog's managed ingestion is better (global CDN, auto-retry, queuing) |

---

## Technical Fit

### Rails Integration
- **`posthog-ruby`** gem (v3.4.0) — official, actively maintained. Batched async capture.
- **`posthog-rails`** gem — Rails-specific. Auto exception tracking, ActiveJob instrumentation, `rails generate posthog:install`.
- Server-side: `PostHog.capture(distinct_id: user.id, event: 'referral_created', properties: { shop_id: Current.shop.id })`

### JavaScript
- Core bundle lazy-loads extensions. Full bundle ~266KB (larger than our `/s.js`).
- "Slim" experimental bundle available for smaller footprint.
- Ad-blocker resistance: reverse proxy through own subdomain (e.g. `e.happypages.co`) — increases capture by 10-30%.

### API for Custom Dashboards
- HogQL query API: `POST /api/projects/:project_id/query`
- **Rate limit: 120 HogQL queries/hour** — fine for admin dashboards (handful of users), NOT suitable for high-frequency customer-facing polling
- For client-facing dashboards: batch export to Postgres, query locally (which is what we'd do anyway)

### Data Model Mapping

| HappyPages | PostHog |
|-----------|---------|
| `visitor_id` | `distinct_id` |
| `event_name` | `event` |
| `pathname` | `$current_url` (auto) |
| `referrer` | `$referrer` (auto) |
| `utm_*` | `utm_*` (auto) |
| `browser`, `os`, `device_type` | Auto-detected client-side |
| `country_code`, `region`, `city` | GeoIP auto-enriched |
| `properties` (JSONB) | Event properties (native) |

### Shopify-Specific
- JS snippet in theme `<head>` for storefront pages
- Custom web pixel for checkout/post-purchase events (sandboxed iframe — no cookies)
- **Identity stitching gap**: checkout pixel can't access PostHog cookie. Need server-side `posthog.identify()` via `orders/create` webhook to link anonymous browser → known customer.
- **PixieHog** (Shopify app) automates the pixel setup.

---

## MCP & AI Integration — Honest Assessment

**Reality: 60% substance, 40% marketing polish.**

### What's real
- Official MCP server with 27 tools, actively maintained
- Claude plugin: `claude plugin install posthog`
- Natural language → HogQL queries work well
- Can create dashboards, manage feature flags, query errors programmatically
- The "auto-instrumentation" is really Claude writing tracking code using PostHog docs as context — not magic, but useful (~70-80% quality, needs curation)

### What's not the main draw
- The MCP alone doesn't beat "Claude + our own Postgres tables"
- The value is PostHog-the-product (session replay, funnels, etc.) with the MCP as a workflow bonus
- Event "rename" is actually Actions (grouping old + new names) — better than GA, but not true rename

### Verdict on MCP
Nice-to-have, not the reason to adopt. The reason to adopt is the product capabilities we'd never build ourselves.

---

## Migration Plan

### Timeline: 7-9 weeks (1-2 person team)

| Phase | Duration | What |
|-------|----------|------|
| POC/Spike | 1 week | Add PostHog JS to happypages.co static site. Verify events flow. |
| Dual-track | 2-3 weeks | Both systems running on Shopify storefronts. Compare numbers. |
| Historical import | 1 week | Export `analytics_events` → JSONL → PostHog batch API |
| Dashboard rebuild | 1-2 weeks | Recreate `DashboardQueryService` metrics as PostHog insights |
| Server-side integration | 1 week | `posthog-ruby` for key backend events |
| Decommission | 1 week | Remove custom analytics code |

### What stays in Postgres
- **`ReferralEvent`** — core business logic, encrypted emails, shop-scoped. Does not move.
- **`Referral`, `Shop`**, all referral business models — unchanged.
- Optionally `Analytics::Payment` (or migrate as revenue events).

### Risk assessment

| Risk | Level | Notes |
|------|-------|-------|
| Data loss | Low | Dual-track means both capture simultaneously |
| Dashboard parity | Medium | Revenue attribution first-touch CTE needs manual recreation in HogQL |
| Checkout tracking | Medium | Sandboxed pixel + identity stitching requires explicit work |
| Cost surprise | Low | Hard billing caps; free tier covers us for a long time |
| Vendor lock-in | Medium | Mitigated by batch export to Postgres from day one |
| Reliability | Medium | ~12 incidents/month (mostly minor, ~1hr each). Fine for analytics, less ideal for feature flags in critical paths |

---

## Agency Angle

**No formal reseller/agency program exists.** But the economics work:

### Structure
One PostHog org, separate project per agency client. Each project gets its own API key (maps to our current `site_token` concept).

### Per-client cost

| Client scale | PostHog cost | What you could charge |
|-------------|-------------|----------------------|
| 100K-500K events/month | $0 (free tier) | $50-150/month for "analytics & insights" |
| 500K-1M events/month | $0-25/month | $100-200/month |

Most clients stay free. You charge a margin for setup, dashboards, and interpretation. PostHog is just the data backend — clients see your UI.

---

## Open Questions (Resolved)

| Question | Answer |
|----------|--------|
| Keep `ReferralEvent` or move? | **Keep in Postgres** — it's business logic, not analytics |
| Customer journey views for merchants? | Not immediately — focus on internal product analytics first |
| Multi-tenant structure? | One org, one project per client. Separate project for HappyPages platform. |

## Recommended Next Step

**1-week spike**: Add PostHog JS to the happypages.co static site (zero risk, instant session replay). Install `posthog-ruby` gem in the Rails app but don't instrument yet — just validate the setup. Install the Claude MCP plugin and kick the tyres. Then decide whether to proceed with full migration.
