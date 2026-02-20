# Referrals App Spec

Shopify referral rewards app — merchants install it, customers share referral links, referred orders earn rewards applied automatically.

**Live:** https://app.happypages.co
**Client ID:** `98f21e1016de2f503ac53f40072eb71b` (public distribution, unlisted)

## Architecture

Rails 8.1 + PostgreSQL on Railway. Multi-tenant via `Current.shop` thread-isolated context. Shop lookup from `X-Shop-Domain` header or session user.

### Key Components

- **Shopify OAuth** — self-service install flow, creates Shop + ShopCredential + User in one transaction. Detects scope upgrades on re-auth and triggers brand re-scrape + imagery generation for returning shops.
- **Checkout UI Extension** — Preact + Polaris thank you page widget showing referral link
- **White-labeled URLs** — `/:shop_slug/refer` routes with auto-generated slugs
- **Webhook pipeline** — `orders/create` triggers referral matching and reward generation, HMAC-verified against `SHOPIFY_CLIENT_SECRET` (Shopify) or per-shop `webhook_secret` (Custom). Referral events tracked via `ReferralEvent` model (renamed from `AnalyticsEvent` to free the `analytics_` namespace for web analytics).
- **Encrypted credentials** — Active Record Encryption on all sensitive fields (API keys, tokens, PII)
- **Audit logging** — AuditLog model with JSONB details for compliance events. Actors: webhook, admin, system, customer, super_admin.
- **Embedded app page** — `/embedded` loads inside Shopify admin iframe with App Bridge 4.x CDN. Session token (JWT) auth via `POST /embedded/authenticate` — App Bridge auto-injects Bearer token, backend verifies HS256 signature against client secret, validates required claims (exp, nbf, aud, iss↔dest consistency), and establishes cookie session.

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
- **Klaviyo** — email marketing integration (coming soon, card placeholder on integrations page)

### Admin UI

- **Analytics Dashboard** — web analytics dashboard with KPI cards (visitors, pageviews, bounce rate, avg duration, revenue) with sparklines, time series chart (Chart.js), top pages, referrers, UTM campaigns, geography, devices, goals, first-touch revenue attribution, and referral performance. Powered by `Analytics::DashboardQueryService`. URL-based period/filter/comparison state via Stimulus filter controller. Also available in superadmin with site picker.
- **Referral Page** — configurable customer-facing referral page editor with inline media picker
- **Thank You Card** — checkout extension configuration with inline media picker
- **Media** — image upload and management library. Drag-and-drop uploads to Railway Bucket (Tigris, S3-compatible). Automatic resizing to optimized WebP variants per display context (1200x400 referral banner, 600x400 extension banner, 300x200 thumbnail). 50-image-per-shop limit. Inline media pickers replace URL inputs on editor pages with thumbnail grid selection + URL fallback. Surface-filtered: each picker shows only images relevant to its context (referral banner or extension card) plus untagged uploads. AI-generated images are auto-tagged by surface; user uploads are tagged based on which picker they're uploaded from.
- **Integrations** — Awtomic connect/disconnect, Klaviyo (coming soon)
- **Settings** — shop slug management + tabbed theme integration (Shopify Theme snippet / Hydrogen discount route / Hydrogen referral code snippet). Storefront URL field lives in the Hydrogen tab, separate form per section to prevent cross-field interference. Bulk customer import button with live progress polling — background job fetches Shopify customers via GraphQL, creates Referral records with generated codes, writes referral_code metafields back in batches. Idempotent, cursor-based resume.
- **Suspended shop guard** — admin base controller checks `shop.suspended?` and forces logout if the shop has been suspended via super admin

### Super Admin (`/superadmin`)

Master dashboard for the app owner to manage all onboarded shops. Env-var-based BCrypt auth (no DB migration), 2-hour session timeout, dark slate theme to distinguish from shop admin.

