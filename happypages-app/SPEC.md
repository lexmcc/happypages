# Referrals App Spec

Shopify referral rewards app — merchants install it, customers share referral links, referred orders earn rewards applied automatically.

**Live:** https://app.happypages.co
**Client ID:** `98f21e1016de2f503ac53f40072eb71b` (public distribution, unlisted)
**Custom App:** `[FD] - Happypages Referrals` — client ID `61162a744826a338fa331f460b18a82c`, same backend, TOML at `happypages-referrals/shopify.app.fd-happypages-referrals.toml`

## Architecture

Rails 8.1 + PostgreSQL on Railway. Multi-tenant via `Current.shop` thread-isolated context. Shop lookup from `X-Shop-Domain` header or session user.

### Key Components

- **Dual auth** — Shopify OAuth (self-service install, creates Shop + ShopCredential + ShopIntegration + User) and email/password login (invite-only, BCrypt). Users have roles (`owner`, `admin`, `member`) and invite tokens. Rate-limited login (20 req/min/IP). OAuth state consumed atomically via `session.delete(:oauth_state)` to prevent replay. `params[:app]` allowlisted to `%w[custom]`.
- **Checkout UI Extension** — Preact + Polaris thank you page widget showing referral link
- **White-labeled URLs** — `/:shop_slug/refer` routes with auto-generated slugs
- **Webhook pipeline** — `orders/create` triggers referral matching and reward generation, HMAC-verified against `SHOPIFY_CLIENT_SECRET` (Shopify) or per-shop `app_client_secret` (Custom). Shop lookup via `Shop.find_by_shopify_domain` (checks ShopIntegration first, falls back to `shops.domain`). Both the public app and custom app (`[FD] - Happypages Referrals`) have identical webhook subscriptions pointing at the same backend. Webhook flow writes both customer note and `referral_code` metafield. Referral events tracked via `ReferralEvent` model.
- **Encrypted credentials** — Active Record Encryption on all sensitive fields (API keys, tokens, PII). `ShopIntegration` model holds per-provider credentials (Shopify, WooCommerce, Custom) with encrypted tokens. `ShopCredential` retained as read-only fallback. `app_client_id` uniqueness enforced, `app_client_secret` required when `app_client_id` present. `find_by_app_client_id` scoped to active integrations only.
- **Feature gating** — `ShopFeature` model tracks per-shop feature activation (referrals, analytics, specs, cro, insights, landing_pages, funnels, ads, ambassadors). Status: active, locked, trial, expired. Sidebar navigation dynamically shows/hides features based on status.
- **Audit logging** — AuditLog model with JSONB details for compliance events. Actors: webhook, admin, system, customer, super_admin, super_admin_impersonating.
- **Embedded app page** — `/embedded` loads inside Shopify admin iframe with App Bridge 4.x CDN. API key meta tag resolves from `Current.shop`'s integration (falls back to ENV). Session token (JWT) auth via `POST /embedded/authenticate` — App Bridge auto-injects Bearer token, backend verifies HS256 signature against client secret (nil/blank secret rejected before HMAC), validates required claims (exp, nbf, aud, iss↔dest consistency), and establishes cookie session.

### Brand Scraping & AI Imagery

Automated brand analysis and marketing image generation pipeline powered by Gemini.

