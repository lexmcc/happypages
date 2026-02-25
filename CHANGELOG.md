# Changelog

Dated record of shipped features across both products.

## 2026-02-25

- **Specs engine audit fixes** — DB-level XOR CHECK constraint on projects (shop-or-org), 7-day invite token expiry on client invites, password minimum length validation via Authenticatable concern, resilient card creation (skips blank titles), nil-shop guard on guest controller, composite index for org-scoped queries. Superadmin org/client management specs, mailer spec, client message endpoint specs, session timeout spec. 377 total specs, all passing.
- **Specs engine (Chunk 5)** — Kanban board. `Specs::Card` model with Backlog → In Progress → Review → Done statuses. Auto-populated from `generate_team_spec` output (one card per chunk, idempotent guard). Admin gets drag-and-drop via SortableJS + manual card creation. Clients get read-only board view. Board tab on project show page (admin: 4th tab, client: 3rd tab). JSON API for board CRUD. 354 specs total, all passing.
- **Specs engine (Chunk 4)** — Client web portal + auth. `Organisation` model for non-Shopify clients, `Specs::Client` with BCrypt auth (shared `Authenticatable` concern), client login/logout/invite acceptance, dashboard with project list, project creation and chat (v1_client tools — no handoff), client brief view and export (team spec hidden). Orchestrator updated with `specs_client:` and `tools:` kwargs. `sender_name` priority chain: user → specs_client → handoff → "Guest". Superadmin organisation management with client invite flow via `SpecsClientMailer`. Rate-limited client login (5/min) and message (1 req/3s). 335 specs total, all passing.

## 2026-02-24

- **Specs engine (Chunk 3)** — Handoff + multi-user support. AI can suggest session handoffs via `request_handoff` tool (with reason, summary, suggested questions). Admin can hand off internally to another shop user or create an external client invite link (token-based, 7-day expiry). Guest access at `/specs/join/:token` with minimal layout, name entry, and full chat interface. Message attribution shows sender names when multiple participants exist. PromptBuilder adapts to active user context and includes handoff history. Guest routes rate-limited. 288 specs total, all passing.
- **Specs engine (Chunk 2)** — Dual output view with tabbed interface (Chat / Client Brief / Team Spec) on completed sessions, markdown export for both outputs, session versioning with context seeding, version dropdown navigation, `analyze_image` tool for extracting design tokens from uploaded screenshots (colors, typography, layout, spacing, effects), design tokens partial with color swatches and typography table. 224 specs total, all passing.
- **Specs engine (Chunk 1)** — AI-powered specification interview tool. AnthropicClient (Net::HTTP wrapper with Sonnet/Opus/Haiku model routing), PromptBuilder (8-section system prompt with caching), Orchestrator (atomic transactions with pessimistic locking, parallel tool_use handling, Haiku compression every 8 turns), 4 tool definitions (ask_question, ask_freeform, generate_client_brief, generate_team_spec). Web chat UI with Stimulus controller. Feature-gated behind "specs" ShopFeature. Rate-limited at 1 req/3s per project. 95 new specs (205 total), all passing.

## 2026-02-20

- **Analytics dashboard UI (Chunk 3)** — full web analytics dashboard replacing the old referral event page. KPI cards (visitors, pageviews, bounce rate, avg duration, revenue) with sparklines, time series chart (Chart.js), top pages, referrers, UTM campaigns, geography, devices, goals, first-touch revenue attribution, and referral performance. Available in both admin and superadmin (with site picker). 3 Stimulus controllers + 8 shared partials + DashboardQueryService.
- **Auto-create analytics site** — first visit to `/admin/analytics` auto-provisions an `Analytics::Site` from the shop's domain and shows a setup page with personalised tracking snippet and install instructions
- **Analytics setup page cleanup** — removed dead-end "Go to dashboard" link that stranded users away from the snippet/instructions
- **Platform architecture (5 chunks):**
  - **Chunk 1: Data models** — `ShopFeature` (per-shop feature gating with active/locked/trial/expired statuses) and `ShopIntegration` (per-provider encrypted credentials replacing ShopCredential). User roles (owner/admin/member) and invite columns. Data migration from ShopCredential → ShopIntegration. Shop gets `feature_enabled?`, `integration_for`, `find_by_shopify_domain` helpers.
  - **Chunk 2: Email auth** — email/password login with BCrypt, invite-only user creation flow with tokenized invite links, `UserMailer` for invite emails, rate-limited login (20 req/min/IP). Session timeout (24h).
  - **Chunk 3: Collapsible sidebar** — persistent left nav replacing top nav bar. Feature-gated sections (active features show normally, locked features show lock icon + preview link). Collapsible on desktop with icon-only mode persisted to localStorage. Mobile slide-out drawer with backdrop. Stimulus `sidebar_controller`.
  - **Chunk 4: Superadmin shop management** — per-shop management page with feature toggles, user management (create + invite), integration status display. Shop creation from superadmin. Audit logging on all management actions.
  - **Chunk 5: Superadmin impersonation** — "View as shop owner" from superadmin. Fixed banner in admin showing impersonated shop with exit controls. 4-hour timeout. `Admin::Impersonatable` concern. Webhook domain lookup via `Shop.find_by_shopify_domain`. Removed superadmin web analytics (now accessed via impersonation).
