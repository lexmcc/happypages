# Changelog

Dated record of shipped features across both products.

## 2026-02-17

- **Oatcult flavor card styling overhaul** — solid colors replace gradients (white unselected, #ED6B93 selected), warm brown (#3C1B01) borders with opacity states, "Choose" button text, "9 pack" subtitle
- **Oatcult size card viewport sliding** — fixed 12-tier sliding viewport that was stuck (CSS `width: 100%` fix + replaced `$watch` with computed getter)

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
