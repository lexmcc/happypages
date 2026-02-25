# Project History

A chronicle of the referral app's evolution from initial commit to production-ready multi-tenant platform.

## Timeline

### Week 1: Foundation (Jan 8-13, 2026)

- **Jan 8** - Checkout extension on thank you page with personalized customer names
- **Jan 9** - Rails backend with PostgreSQL database
- **Jan 13** - Referral code generation and webhook-triggered rewards
- **Jan 13** - Admin UI for extension and discount configuration

### Week 2: Polish & UI Overhaul (Jan 14-21, 2026)

- **Jan 14** - Neumorphic design system with live preview and undo support
- **Jan 14** - Analytics dashboard with event tracking
- **Jan 21** - Shared discount architecture with generations and scheduled boosts
- **Jan 21** - Configurable referral page with admin UI

### Week 3: Integrations (Jan 22-23, 2026)

- **Jan 22** - Awtomic subscription integration with auto-applied rewards
- **Jan 23** - Klaviyo integration for referral lifecycle events
- **Jan 23** - Duplicate reward prevention and expiration handling
- **Jan 23** - Reward status display on customer referral page

### Week 4: Scale & Production (Jan 26+, 2026)

- **Jan 26** - Multi-tenant architecture with encrypted credentials and provider pattern
- **Jan 26** - Self-service onboarding via Shopify OAuth
- **Jan 29** - Railway deployment: Rails + PostgreSQL at app.happypages.co
- **Jan 29** - White-labeled referral URLs with auto-generated shop slugs

### Week 5: PII Compliance & App Distribution (Feb 6, 2026)

- **Feb 6** - PII compliance: encryption, audit logging, privacy policy
- **Feb 6** - Compliance webhooks with HMAC verification
- **Feb 6** - Public distribution Shopify app for multi-merchant installs
- **Feb 6** - Data protection questionnaire submitted

### Week 6: Oatcult Shop Page Polish + Integrations (Feb 10-11, 2026)

- **Feb 10** - Mobile sticky basket fixes: full-width slots, progress bar + badge always visible, scroll no longer closes drawer
- **Feb 11** - Awtomic API key connect/disconnect flow on integrations page

### Week 7: Security Hardening + Embedded Auth + Hydrogen Readiness (Feb 12-13, 2026)

- **Feb 12** - Fixed webhook HMAC validation to reject invalid signatures (Shopify app check compliance)
- **Feb 12** - App Bridge + session token auth on embedded page for Shopify automated checks
- **Feb 12** - Security audit: hardened JWT verification (required claims, iss↔dest validation, domain checks)
- **Feb 13** - Hydrogen readiness: storefront URL setting, API base controller, rate limiting, GET referral endpoint
- **Feb 13** - Media upload & image management: admin media library, inline media pickers on editors, Railway Bucket (Tigris) storage with automatic WebP variant generation
- **Feb 13** - Super admin dashboard: `/superadmin` with shop list, detail tabs, suspend/reactivate, audit logging, env-var BCrypt auth
- **Feb 13** - Tabbed theme integration UI with Hydrogen discount route snippet for headless stores

### Week 8: AI Imagery Pipeline + Tooling (Feb 14-16, 2026)

- **Feb 14** - Brand scraper + AI imagery generator: automatic brand analysis on install, Gemini-powered marketing image generation for three surfaces
- **Feb 14** - SolidQueue for background jobs, superadmin prompt template & scene asset management
- **Feb 16** - Surface-filtered media pickers: each admin tab shows only relevant images (referral banner / extension card)
- **Feb 16** - 3-layer CLAUDE.md architecture: global rules, project context, session memory separated
- **Feb 17** - Oatcult shop page v3: hero gallery jiggle fix, flavor card styling overhaul, size card viewport fix, mobile sticky CTA subscription savings pill
- **Feb 17** - Shopify theme architecture playbook: 5-framework evaluation → vanilla CE + Preact islands decision
- **Feb 18** - Header checkout button: disabled until items added on shop-v3, `spf:has-items` event bridge

### Week 9: Web Analytics + Customer Import + Overview Page (Feb 19-20, 2026)