- **RSpec test suite** — 118 specs across models, requests, and concerns. Full TDD for all platform architecture chunks.

## 2026-02-19

- **Web analytics system (Chunks 1+2)** — self-hosted analytics engine inside the Rails app. `Analytics::Site`, `Analytics::Event`, `Analytics::Payment` models with full visitor/session tracking, GeoIP, bot filtering, UTM capture, and revenue attribution.
- **Tracking script** (`/s.js`) — <3KB vanilla JS beacon with cookie-based visitor/session IDs, SPA support, declarative `data-hp-goal` events, Shopify cart attribute injection for referral→order attribution.
- **Ingestion endpoint** (`POST /collect`) — 204-always ingestion with 64KB body limit, hostname validation, bot filtering (crawler_detect), UA parsing (device_detector), GeoIP (MaxMind). Rate limited at 1000 req/min/IP.
- **Table rename** — `analytics_events` → `referral_events` (model `AnalyticsEvent` → `ReferralEvent`) to free the `analytics_` namespace for web analytics.
- **Audit + hardening** — 5-agent audit found 27 issues. Fixed: removed table partitioning (premature), added ON DELETE CASCADE on FKs, body size limit, hostname validation, secure cookies, SPA UTM refresh, session-guarded cart sync.
- **Bulk customer import** — background job fetches existing Shopify customers with orders via GraphQL, creates Referral records with generated codes, writes referral_code metafields back in batches. Idempotent, cursor-based resume. Admin UI in Settings with live progress polling via Stimulus.
- **Oatcult cart sync** — background cart syncing with 300ms debounce for abandoned cart recovery. AbortController cancels in-flight syncs before checkout redirect. Session storage for back-button state restoration.
- **Interactive overview page** — self-contained `/overview` page for client meeting prep. System architecture diagram, clickable nodes with code examples, user journey flow, feature map, Hydrogen integration guide, testing plans. Print-to-PDF layout.

## 2026-02-18

- **Oatcult header checkout button disabled state** — "Checkout" button starts disabled (grey) on shop-v3 page when no items in box. Enables (yellow) when items are added via `spf:has-items` custom event bridge between purchase flow and header. "Buy now" on non-shop pages unaffected.

## 2026-02-17