- **Login** — email + BCrypt password verified against `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD_DIGEST` env vars. Rate-limited to 5 attempts/min/IP. Failed attempts logged.
- **Shop list** — all shops ordered by install date, filterable by status (active/suspended/uninstalled). Shows referral counts per shop.
- **Shop detail** — four-tab view (Referrals, Campaigns, Analytics, Credentials) with audit logging on each view. Referral search by code only (encrypted fields can't be queried). No emails displayed.
- **Suspend / Reactivate** — status management with confirmation dialogs and audit trail. Reactivate guarded to suspended-only (can't reactivate uninstalled shops).
- **Credentials tab** — shows integration connection status (Present/Missing/Connected) without exposing actual tokens.
- **Brand & AI tab** — view shop's brand profile, trigger re-scrape, see generation logs and quality scores.
- **Prompt Templates** (`/superadmin/prompt_templates`) — CRUD for AI prompt templates with test-generate against any shop's brand profile.
- **Scene Assets** (`/superadmin/scene_assets`) — upload and manage reference images for image generation, organized by category/mood/tags.

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

### API Layer

- **`Api::BaseController`** — shared base class inheriting `ActionController::API` with `ShopIdentifiable` concern and `X-Shop-Domain` header auth. All API controllers inherit from this.
- **`POST /api/referrals`** — create referral (idempotent by email)
- **`GET /api/referrals/:id`** — lookup referral by code, returns `referral_code`, `usage_count`, `share_url` (no PII)
- **`GET /api/config`** — extension configuration including `storefront_url` for Hydrogen stores
- **`POST /api/analytics`** — event tracking from checkout extension (referral events, not web analytics)
- **Rate limiting** — `rack-attack` throttles POST /api/referrals at 500 req/min per IP, POST /superadmin/login at 5 req/min per IP, POST /collect at 1000 req/min per IP
- **CORS** — Shopify + custom origins for referrals (GET + POST), open for config and analytics endpoints, wildcard for /collect

### Hydrogen / Headless Storefront Support

- Optional `storefront_url` field on Shop — merchants set this in Settings (Hydrogen tab) for headless storefronts
- `customer_facing_url` helper returns `storefront_url` or falls back to `https://{domain}`
- Referral copy-link, back-to-store link, and config API all use `customer_facing_url`
- `shop_slug` and `referral_code` metafields have storefront API read access for Liquid/Storefront API queries
- **Discount route snippet** — copyable `app/routes/discount.$code.tsx` Remix route file provided in admin Settings. Uses Storefront API `cartCreate` mutation to apply discount code and redirect to homepage, replicating Online Store's built-in `/discount/CODE` route for Hydrogen stores.

### Data Protection

- Privacy policy at `/privacy`
- Compliance webhooks: `customers/data_request`, `customers/redact`, `shop/redact`
- Active Record Encryption on PII (email, first_name) and credentials
- Audit logging on all compliance actions
- `support_unencrypted_data = false` enforced

## What's Next

### Shopify App Submission

#### Pre-Deploy
- [ ] Deploy app + webhooks: `cd happypages-referrals && shopify app deploy --force`
- [ ] Verify webhook subscriptions in Partner Dashboard

#### Partner Dashboard
- [ ] Add privacy policy URL: `https://app.happypages.co/privacy`
- [ ] Verify protected customer data access approved (email, first_name)
- [ ] Verify network access approval for theme extension
- [ ] Upload walkthrough video (.mp4, 1080p, < 3 min)
- [ ] Fill in testing instructions
- [ ] App intro (100 chars), app details (500 chars), feature bullets (80 chars each)
- [ ] Submit for review

#### Walkthrough Video Scenes
1. Install flow — OAuth from app listing → grant screen → redirect to admin
2. First-time setup — Configure extension in admin UI → save → live preview
3. Referral page — Visit `/:shop_slug/refer`
4. Customer journey — Checkout → thank you page shows extension → share link
5. Referral tracked — Referred order via webhook → reward code generated
6. Analytics — Admin analytics dashboard

#### Test Store Cleanup (`happypages-test-store`)
- [ ] Remove messy test/dummy orders
- [ ] Ensure theme has extension block enabled and visible
- [ ] Verify referral page loads at `/:slug/refer`
- [ ] Test fresh install flow (uninstall → reinstall)

### App Hardening

| Priority | Issue | Notes |
|----------|-------|-------|
| High | No API auth on `/api/*` endpoints | Header-only shop identification, no HMAC/token |
| High | Zero automated tests | No test suite at all — model + webhook tests at minimum |
| Medium | Broad `rescue => e` in webhooks | Swallows errors silently — rescue specific exceptions |
| Medium | Missing DB indices | `referral_events(shop_id, created_at)`, `discount_configs(shop_id, config_key)` (note: `analytics_events` table has proper indices) |
| Low | ~~CORS gem included but unconfigured~~ | **Done** — CORS initializer with Shopify + custom origins |
| Low | ~~No rate limiting~~ | **Done** — rack-attack on POST /api/referrals (500/min/IP) |

### Housekeeping
- [ ] Delete old custom distribution app from Partner Dashboard