- **Feb 19** - Bulk customer import: background job fetches Shopify customers via GraphQL, creates Referral records + metafields. Admin UI with live progress polling.
- **Feb 19** - Oatcult cart sync: background syncing with debounce + AbortController for abandoned cart recovery, session storage for back-button restoration
- **Feb 19** - Interactive overview page (`/overview`) for Field Doctor meeting prep: architecture diagram, feature map, Hydrogen guide, testing plans
- **Feb 19** - Renamed `analytics_events` → `referral_events` (table + model + 11 file find-replace) to free namespace for web analytics
- **Feb 20** - Built analytics schema: `analytics_sites` (per-shop site tokens), `analytics_events` (immutable event log with visitor/session/UTM/GeoIP/device), `analytics_payments` (revenue attribution)
- **Feb 20** - Tracking script (`hp-analytics.js`): cookie-based visitor/session, sendBeacon ingestion, SPA history monkey-patching, declarative goals, Shopify cart attribute injection
- **Feb 20** - Ingestion endpoint (`POST /collect`): EventIngester service with bot filtering, UA parsing, GeoIP, hostname validation
- **Feb 20** - Analytics dashboard UI (Chunk 3): KPIs with sparklines, time series chart, top pages/referrers/UTMs, geography, devices, goals, revenue attribution. Admin + superadmin.
- **Feb 20** - Auto-create analytics site on first visit with setup page showing personalised tracking snippet

### Week 10: Platform Architecture Refactor (Feb 20, 2026)

- **Feb 20** - Platform architecture: 5-chunk refactor building ShopFeature/ShopIntegration models, email auth, collapsible sidebar, superadmin shop management, and impersonation — all TDD with 118 passing specs
- **Feb 20** - Superadmin impersonation: "View as shop owner" with 4-hour timeout, fixed banner, audit trail
- **Feb 20** - Collapsible sidebar with feature gating: locked features show lock icon + preview link, desktop collapse to icon-only mode

### Week 11: Specs Engine (Feb 24, 2026)

- **Feb 24** - Specs engine chunk 1: AI-powered specification interviews with Anthropic API, web chat UI, and 95 new specs
- **Feb 24** - AnthropicClient service, prompt builder with 8-section system prompt, orchestrator with atomic transactions and parallel tool_use handling
- **Feb 24** - Specs engine chunk 2: tabbed output view (Chat/Brief/Spec), markdown export, session versioning with context seeding, `analyze_image` tool for screenshot design tokens, 224 total specs
- **Feb 24** - Specs engine chunk 3: handoff + multi-user — `request_handoff` tool, internal/external invite flow, guest access with token-based join, message attribution, PromptBuilder active user context, 288 total specs
- **Feb 25** - Specs engine chunk 4: client web portal + auth — Organisation model, Specs::Client with Authenticatable concern, client portal (login, invite, dashboard, projects, chat, brief export), v1_client tool definitions (no handoff), orchestrator specs_client/tools kwargs, superadmin org/client management with SpecsClientMailer, 335 total specs
- **Feb 25** - Specs engine chunk 5: kanban board — Specs::Card model with status lanes, auto-populate from generate_team_spec, SortableJS drag-and-drop for admin, read-only client view, Board tab on project pages, 354 total specs

## Key Milestones

1. **First checkout extension working** - Jan 8: "It Works" thank you page displayed
2. **First referral code generated** - Jan 13: Automatic code creation from customer data
3. **First webhook processed** - Jan 13: Order webhook triggers referrer rewards
4. **Admin UI live preview** - Jan 14: Real-time preview with undo functionality
5. **Neumorphic design system** - Jan 14: Coral accents, shadows, modern aesthetic
6. **First Awtomic reward applied** - Jan 22: Subscription discount auto-applied
7. **First Klaviyo event tracked** - Jan 23: Referral lifecycle events flowing
8. **Multi-tenant architecture complete** - Jan 26: Platform-agnostic, encrypted credentials
9. **Self-service OAuth onboarding** - Jan 26: Merchants can install independently
10. **Production deployment** - Jan 29: Rails app live at app.happypages.co with PostgreSQL
11. **PII compliance complete** - Feb 6: Encryption, audit logs, compliance webhooks, privacy policy
12. **Public distribution app** - Feb 6: Recreated app for multi-merchant installs

## Architecture Evolution

```
Week 1: Monolith
├── Single shop, hardcoded credentials
├── Direct Shopify API calls
└── Basic webhook handling

Week 2-3: Feature-Rich Monolith
├── Admin UI with live preview
├── Awtomic + Klaviyo integrations
└── Sophisticated reward lifecycle

Week 4: Multi-Tenant Platform
├── Shop model with encrypted credentials
├── Provider pattern (Shopify/Custom/WooCommerce)
├── OAuth-based self-service onboarding
└── Thread-isolated shop context
```
