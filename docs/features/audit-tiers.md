# Website Audit — Tier Packaging & Positioning

## Context

Prospective client: D2C meal kit brand, Shopify, £1-5M revenue. Already using Platter (quiz), Octane AI (personalisation), Recharge/Skio (subscriptions). Wants 6-month engagement: month 1 audit, months 2-6 execution across three workstreams (site audit & roadmap, landing pages, quiz + Octane enhancements).

This document defines what the audit deliverable looks like across HappyPages' two subscription tiers, plus bolt-on audit products.

---

## Growth Partner Audit — "Strategic CRO Audit"

**Tier:** £2,995/m | **Audit = month 1 of retainer**

### What It Is

A full strategic CRO audit across 8 areas with data analysis, competitor benchmarking, and a prioritised 6-month roadmap. This is the premium offering — it justifies the 3x price gap over Build Retainer by demonstrating the strategic layer from day one.

### Scope (8 Areas)

| # | Area | What's Reviewed |
|---|------|-----------------|
| 1 | **Quiz Funnel** | Entry points, flow structure, question-to-recommendation logic, results page design, quiz-to-cart handoff, downstream data usage (Klaviyo segments, personalised recovery emails) |
| 2 | **Subscription Flow** | Subscribe vs one-time framing, frequency options, commitment anxiety signals, Recharge/Skio portal (skip/swap/cancel UX), dunning flow, churn prevention touchpoints |
| 3 | **Homepage & Navigation** | First-screen value prop clarity, CTA hierarchy, quiz discovery, trust signals, nav architecture, mobile-first review |
| 4 | **Product Discovery & PDPs** | Collection layout, filtering/sort, PDP structure, subscription toggle clarity, cross-sell/upsell logic, stock handling |
| 5 | **Checkout & Post-Purchase** | Cart friction, payment options, delivery expectation setting, order confirmation page, first 7-day email sequence, packaging/unboxing |
| 6 | **Personalisation Logic** | Octane AI on-site rules, returning visitor experience, recommendation engine depth, email personalisation beyond {first_name} |
| 7 | **Technical Performance** | PageSpeed (mobile + desktop, 5 key URLs), Core Web Vitals with specific culprits, third-party script audit, Shopify app bloat check |
| 8 | **Competitor Benchmarking** | 3-4 direct competitors benchmarked across quiz, subscription, homepage, mobile, personalisation — with side-by-side teardowns and "what to steal" |

### Methodology

**Week 1 — Data Collection & Heuristic Review**
- Request: GA4 (read-only), Shopify analytics, Octane AI dashboard, Recharge/Skio admin, Klaviyo, Hotjar (or install free plan)
- Pull 90 days of key metrics: traffic, CVR, quiz completion rate, subscription attach rate, churn rate, AOV
- Full heuristic walkthrough (mobile + desktop) of entire customer journey with recorded Loom commentary
- Nielsen's 10 usability heuristics applied at each stage