- **Brand Scraper** — on OAuth install (or scope upgrade), scrapes Shopify theme settings, top products, and storefront HTML. Gemini analyzes the data and returns a structured `brand_profile` (category, style, vibe, palette, suggested scene). Auto-sets referral page colors from extracted palette if merchant hasn't customized.
- **Imagery Generator** — 8-step pipeline: product selection → scene matching → prompt building → Gemini image generation (multimodal, with product + scene reference images) → quality review (score 1-10, retry if < 7) → VIPS post-processing → WebP storage as MediaAsset → applied to discount configs. Three surfaces: `referral_banner` (1200x400), `extension_card` (600x400), `og_image` (1200x630).
- **Gemini Client** — HTTP wrapper for Google Generative AI API. Text, image analysis, image generation, and JSON modes. SSRF protection on image fetches. Models: `gemini-2.0-flash` (text), `gemini-2.0-flash-exp` (image gen).
- **Prompt Templates** — reusable AI prompts with `{variable}` interpolation. Surfaces: referral_banner, extension_card, og_image, brand_analysis, quality_review, product_selection, scene_selection. Category-specific templates with universal fallback. Managed via superadmin UI.
- **Scene Assets** — reference image library organized by category (food, fashion, beauty, etc.) and mood/tags. Managed via superadmin UI.
- **Generation Logs** — audit trail per generation: prompt, image URL, quality score, cost, retry flag.
- **SolidQueue** — PostgreSQL-backed job queue. `BrandScrapeJob` chains into `ImageGenerationJob` on successful scrape. Retry with exponential backoff on Gemini rate limits and network timeouts.

### Integrations