- **Oatcult mobile sticky CTA subscription pill** — "subscribing & saving £x.xx" pill appears next to "Your box" when subscribe & save is active. Dynamic savings amount, scale+fade transition on toggle, hidden when no items in box.
- **Oatcult hero gallery jiggle fix** — clicking non-adjacent thumbnails no longer jiggles through intermediates. CSS `scroll-snap-stop: normal` overrides theme's `always` + JS guard suppresses IntersectionObserver during programmatic scrolls.
- **Oatcult flavor card styling overhaul** — solid colors replace gradients (white unselected, #ED6B93 selected), warm brown (#3C1B01) borders with opacity states, "Choose" button text, "9 pack" subtitle
- **Oatcult size card viewport sliding** — fixed 12-tier sliding viewport that was stuck (CSS `width: 100%` fix + replaced `$watch` with computed getter)
- **Shopify theme architecture playbook** — 12-section `SHOPIFY-THEME-PLAYBOOK.md` covering component patterns, decision framework, CSS architecture, animation tiers, Shopify integration, and themes-vs-Hydrogen guidance. Arrived at via 5-agent framework evaluation (Alpine, Svelte, Lit, Preact, Vanilla JS).
- **Architecture decision**: vanilla custom elements (80%) + Preact islands (complex reactivity) + nanostores (shared state) + Motion (animation) + CSS @layer

## 2026-02-16

- **Surface-filtered media pickers** — referral page tab shows only referral banner images, thank-you card tab shows only extension card images. AI-generated images auto-tagged by surface; user uploads tagged by picker context. Untagged images appear everywhere.
- **MediaAsset surface validation** — model-level inclusion validation on `surface` column prevents invalid values
- **3-layer CLAUDE.md** — global rules extracted to `~/.claude/CLAUDE.md`, project CLAUDE.md trimmed, MEMORY.md deduplicated
- **doc-checkpoint skill rewrite** — added session context gathering (git log), CLAUDE.md improvement review across all three layers, auto-memory staleness check, session retrospective output

## 2026-02-14

- **Brand scraper** — automatic brand analysis on OAuth install via Gemini AI. Scrapes theme settings, products, and storefront HTML to build structured brand profile. Auto-sets referral page colors from extracted palette.
- **AI imagery generator** — 8-step pipeline producing marketing images for three surfaces (referral banner, extension card, OG image). Gemini multimodal generation with product + scene reference images, quality review with retry, VIPS post-processing to WebP.
- **Superadmin prompt templates** — CRUD for AI prompt templates with test-generate against any shop's brand profile
- **Superadmin scene assets** — reference image library organized by category/mood for image generation
- **SolidQueue** — PostgreSQL-backed background job queue for brand scraping and image generation
- **OAuth scope re-consent** — returning shops with new scope requirements re-authorize and trigger brand re-scrape + imagery generation
- Fixed OAuth redirect loop when shop already has required scopes

## 2026-02-13

- **Tabbed theme integration UI** — Settings page now has Shopify Theme / Hydrogen tabs. Hydrogen tab includes storefront URL field and copyable discount route snippet (`discount.$code.tsx`) for Hydrogen stores.
- Fixed storefront_url silently wiped when saving slug (split into separate forms, controller guards with `params.key?`)
- Renamed `superadmin_tabs_controller` → shared `tabs_controller` used by both admin and superadmin views
- **Super admin dashboard** at `/superadmin` — master view of all onboarded shops with status filters, referral/campaign/analytics/credentials tabs, and suspend/reactivate actions
- Super admin env-var BCrypt auth with 2-hour session timeout, rate-limited login (5/min/IP), failed login logging
- Suspended shops are now blocked from `/admin` access (admin base controller guard)
- Reactivate guarded to suspended-only — can't accidentally reactivate uninstalled shops
- **Media library** — admin page for uploading and managing banner images with drag-and-drop
- **Inline media pickers** on Referral Page and Thank You Card editors replace URL text inputs
- **Automatic image resizing** to optimized WebP variants (1200x400 referral, 600x400 extension, 300x200 thumbnail)
- **Railway Bucket storage** (Tigris, S3-compatible) via Active Storage with presigned URL redirects
- Storefront URL field in admin settings for Hydrogen/headless stores (referral links + back-to-store adapt automatically)
- Extracted `Api::BaseController` — all API controllers inherit from `ActionController::API` with shared shop auth
- `rack-attack` rate limiting on POST /api/referrals (500 req/min per IP)
- GET /api/referrals/:id endpoint — lookup referral by code (no PII exposed)
- CORS updated: GET + wildcard for /api/referrals, storefront_url returned from config API

## 2026-02-12

- App Bridge 4.x + session token auth on embedded page (passes Shopify automated app checks)
- Hardened JWT verification: required claims (exp/nbf/aud), iss↔dest cross-validation, domain format check, logged failures
- Removed conflicting X-Frame-Options header on embedded page
- Explicit user ordering (`order(:id).first`) in both OAuth and embedded auth flows
- Fixed webhook HMAC validation: invalid signatures now return 401 instead of 200
- Removed `return true if secret.blank?` auth bypasses from Shopify and Custom order handlers
- Switched webhook signing secret from `SHOPIFY_WEBHOOK_SECRET` to `SHOPIFY_CLIENT_SECRET` (what Shopify actually signs with)

## 2026-02-11

- Awtomic API key connect/disconnect flow on integrations page
- Rake task guards against missing Awtomic API key

## 2026-02-10

- Mobile sticky basket polish: full-width slots, always-visible progress bar + badge

## 2026-02-06

- PII compliance: Active Record Encryption on PII fields, audit logging, privacy policy page
- Compliance webhooks (customers/data_request, customers/redact, shop/redact) with HMAC verification
- Recreated app with public distribution (unlisted) for multi-merchant installs
- Fixed critical webhook fallback bug (Shop.active.first on destructive actions)
- SSL, host authorization, and mailer config enabled in production
- Data protection questionnaire submitted

## 2026-01-29

- White-labeled referral URLs with auto-generated shop slugs
- Railway deployment: Rails backend + PostgreSQL at app.happypages.co
- Shopify OAuth for self-service app installation
- Footer: referrals login link on landing page
- Fixed Railway watch patterns for multi-service deployment

## 2026-01-26

- Multi-tenant architecture with encrypted credentials and provider pattern
- Self-service onboarding via Shopify OAuth

## 2026-01-22–23

- Awtomic subscription integration with auto-applied rewards
- Klaviyo integration for referral lifecycle events
- Duplicate reward prevention and expiration handling
- Reward status display on customer referral page

## 2026-01-21

- Shared discount architecture with generations and scheduled boosts
- Configurable referral page with admin UI

## 2026-01-14–16

- Neumorphic design system with live preview and undo support
- Analytics dashboard with event tracking
- /happier design exploration: step card videos/GIFs, grid animation, pricing CTA
- Landing page: works section card deck, member benefits carousel, floating icons, orbit animation

## 2026-01-13

- Referral code generation and webhook-triggered rewards
- Admin UI for extension and discount configuration

## 2026-01-08

- Checkout extension on thank you page with personalized customer names
- Initial landing page with hero, neumorphic card, Railway deployment