**Week 2 — Deep Analysis & Competitor Benchmarking**
- GA4 funnel visualisation: homepage → quiz → results → cart → checkout → purchase (identify biggest drops)
- 20-30 session recording reviews (10 mobile, 10 desktop, 5-10 quiz completers who didn't purchase)
- Competitor teardown: complete quiz + subscribe flow for 3-4 competitors with annotated screenshots
- Personalisation gap analysis: data collected vs data actually used

**Week 3 — Synthesis & Prioritisation**
- Group findings by area, score each using ICE framework
- Build prioritised 6-month roadmap
- Draft audit document

**Week 4 — Delivery & Alignment**
- Deliver document + video walkthrough
- Roadmap review session to agree month 2 priorities
- Set up execution board with top opportunities queued as cards

**Time investment:** ~40-50 hours across the month

### Deliverable Package

**Part A: Strategic Audit Document (25-40 pages)**
- Executive summary: top 5 findings with estimated revenue impact
- Per-area deep dives with annotated screenshots, data evidence, numbered findings, specific recommendations, impact ratings
- Competitor benchmarking section with side-by-side comparisons
- Personalisation strategy: specific Octane rules and Klaviyo segments to implement
- Technical audit summary with PageSpeed scores and fix list

**Part B: Video Walkthrough (30-45 min)**
- Recorded Loom walking through key findings with screen shares of actual site, annotations, competitor comparisons
- This is what the team will actually watch — the document is the reference

**Part C: Prioritised Roadmap Board**
- Every finding becomes a board card with: description, evidence, expected impact, estimated effort, dependencies
- Cards sorted into: Month 2 / Month 3 / Month 4 / Month 5 / Month 6 / Backlog
- Colour-coded by workstream
- This board becomes the live execution queue

### Prioritisation: Modified ICE Scoring

| Factor | 1-5 Scale | CRO Meaning |
|--------|-----------|-------------|
| **Impact** | Revenue/conversion lift potential | 5 = directly fixes a known dropout with data evidence |
| **Confidence** | How sure are we? | 5 = data shows the problem + proven solution exists |
| **Ease** | Implementation within Shopify/Platter/Octane | 5 = config change or simple Liquid edit |

Score = (I × C × E) / 3 — top scorers go into months 2-3.

### Transition to Execution

The audit doesn't "end" — it becomes the backlog:
- Week 4: roadmap review session, client confirms or re-prioritises month 2 items
- Month 2: top 4-6 items scoped into deliverables with acceptance criteria
- Weekly async updates begin (Friday Loom or written update)
- Quarterly roadmap session: re-score remaining backlog based on shipped results
- After each change, compare before/after metrics — this is what "strategic input" means

---

## Build Retainer Audit — "Conversion Sprint Audit"

**Tier:** £1,095/m | **Audit = 2 of 2-3 monthly deliverables**

### What It Is

A focused, practical audit by a senior practitioner who walks the site as a customer would, identifies friction and missed opportunities, then turns findings directly into an execution queue. No strategy layer — just expert pattern-matching that feeds building.

### Philosophy

Answers one question: **"What should we build first, and why?"**

Build Retainer clients are operators, not strategists. They know their brand and their customer. They don't need someone to tell them "subscription is important" — they need someone to look at their subscription flow and say "this toggle is confusing, here's the fix, I'll build it next month."

### Scope (5 Key Flows)

| # | Flow | What's Reviewed |
|---|------|-----------------|
| 1 | **Homepage → Quiz Entry** | Hero clarity, quiz discovery/prominence, trust signals, mobile-first review |
| 2 | **Quiz Journey (Platter)** | Completion flow, question logic, results page, Octane integration, recommendation clarity |
| 3 | **PDP → Cart → Checkout** | Subscription toggle clarity, pricing presentation, subscribe & save messaging, cart upsells, checkout friction |
| 4 | **Subscription Landing** | Dedicated sub page (or flag its absence), plan comparison, flexibility messaging |
| 5 | **Post-Purchase / Account Portal** | Customer portal experience, subscription management UX, retention touchpoints |

### Methodology

**Direct observation (primary method):**
- Full site walkthrough as new visitor (homepage → checkout), desktop + mobile
- Full walkthrough as returning/logged-in subscriber
- Mobile on actual device (not just responsive resize)
- 1-2 competitor quick-references (not a full analysis — just "is this normal?" sanity checks)

**Publicly available data:**
- PageSpeed Insights: 3-4 key URLs
- Shopify theme check: is it Online Store 2.0?
- SEO quick scan: meta titles/descriptions, schema markup

**Client-provided (requested via board):**
- View-only GA4 access (enhances but not required)
- Shopify admin viewer access
- Test account for subscription portal

**What's NOT required:**
- No stakeholder interviews or strategy calls
- No heatmap/session recording analysis
- No GA4 funnel deep-dive
- No customer research

**Time investment:** 7.5-10.5 hours

| Activity | Hours |
|----------|-------|
| Site walkthrough (desktop + mobile, 5 flows) | 3-4h |
| Screenshots + annotation | 1-2h |
| PageSpeed / technical checks | 0.5h |
| Competitor quick-look (1-2 sites) | 1h |
| Write-up + prioritisation | 2-3h |

### Deliverable

**Part A: Sprint Audit Document (6-8 pages)**

1. **Snapshot Summary** (half page) — 3-5 headline findings, traffic-light per flow (green/amber/red)
2. **Flow-by-Flow Findings** (1-1.5 pages each) — annotated screenshots, "what we observed → why it matters → what to build", severity tags (Quick Win / Medium / Larger Build)
3. **Technical Quick Check** (half page) — PageSpeed scores, theme/app observations, red flags

**Part B: Prioritised Execution Queue (Board Cards)**

Every finding becomes a board card:
- Clear title (e.g., "Redesign subscription toggle on PDP for clarity")
- 1-2 sentence brief
- Priority: P1 (Month 2) / P2 (Month 3) / P3 (Month 4+)
- Effort: S / M / L
- Category: Landing Page / Quiz / Subscription / Technical

P1 items = 2-3 deliverables, matching month 2 capacity.

### Prioritisation Hierarchy (Meal Kit Specific)

| Priority | Area | Rationale |
|----------|------|-----------|
| **Tier 1: Revenue-Direct** | Subscription conversion friction, quiz-to-subscription handoff, cart/checkout abandonment | Highest revenue impact, build first |
| **Tier 2: Acquisition Efficiency** | Homepage-to-quiz path, landing page gaps, mobile UX friction | Feeds workstream 2 (landing pages) |
| **Tier 3: Retention & LTV** | Subscription portal, post-purchase upsells, Octane personalisation | Build later, compounds over time |
| **Tier 4: Technical Foundation** | Page speed, theme/app stack | Ongoing alongside other work |

### Transition to Execution

The audit document IS the execution brief:
- Last week of month 1: audit doc posted, queue cards created, async note highlighting P1 items
- Month 2: start building P1 immediately, no review meeting needed
- Monthly rhythm: pick 2-3 cards, complete them, post for review, add new cards if builds reveal new issues
- Queue is a living document, not a fixed plan

---

## Tier Comparison — Side by Side

| Dimension | Build Retainer (£1,095/m) | Growth Partner (£2,995/m) |
|-----------|--------------------------|---------------------------|
| **Audit name** | Conversion Sprint Audit | Strategic CRO Audit |
| **Scope** | 5 key flows | 8 interconnected areas |
| **Depth** | Heuristic walkthrough + expert observation | Heuristic + data analysis + session recordings |
| **Data analysis** | PageSpeed + quick-look (GA4 optional) | Full GA4 funnel analysis, Octane analytics, churn data |
| **Competitor research** | 1-2 quick references | 3-4 full teardowns with side-by-side comparisons |
| **Personalisation strategy** | Not included | Specific Octane rules + Klaviyo segments mapped |
| **Session recordings** | Not included | 20-30 recordings reviewed |
| **Deliverable** | 6-8 page doc + board cards | 25-40 page doc + 30-45 min video + board cards |
| **Prioritisation** | Impact hierarchy (practical) | ICE-scored with data evidence |
| **Delivery session** | Async (board note) | Recorded walkthrough + roadmap review session |
| **Time investment** | ~8-10 hours | ~40-50 hours |
| **Ongoing strategy** | None — client decides priorities | Weekly updates, quarterly roadmap re-prioritisation |
| **Measurement** | "Did we ship it?" | "Did it move the metric?" |

**The clear value gap:** Build identifies and fixes problems. Growth identifies, quantifies, fixes, measures, and re-prioritises. The audit is the most visible expression of that difference.

---

## The Gap Between the Two

The tier boundary is clean and easy to explain:

**Build Retainer = expert eye.** A senior practitioner spots what's broken and builds the fixes. No data analysis, no competitor research, no strategy layer. The value is speed and accuracy of pattern recognition.

**Growth Partner = expert eye + data + strategy.** Same practitioner, but now with GA4 funnel data, session recordings, competitor teardowns, personalisation strategy, and an ongoing measurement loop. The value is knowing not just *what* to fix, but *why* it matters, *how much* it's costing, and *whether the fix worked*.

| What you get | Build (£1,095/m) | Growth (£2,995/m) |
|---|---|---|
| Expert walks your site and finds problems | Yes | Yes |
| Annotated findings with "build this" tasks | Yes | Yes |
| Prioritised execution queue | Yes | Yes |
| GA4 funnel analysis with dropout data | No | Yes |
| Session recording review (20-30 sessions) | No | Yes |
| Competitor teardowns (3-4 brands) | No | Yes |
| Octane/Klaviyo personalisation strategy | No | Yes |
| ICE-scored roadmap with data evidence | No | Yes |
| Video walkthrough of findings | No | Yes (30-45 min) |
| Weekly async updates | No | Yes |
| Quarterly roadmap re-prioritisation | No | Yes |
| Before/after measurement on shipped changes | No | Yes |

**One line version:** Build tells you what to fix. Growth tells you what to fix, proves why, and measures the result.

---

## Recommendation: How to Present This to the Client

### For THIS specific client (meal kit, £1-5M, 6-month engagement):

**Lead with Growth Partner.** This client has explicitly asked for audit + execution + quiz + personalisation work. That's a strategic engagement. The three workstreams they've described (audit & roadmap, landing pages, quiz + Octane) map perfectly to the Growth Partner audit structure. They've essentially described what Growth Partner delivers.

**Frame the Build Retainer as the alternative, not the fallback.** If they baulk at £2,995/m, Build Retainer gives them a focused month 1 audit with execution in months 2-6. Position it as: "You'd get a narrower audit covering 5 key flows instead of 8 full areas, and we'd skip the data analysis and competitor research — but you'd still get an experienced practitioner identifying the biggest friction points and building the fixes month by month."

**Keep it simple.** Two tiers, clear gap, no add-ons. The client picks the level of depth and strategic input they want.

### What to commit to at each level:

**Growth Partner (£2,995/m):**
- Month 1: Full 8-area Strategic CRO Audit with data analysis, competitor benchmarking, video walkthrough, and prioritised 6-month roadmap
- Months 2-6: 4-6 deliverables/month executing the roadmap, weekly async updates, quarterly re-prioritisation
- Measurement: before/after on every shipped change

**Build Retainer (£1,095/m):**
- Month 1: Focused 5-flow Conversion Sprint Audit with annotated findings and prioritised build queue
- Months 2-6: 2-3 deliverables/month working through the queue, board-only comms
- No ongoing strategy, measurement, or re-prioritisation

Both are honest, deliverable commitments. Neither overpromises.