- **Awtomic** — subscription management, auto-applies referral rewards to subscriptions. Connect/disconnect flow via admin integrations page. Webhook listener for billing attempt lifecycle.
- **Linear** — project management integration for Specs engine. Admin OAuth flow (`/admin/linear/*`) connects shop to Linear workspace. Push kanban cards to Linear as issues (background job, status-mapped). Bi-directional status sync via webhooks (`/linear_integration/webhooks`). `LinearClient` service (Net::HTTP + GraphQL, follows AnthropicClient pattern). `ShopIntegration` stores encrypted `linear_access_token` + `linear_webhook_secret`. Webhook verification via per-team HMAC-SHA256 secret with 60s replay protection. Shop-scoped only (org-owned projects can't push to Linear). Env vars: `LINEAR_CLIENT_ID`, `LINEAR_CLIENT_SECRET`.
- **Klaviyo** — email marketing integration (coming soon, card placeholder on integrations page)

### Admin UI

- **Collapsible sidebar** — persistent left nav with feature-gated sections. Collapsible on desktop (icon-only mode persisted to localStorage via Stimulus). Mobile: slide-out drawer with backdrop. Shows active features with icons; locked features show lock icon and link to feature preview pages. Section headers group related features (Main, Marketing, Insights).
- **Referral Performance Dashboard** — dedicated `/admin/performance` page with 6 KPI cards (extension loads, share rate %, page visits, referred orders, conversion rate %, referred revenue) with sparklines and period comparison badges. Time series chart (click KPI to switch metric, previous-period comparison overlay). 4-stage funnel visualisation (extension loads → page visits → shares → referred orders) with step-to-step conversion rates. Source breakdown (extension vs direct). Top referrers table. Period selector (today/7d/30d/90d). Empty state for new merchants. Powered by `Referrals::PerformanceQueryService`. Reuses `analytics_chart_controller.js` and `analytics_sparkline_controller.js` Stimulus controllers.
- **Analytics Dashboard** — web analytics dashboard with KPI cards (visitors, pageviews, bounce rate, avg duration, revenue) with sparklines, time series chart (Chart.js), top pages, referrers, UTM campaigns, geography, devices, goals, first-touch revenue attribution, and referral performance. Powered by `Analytics::DashboardQueryService`. URL-based period/filter/comparison state via Stimulus filter controller. Also available in superadmin with site picker. Hidden from sidebar (accessible by URL).
- **Referral Page** — configurable customer-facing referral page editor with inline media picker
- **Thank You Card** — checkout extension configuration with inline media picker
- **Media** — image upload and management library. Drag-and-drop uploads to Railway Bucket (Tigris, S3-compatible). Automatic resizing to optimized WebP variants per display context (1200x400 referral banner, 600x400 extension banner, 300x200 thumbnail). 50-image-per-shop limit. Inline media pickers replace URL inputs on editor pages with thumbnail grid selection + URL fallback. Surface-filtered: each picker shows only images relevant to its context (referral banner or extension card) plus untagged uploads. AI-generated images are auto-tagged by surface; user uploads are tagged based on which picker they're uploaded from.
- **Integrations** — Awtomic connect/disconnect, Linear OAuth connect/team-select/disconnect with status badges, Klaviyo (coming soon)
- **Settings** — shop slug management + tabbed theme integration (Shopify Theme snippet / Hydrogen discount route / Hydrogen referral code snippet). Storefront URL field lives in the Hydrogen tab, separate form per section to prevent cross-field interference. Bulk customer import button with live progress polling — background job fetches Shopify customers via GraphQL, creates Referral records with generated codes, writes referral_code metafields back in batches. Idempotent, cursor-based resume.
- **Suspended shop guard** — admin base controller checks `shop.suspended?` and forces logout if the shop has been suspended via super admin

### Super Admin (`/superadmin`)

Master dashboard for the app owner to manage all onboarded shops. Env-var-based BCrypt auth (no DB migration), 2-hour session timeout, dark slate theme to distinguish from shop admin.

- **Login** — email + BCrypt password verified against `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD_DIGEST` env vars. Rate-limited to 5 attempts/min/IP. Failed attempts logged.
- **Shop list** — all shops ordered by install date, filterable by status (active/suspended/uninstalled). Shows referral counts per shop.
- **Shop management** — per-shop page with feature toggles (activate/lock per feature), user management (create users, send invites), integration status, and audit log. Audit logging on all management actions.
- **Suspend / Reactivate** — status management with confirmation dialogs and audit trail. Reactivate guarded to suspended-only (can't reactivate uninstalled shops).
- **Impersonation** — "View as shop owner" button on shop management page sets `session[:impersonating_shop_id]` and redirects to admin dashboard. Fixed 40px banner shows impersonated shop name with "Back to Superadmin" and "Exit" buttons. 4-hour timeout via `Admin::Impersonatable` concern. Audit logged as `super_admin_impersonating` actor.
- **Brand & AI tab** — view shop's brand profile, trigger re-scrape, see generation logs and quality scores.
- **Prompt Templates** (`/superadmin/prompt_templates`) — CRUD for AI prompt templates with test-generate against any shop's brand profile.
- **Scene Assets** (`/superadmin/scene_assets`) — upload and manage reference images for image generation, organized by category/mood/tags.
- **Specs Overview** (`/superadmin/specs_overview`) — cross-shop/org read-only view of all specs projects. Filterable by shop, organisation, and session status (active/completed). Table shows project name, owner (linked), session counts, card status badges, and creation date.
- **Per-shop specs tab** — 6th "Specs" tab on shop detail page showing shop's specs projects with session/card summaries.
- **Organisations** (`/superadmin/organisations`) — create and manage organisations for non-Shopify specs clients. Per-org management page shows clients and projects. Create clients (generates invite token, sends email via `SpecsClientMailer`), resend invites.
- **Ops Dashboard** (`/superadmin/ops`) — embeds the local ops dashboard (comms log, meetings, commitments, backlogs) via client-side fetch from `127.0.0.1:3333`. Shows graceful fallback when the local Node server isn't running. Dashboard server lives at `ops/dashboard/` (outside git repo, local-only).

### Web Analytics System

Lightweight, self-hosted web analytics for tracking page views, custom events, and revenue attribution across client Shopify themes and the referral app itself.

- **Auto-provisioning** — first visit to `/admin/analytics` auto-creates an `Analytics::Site` from the shop's domain and renders a setup page with the personalised tracking snippet and install instructions. Dashboard appears once data arrives.
- **Analytics::Site** — per-shop analytics site with unique `site_token` (32-char hex). Scoped to shop, one site per domain. `dependent: :delete_all` on events and payments for fast teardown.
- **Analytics::Event** — immutable event log (no `updated_at`). Stores visitor/session IDs, event name, pathname, hostname, referrer, UTMs, browser/OS/device, GeoIP (country, region, city), referral code, and custom properties (JSONB, max 50 keys). `occurred_at` is the sole timestamp.
- **Analytics::Payment** — revenue attribution record linking visitor/session to order. Amount in cents, currency, referral code for attribution. Unique constraint on `[site_id, order_id]`.
- **Tracking script** (`/s.js`) — <3KB vanilla JS IIFE. Cookie-based visitor (1-year `hp_vid`) and session (30-min sliding `hp_sid`). `sendBeacon` with `text/plain` to avoid CORS preflight, `fetch+keepalive` fallback. SPA support via `history.pushState/replaceState` monkey-patching. Declarative goals via `data-hp-goal` attributes. Shopify cart attribute injection (`hp_vid/hp_sid/hp_ref`) for referral→order attribution. Session-guarded to sync once per session.
- **Ingestion endpoint** (`POST /collect`) — `Analytics::CollectController` inherits `ActionController::API` directly (no `Current.shop`, no `X-Shop-Domain`). 64KB body size limit. Delegates to `Analytics::EventIngester` service: parse → validate → bot filter (`crawler_detect`) → site lookup by token → hostname validation (reject mismatched domains, allow subdomains) → UA parsing (`device_detector`) → GeoIP (`maxmind-geoip2`) → truncate/sanitize → insert. Always returns 204.
- **GeoIP** — MaxMind GeoLite2-City database downloaded on boot via `start.sh` using `MAXMIND_LICENSE_KEY` env var. Graceful nil if file/key missing.
- **Rate limiting** — 1000 req/min per IP on `/collect`
- **CORS** — wildcard origin on `/collect` (POST + OPTIONS)
- **Dashboard query service** — `Analytics::DashboardQueryService` computes all dashboard metrics from raw events: unique visitors, pageviews, bounce rate, avg visit duration, revenue totals, sparkline data, time series, top pages/referrers/UTMs, geography, device/browser/OS breakdowns, goal conversions, first-touch revenue attribution, and referral performance. Supports period filtering (today, 7d, 30d, custom) and comparison periods.

### Specs Engine (AI-Powered Specification Interviews)

Interview-driven specification tool powered by the Anthropic API. Stakeholders answer structured questions; the AI produces client briefs and team specs. See [`docs/features/specs-engine.md`](/docs/features/specs-engine.md) for the full multi-chunk feature spec and roadmap.

- **Models** — `Specs::Project` (per-shop or per-organisation, with optional context briefing and accumulated context JSONB), `Specs::Session` (versioned per project, tracks phase/turns/transcript/outputs), `Specs::Message` (immutable display records with optional image attachments and `image_data` JSONB for analysis results via Active Storage), `Specs::Client` (per-organisation authenticated client, includes `Authenticatable` concern). `Organisation` model for non-Shopify clients (has_many specs_clients and specs_projects). XOR validation on Project: must belong to shop OR organisation, not both/neither (enforced at both model and DB CHECK constraint level).
- **AnthropicClient** — vanilla Net::HTTP wrapper for the Anthropic Messages API. Model constants for Sonnet, Opus, Haiku. Error hierarchy: RateLimitError (429), OverloadedError (529), MaxTokensError, RefusalError. Prompt caching via system prompt array format with `cache_control: {type: "ephemeral"}`.
- **Orchestrator** — `Specs::Orchestrator#process_turn` handles the full API round-trip inside a pessimistic-locked transaction. Assembles system prompt (8 sections: persona, methodology, phase, turn budget, project context, session context, active user, output instructions), selects model (Sonnet default, Opus for generate phase + complexity heuristics), calls API, stores full assistant content array verbatim in transcript, processes tool_use blocks (including `analyze_image` → stores structured analysis on message `image_data` column), creates display Message records, and updates session state atomically. Compression via Haiku every 8 turns. Phase advancement is guided-fluid (budget-based defaults, AI can advance early).
- **Tool definitions** — v1 ships 6 tools: `ask_question` (structured with 2-4 options), `ask_freeform` (open-ended), `analyze_image` (extracts colors/typography/layout/spacing/effects from uploaded screenshots), `generate_client_brief` (client-facing doc), `generate_team_spec` (team-facing spec with chunks, acceptance criteria, and design tokens), `request_handoff` (suggest session handoff to another participant). Parallel tool calls supported (both generate tools in one response). `v1_client` variant excludes `request_handoff` for client portal sessions.
- **Handoff + multi-user** — `Specs::Handoff` model tracks AI-initiated handoff requests with reason, summary, suggested questions, and suggested role. Admin can hand off internally (to another shop user, switches `session.user_id`) or create an external client invite (token-based, 7-day expiry). Guest access via `/specs/join/:token` with minimal layout (no admin nav). One pending handoff per session validation. Messages attributed via `user_id` or `specs_client_id` on `specs_messages`; `sender_name` method resolves from User → Specs::Client → active handoff's `to_name` → "Guest". Orchestrator accepts `user:` (User record for DB attribution), `active_user:` (context hash `{name:, role:, handoff_context:}` for prompt), `specs_client:` (Client record for client portal attribution), and `tools:` (tool definitions override). PromptBuilder includes handoff history and adapts active user section for guests. Guest routes rate-limited at 1 req/3s per invite token.
- **Client portal** — authenticated web portal for organisation clients at `/specs/*`. `Specs::Client` model with BCrypt auth (shared `Authenticatable` concern with User, minimum 8-char password validation). Login at `/specs/login`, invite acceptance at `/specs/invite/:token` (7-day token expiry). Dashboard shows organisation's projects. Clients can create projects, chat (using `v1_client` tools — no handoff), view client briefs, and export briefs as markdown. Team specs are hidden from clients. Separate session keys (`specs_client_id`, `specs_last_seen`) from admin auth, 24h timeout. Client layout based on guest layout with name + logout header. Rate-limited: 5/min on login, 1 req/3s on message.
- **Dual output view** — completed sessions show tabbed interface (Chat / Client Brief / Team Spec / Board) using shared `tabs_controller.js`. Client Brief renders structured JSONB with sections. Team Spec renders chunks with acceptance criteria, dependency tags, UI badges, tech notes, design token swatches, and open questions. Both exportable as markdown via `GET /admin/specs/:id/export?type=brief|spec`.
- **Kanban board** — `Specs::Card` model tracks delivery cards through Backlog → In Progress → Review → Done. Auto-populated from `generate_team_spec` tool output (one card per chunk, idempotent). Admin gets drag-and-drop via SortableJS (`kanban_controller.js`) plus manual card creation. Clients get a read-only board view. Board tab appears on completed sessions with team_spec or cards. JSON API: `GET board_cards` (admin + client), `PATCH update_card` and `POST create_card` (admin only). Push to Linear via `POST push_to_linear` (admin, shop-scoped projects only) — cards synced to Linear display "LIN" badge linking to the Linear issue. Bi-directional status sync via `LinearIntegration::WebhooksController` and `Specs::LinearSyncJob`.
- **Versioning** — `POST /admin/specs/:id/new_version` creates a new session seeded with context from the previous session's outputs. Version dropdown appears when multiple versions exist. Each version's chat and outputs are independently viewable via `?version=N` param.
- **Web UI** — chat interface at `/admin/specs/:id` with Stimulus controller. Option buttons for structured questions, image upload with analysis card (blue info card with color swatches), handoff request cards (amber, with invite/assign actions), turn counter, phase label, progress bar, sender name attribution when multiple participants. Auto-reload on session completion.
- **Guest access** — minimal guest layout at `/specs/session/:token` with chat interface and input bar. No admin nav or sidebar. Uses `spec_session_controller.js` with guest message endpoint URL. Join flow at `/specs/join/:token` shows project summary, AI's handoff summary, suggested questions, and name input.
- **Channel adapter layer** — `Specs::Adapters::Base` wraps orchestrator calls, `Specs::Adapters::Web` handles web-specific formatting (e.g. stripping team_spec for clients), `Specs::Adapters::Slack` formats results as Slack Block Kit JSON. `Specs::Adapters.for(session, **opts)` registry factory returns the correct adapter by `session.channel_type`. `Specs::MessageHandling` concern extracts shared error handling (blank check, rate limit rescue, API error rescue) from all three web message controllers (admin, client, guest). `Specs::Session` tracks `channel_type` (web/slack/teams, default web) and `channel_metadata` (JSONB).
- **Slack integration** — `slack-ruby-client` gem. Organisation stores `slack_team_id`, `slack_bot_token` (encrypted), `slack_app_id`. Specs::Client has optional `slack_user_id` (unique per org). Controllers namespaced as `SlackIntegration::` (not `Slack::` to avoid gem collision). Request verification via HMAC signature (`SLACK_SIGNING_SECRET`). Three webhook endpoints: `/slack_integration/events` (threaded messages → `SlackEventJob`), `/slack_integration/actions` (button clicks → `SlackActionJob`), `/slack_integration/commands` (`/spec new` → `SlackCommandJob`). All orchestrator calls in SolidQueue background jobs (Slack requires HTTP 200 within 3s). `SlackRenderer` converts tool outputs to Block Kit (section blocks, action buttons with `speccy_option_{session_id}_{index}` action_ids, context blocks). OAuth flow at `/specs/slack/install` + `/specs/slack/callback` with CSRF state parameter. Event deduplication via Rails.cache (5-min TTL). JSONB partial index on `channel_metadata->>'thread_ts'` for session-by-thread lookup. Env vars: `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_SIGNING_SECRET`.
- **Notifications** — polymorphic `Notification` model (recipient + notifiable) with 3 action types: `spec_completed`, `card_review`, `turn_limit_approaching`. JSONB notification preferences on User (`notification_muted?` check). `Specs::NotifyJob` background job for fire-and-forget creation outside Orchestrator transactions (notification_queue pattern: capture intent inside lock, enqueue after commit). Notification bell in admin sidebar with 30s polling via Stimulus (`notification_bell_controller.js`, `credentials: 'same-origin'` for session cookies). Notifications page with per-type preference toggles, mark-as-read (redirects to project), mark-all-read. Nil guard for superadmin impersonation (returns `{ unread_count: 0 }`). Triggers: Orchestrator auto-complete → `spec_completed`, Orchestrator 80% turn budget → `turn_limit_approaching`, admin complete/card-to-review → enqueue, Linear sync review → enqueue. Shop-scoped only (org-scoped deferred). 90-day stale scope for future cleanup.
- **Session limits + usage gating** — `Specs::UsageChecker` service gates session creation per billing cycle. Per-shop limits stored as JSONB metadata on `ShopFeature` (`tier`, `monthly_limit`, `billing_cycle_anchor`); per-org limits stored as dedicated columns on `Organisation` (`specs_tier`, `specs_monthly_limit`, `specs_billing_cycle_anchor`). Two tiers: Tier 1 (5/mo default), Tier 2 (8/mo default). `nil` or `0` monthly_limit = unlimited (default until superadmin assigns a tier). Counts only completed sessions since billing cycle start. Soft enforcement at 4 session creation points: admin create, admin new_version, client portal create, Slack `/spec new` command. Usage pill in admin specs index and client dashboard shows "X of Y sessions used this cycle" with progress bar. "New project" button disabled at limit. Superadmin manage pages (shop + org) show Specs Usage section with tier/limit/anchor edit form. Tier values validated against `TIERS` constant. Configurable billing cycle anchor (defaults to 1st of month).
- **Rate limiting** — 1 req per 3s per project on admin message endpoint, 1 req per 3s per invite token on guest message endpoint (Rack::Attack). No rate limiting on Slack webhook endpoints (signature verification is the security layer).

### API Layer

- **`Api::BaseController`** — shared base class inheriting `ActionController::API` with `ShopIdentifiable` concern and `X-Shop-Domain` header auth. All API controllers inherit from this.
- **`POST /api/referrals`** — create referral (idempotent by email)
- **`GET /api/referrals/:id`** — lookup referral by code, returns `referral_code`, `usage_count`, `share_url` (no PII)
- **`GET /api/config`** — extension configuration including `storefront_url` for Hydrogen stores
- **`POST /api/analytics`** — event tracking from checkout extension (referral events, not web analytics)
- **Rate limiting** — `rack-attack` throttles POST /api/referrals at 500 req/min per IP, POST /superadmin/login at 5 req/min per IP, POST /collect at 1000 req/min per IP, POST /specs/login at 5 req/min per IP, POST /specs/projects/:id/message at 1 req/3s per path
- **CORS** — Shopify + custom origins for referrals (GET + POST), open for config and analytics endpoints, wildcard for /collect

### Hydrogen / Headless Storefront Support

- Optional `storefront_url` field on Shop — merchants set this in Settings (Hydrogen tab) for headless storefronts
- `customer_facing_url` helper returns `storefront_url` or falls back to `https://{domain}`
- Referral copy-link, back-to-store link, and config API all use `customer_facing_url`
- `shop_slug` and `referral_code` metafields have storefront API read access for Liquid/Storefront API queries. Metafield namespace is dynamic via `Shop#metafield_namespace` — returns `app--fd-happypages-referrals` for the custom app, `app--happypages-friendly-referrals` for the public app (matched by `SHOPIFY_CUSTOM_CLIENT_ID` env var).
- **Discount route snippet** — copyable `app/routes/discount.$code.tsx` Remix route file provided in admin Settings. Uses Storefront API `cartCreate` mutation to apply discount code and redirect to homepage, replicating Online Store's built-in `/discount/CODE` route for Hydrogen stores.

### Data Protection

- Privacy policy at `/privacy`
- Compliance webhooks: `customers/data_request`, `customers/redact`, `shop/redact`
- Active Record Encryption on PII (email, first_name) and credentials
- Audit logging on all compliance actions
- `support_unencrypted_data = false` enforced

## What's Next

- [ ] PostHog Analytics Integration (see [posthog-evaluation.md](../docs/features/posthog-evaluation.md))
- [ ] Referrals: Self-referral prevention — user's own referral code must not work for themselves. Tested and broken, needs fix
- [ ] Referrals: Metafield storage for rewards — confirm rewards are stored in metafields so account area can display them
- [ ] Referrals: Discount grouping — investigate whether each reward creating a separate discount (instead of grouped) is a bug. Ben ok with current behaviour for now
- [ ] Referrals: CS team referral data access — longer term, CS team needs to look up referral info without pinging Ben. Gorgias widget or in-app view
- [ ] Referrals: Customer timeline enrichment — reward usage events showing in Shopify customer timeline. Referral code note works, reward usage needs verification
- [ ] Referrals: Klaviyo event on reward — fire Klaviyo event when reward is generated so email notification can be sent. Ben offered to help with API key
- [ ] Referrals: Per-customer referral page link — metafield with link to their referral page (for checkout/thank you widget). Needs confirming setup
- [ ] Referrals: Reward state clearing — clear reward from metafield once used (via Atomic or checkout) so account doesn't show stale rewards
## Done

- [x] Housekeeping — old custom distribution app deleted from Partner Dashboard

- [x] App Hardening
  - [x] RSpec suite — 647 specs (model, request, service, concern, mailer, job)
  - [x] DB indices — already in place: `discount_configs(shop_id, config_key)` composite unique, `referral_events(shop_id)` + `referral_events(created_at)` individual indices. Sufficient for current scale.
  - [x] API auth on `/api/*` endpoints — accepted risk: header-only shop ID, but endpoints are low-sensitivity (config reads, referral CRUD), rate-limited, and only called from Shopify checkout sandbox. No destructive mutations exposed.
  - [x] CORS initializer with Shopify + custom origins
  - [x] rack-attack rate limiting (500/min/IP on POST /api/referrals)
  - [x] Narrow `rescue => e` in webhooks — accepted risk: broad rescues are intentional defensive isolation preventing Shopify retry storms. Each wraps a non-critical side effect (customer note, metafield, discount) with error logging. No data corruption possible.

- [x] Shopify App Submission — app submitted for review, public app webhooks deployed, privacy policy live, protected customer data and network access approved, walkthrough video uploaded, test store cleaned up.