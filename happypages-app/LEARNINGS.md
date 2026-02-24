# Project Learnings

Detailed learnings, gotchas, and session discoveries. Claude reads this when working on related areas.

## Gotchas & Bug Fixes

### Webhook HMAC `return true if secret.blank?` Bypass (Feb 12, 2026)
- Both `Shopify::OrderHandler` and `Custom::OrderHandler` had `return true if secret.blank?` at the top of `verify_signature`
- This meant any request was accepted without verification when the signing secret wasn't configured
- Shopify's automated app check sends a POST to `/webhooks/compliance` with an invalid HMAC and expects 401 — we returned 200
- Additionally, Shopify signs webhooks with `SHOPIFY_CLIENT_SECRET` (the app's client secret), but we were looking at `SHOPIFY_WEBHOOK_SECRET` which didn't exist
- **Fix**: Removed the blank-secret bypass from both handlers. Controller now checks: HMAC present + no secret → 401, no HMAC + no secret → skip (local dev). Always use `SHOPIFY_CLIENT_SECRET` for Shopify.
- **Lesson**: Never `return true` on a missing secret — that's an auth bypass, not a graceful fallback

### Shop.active.first Fallback (Feb 6, 2026)
- `set_shop_from_webhook` had `Current.shop ||= Shop.active.first` as a fallback for when webhook domain didn't match any shop
- Test compliance webhooks from Shopify CLI send `{shop}.myshopify.com` as domain, which doesn't match any real shop
- The fallback grabbed the first real shop, then `shop/redact` handler called `shop.destroy!` cascade-deleting all data
- **Fix**: Removed fallback. Webhooks now only match by exact domain. If no match, `Current.shop` stays nil and handlers skip gracefully
- **Lesson**: Never use broad fallbacks on destructive webhook handlers

### Shopify Distribution is Permanent (Feb 6, 2026)
- Custom distribution locks app to one Plus organization — can't install on arbitrary stores
- Distribution type cannot be changed after selection
- Had to create an entirely new app with public distribution (unlisted visibility)
- **Lesson**: Choose public distribution from the start if multi-merchant is planned

### Protected Customer Data Chicken-and-Egg (Feb 6, 2026)
- `orders/create` webhook contains customer PII, so it requires protected customer data access approval
- Can't deploy ANY webhook with customer data until access is approved
- **Workaround**: Deploy without webhooks → request protected data access → re-deploy with webhooks
- Compliance webhooks (`customers/data_request`, `customers/redact`, `shop/redact`) also require this approval

### Audit Log Cascade Deletion (Feb 6, 2026)
- `has_many :audit_logs, dependent: :destroy` on Shop means shop deletion removes audit trail
- The `shop_redact` handler correctly sets `shop: nil` on the audit log before destroying the shop
- But `data_request` and `customer_redact` logs with `shop_id` set are lost on shop destruction
- Consider: should compliance audit logs survive shop deletion? May need `dependent: :nullify` instead

### Hand-Rolled JWT Claims Must Be Required (Feb 12, 2026)
- Initial implementation used `claims["exp"] && now > claims["exp"]` — this silently skipped validation when the claim was missing
- A forged token omitting `exp`, `nbf`, or `aud` would bypass all time/audience checks
- **Fix**: Changed to `return nil unless claims["exp"].is_a?(Integer)` before comparison — claim must be present AND valid type
- Also added `iss` ↔ `dest` host cross-validation and `*.myshopify.com` domain format check on `dest`
- **Lesson**: When hand-rolling JWT verification, require every claim you check — optional-if-present is a security gap

### X-Frame-Options Conflicts with CSP frame-ancestors (Feb 12, 2026)
- Rails sets `X-Frame-Options: SAMEORIGIN` by default
- The embedded controller set `Content-Security-Policy: frame-ancestors ...` but never removed X-Frame-Options
- Modern browsers prefer CSP over X-Frame-Options, but having both is technically conflicting
- **Fix**: Added `response.headers.delete("X-Frame-Options")` before setting CSP
- **Lesson**: Always delete X-Frame-Options when setting frame-ancestors

### Api::BaseController Extraction (Feb 13, 2026)
- API controllers previously inherited `ApplicationController` and skipped `verify_authenticity_token` + `set_current_shop`, then re-included `ShopIdentifiable` — 4 lines of boilerplate per controller
- `Api::BaseController` inherits `ActionController::API` (no CSRF, no session, no browser middleware) and includes `ShopIdentifiable` once
- **Gotcha**: `ActionController::API` doesn't include `ActionController::Base` middleware — no `verify_authenticity_token` to skip, no `set_current_shop` to skip. Clean inheritance.

### rack-attack Requires Separate Gem (Feb 13, 2026)
- `rack-attack` is NOT bundled with Rails despite being Rack middleware
- Must add `gem "rack-attack"` to Gemfile and create `config/initializers/rack_attack.rb`
- Throttle rules use `Rack::Attack.throttle` with a block returning a discriminator (e.g., `req.ip`) or nil to skip

### Railway Bucket Env Var Names Are Preset-Dependent (Feb 13, 2026)
- Railway's "Connect Service to Bucket" dialog has a preset dropdown (AWS SDK Generic, Ruby on Rails ActiveStorage, Django, etc.)
- Each preset injects **different env var names** for the same bucket
- "AWS SDK (Generic)" injects: `AWS_BUCKET`, `AWS_ENDPOINT`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- "Ruby on Rails (ActiveStorage)" would inject: `AWS_S3_BUCKET_NAME`, `AWS_ENDPOINT_URL`, `AWS_DEFAULT_REGION`, etc.
- **Always check `railway variables` to see the actual injected names** — don't assume from the preset label
- **Lesson**: After linking a bucket, run `railway variables | grep AWS` to confirm var names before configuring `storage.yml`

### Active Storage Variant Processing Requires libvips (Feb 13, 2026)
- `image_processing` gem uses `ruby-vips` (libvips) by default in Rails 8.x, not ImageMagick
- Local dev needs `brew install vips` — the Docker image for Railway already includes it
- Variant `.processed` call triggers the actual image transformation — fails at runtime, not at boot
- **Lesson**: Install vips locally before testing variant generation

### BCrypt Digest in Railway Env Vars (Feb 13, 2026)
- BCrypt hashes contain `$` characters (e.g., `$2a$12$...`) which can be stripped or interpreted by shell/env var UIs
- Railway dashboard stripped the `$` signs, leaving a truncated hash that always failed verification
- **Fix**: Generated the digest directly on the Railway container via `bin/rails runner` and pasted the full output into the dashboard
- **Lesson**: After setting a BCrypt digest as an env var, always verify with `puts ENV['VAR_NAME']` on the actual container to confirm `$2a$` prefix is intact

### Super Admin Session Isolation (Feb 13, 2026)
- Super admin and shop admin share the same Rails session (cookie-based)
- `reset_session` on super admin login/logout clears ALL session data, including any concurrent shop admin session
- Acceptable since only the app owner uses both, but worth knowing
- **Lesson**: If multi-user super admin is ever needed, consider separate session stores or token-based auth

### Analytics Namespace Shadowing (Feb 19, 2026)
- Models under `module Analytics` cause `CrawlerDetect` and `DeviceDetector` to resolve as `Analytics::CrawlerDetect` / `Analytics::DeviceDetector`
- Ruby namespace resolution looks inside the current module first, then walks up to top-level
- **Fix**: Use `::CrawlerDetect` and `::DeviceDetector` (leading `::`) to force top-level constant resolution
- **Lesson**: When calling third-party gem constants from inside a custom namespace, always use `::` prefix

### Partitioning is Premature at Low Scale (Feb 19, 2026)
- Initially built `analytics_events` as a PostgreSQL partitioned table (`PARTITION BY RANGE (occurred_at)`) with composite PK `(id, occurred_at)`
- Composite PK breaks Rails conventions: `find(id)` fails, `dependent: :destroy` fails, `destroy!` fails — Rails always uses `WHERE id = ?` which doesn't work on partitioned tables without the partition key
- At current scale (< 1M rows), partitioning adds operational complexity (rake task to create future partitions, `structure.sql` requirement) with zero performance benefit
- **Fix**: Replaced with a regular table, standard integer PK, same columns and indexes
- **Lesson**: Don't partition until you have 100M+ rows and actual query performance issues. Standard indexes + good query patterns handle millions of rows fine.

### "Capture Now or Lose Forever" Pattern (Feb 19, 2026)
- GeoIP (IP→country/city) and UA parsing (user-agent→browser/device) must happen at ingestion time
- IP addresses and raw user-agent strings are not stored (privacy), so you can't backfill geo/device data later
- Similarly, `Analytics::Payment` captures visitor_id/session_id at purchase time — this context is ephemeral (cookies expire, sessions end)
- **Lesson**: If a data point is derivable from ephemeral context, capture it inline at the earliest opportunity. Deferring to a background job risks losing the context.

### sendBeacon Content-Type and CORS (Feb 19, 2026)
- `navigator.sendBeacon` with a `Blob({type: 'text/plain'})` avoids CORS preflight entirely — simple requests don't trigger OPTIONS
- Using `application/json` content type would require a preflight on every page view — significant overhead at scale
- The server parses the body as JSON regardless of Content-Type header
- **Lesson**: For high-volume beacon endpoints, use `text/plain` content type to avoid CORS preflight. Parse body as JSON server-side.

### Hostname Validation Prevents Data Poisoning (Feb 19, 2026)
- Without hostname validation, anyone with a site token (which is public, embedded in the tracking script) can send fake events from any domain
- The ingester now compares the beacon's `hostname` against the registered `site.domain`, stripping `www.` and allowing subdomains
- Empty hostname is allowed (some environments don't set it)
- **Lesson**: Public-token analytics systems need hostname validation — it's the only defense against data pollution

### AuditLog Action Names Must Match ACTIONS Constant (Feb 20, 2026)
- `AuditLog` validates `action` against `ACTIONS` constant (`create`, `update`, `delete`, `view`, `login`, `logout`, `suspend`, `reactivate`, `webhook_receive`, `data_request`, `customer_redact`, `shop_redact`)
- Using Rails-style names like `"destroy"` or custom names like `"create_user"` or `"send_invite"` causes `ActiveRecord::RecordInvalid` — the `audit!` call raises, not the main action
- **Lesson**: Always check the model's validation constant before calling `audit!`. Use generic actions (`create`, `update`, `delete`) with specific details in the JSONB `details` column.

### Ruby Module Inclusion: Class Methods Take Precedence (Feb 20, 2026)
- `include Admin::Impersonatable` in `Admin::BaseController` places concern methods BELOW class methods in the MRO
- If the class defines `require_login` and the concern also defines `require_login`, the class method wins — the concern's version is never called
- **Fix**: Keep the concern for helpers (`impersonating?`, `impersonated_shop`) and `before_action` callbacks only. Integrate impersonation logic directly into the class's existing methods.
- **Lesson**: Concerns can't override methods already defined in the including class. Use `before_action` callbacks or `prepend` instead of `include` if you need to override.

### `perform_enqueued_jobs` Required for `deliver_later` in Request Specs (Feb 20, 2026)
- `deliver_later` enqueues a job but doesn't execute it synchronously — `ActionMailer::Base.deliveries` stays empty
- `include ActiveJob::TestHelper` and wrap assertions in `perform_enqueued_jobs { ... }` to actually run the mailer job
- Alternatively, use `assert_enqueued_emails` to test that the job was enqueued without executing it
- **Lesson**: In request specs testing email delivery, always use `perform_enqueued_jobs` or `assert_enqueued_emails`

### Rendering Manage Template for Unsaved Records Crashes (Feb 20, 2026)
- `render :manage, status: :unprocessable_entity` for a shop that failed validation crashes because:
  - `@shop.created_at` is nil → `strftime` raises NoMethodError
  - Route helpers like `superadmin_shop_path(@shop)` need a persisted record with an id
- **Fix**: Use `redirect_to` with flash alert instead of re-rendering the manage template for failed creates
- **Lesson**: Complex show/manage templates with route helpers and timestamp displays can't render for unpersisted records — redirect on create failure instead

### Active Storage Validators Don't Exist by Default (Feb 24, 2026)
- `validates :image, content_type: {...}, size: {...}` requires the `activestorage-validator` gem — not built into Rails
- Without the gem, Rails raises `Unknown validator: 'ContentTypeValidator'` at class load time
- **Fix**: Use a custom `validate :acceptable_image` method that checks `image.content_type` and `image.byte_size` manually
- **Lesson**: Don't assume Active Storage has built-in content_type/size validators — check the Gemfile before using declarative validation syntax

### ENV.fetch in Service Initializers Breaks Test Stubs (Feb 24, 2026)
- `AnthropicClient.new` uses `ENV.fetch("ANTHROPIC_API_KEY")` in `initialize` — raises `KeyError` before any test stub takes effect
- `allow_any_instance_of(AnthropicClient).to receive(:messages)` stubs the method but the instance must be constructable first
- **Fix**: Set `ENV["ANTHROPIC_API_KEY"] ||= "test-key"` in a `before` block, or use a factory/double instead of real initialization
- **Lesson**: Services with `ENV.fetch` in the constructor need the env var set in specs even when you plan to stub all methods

### Anthropic API Parallel Tool Use Ordering (Feb 24, 2026)
- When Claude calls multiple tools in one response (e.g., `generate_client_brief` + `generate_team_spec`), ALL `tool_result` blocks must be in a SINGLE user message
- `tool_result` blocks must come before any `text` blocks in the user content array
- The full assistant `content` array (text + tool_use blocks) must be stored verbatim in the transcript — don't extract/simplify
- For `ask_question`/`ask_freeform` tools, the user's NEXT message is the tool_result (their answer)
- **Lesson**: Anthropic's tool_use protocol is strict about message ordering — build a proper state machine, don't try to simplify the transcript format

## Patterns & Best Practices

### Alpine.js x-if vs x-show for Layout Restructuring (Feb 10, 2026)
- `x-if` removes elements from DOM entirely — use when an element should not occupy space
- `x-show` hides with `display: none` — use when element participates in flex layout (e.g., progress bar in a flex row)
- When moving an element from conditional to always-visible, switch from `<template x-if>` wrapper to a plain `<div>` (or remove the wrapper entirely)
- For mobile sticky bars: prefer always showing progress/badge with `x-show` toggling only the empty-state message

### Credential Save Pattern for Integrations (Feb 11, 2026)
- Use `Current.shop.shop_credential || Current.shop.build_shop_credential` to find-or-build
- `has_one` + FK constraint prevents duplicates — `build_` is safe
- `save!` will raise if Active Record Encryption env vars are missing (expected in dev without setup)
- Rake tasks that consume credentials should `abort` early with a clear message if key is blank
- `<details>` element is a zero-JS way to toggle inline forms — no Stimulus needed

### Webhook Domain Matching
- Shopify sends `X-Shopify-Shop-Domain` header with real domain on production webhooks
- Always match shop by exact domain, never fall back to first/any shop
- Compliance handlers have secondary lookup from payload `shop_domain` field

### Webhook Signing Secrets (Feb 12, 2026)
- Shopify signs ALL webhooks (including mandatory compliance) with the **app client secret** (`SHOPIFY_CLIENT_SECRET`), not a per-shop or per-webhook secret
- `SHOPIFY_WEBHOOK_SECRET` was a red herring — this env var was never needed
- The `shop_credential.shopify_webhook_secret` DB column is effectively dead; don't store secrets there for Shopify
- Custom platform webhooks use per-shop `webhook_secret` (stored in `shop_credential`) — this is correct for non-Shopify

### Re-creating Shop Records
- Re-installing app via OAuth (`/auth/shopify?shop=domain.myshopify.com`) is cleanest way to recreate shop
- `shop:setup` rake task depends on `SHOPIFY_SHOP_URL` env var which may not be set
- OAuth creates Shop + ShopCredential + User in one transaction

## Config & Environment

### Railway SSH
- `railway ssh --service happypages-app` to get into container
- Rails app lives at `/rails` in container (not `/app`)
- Use `bin/rails console` or `bin/rails runner "..."` from `/rails`
- `railway shell` only injects env vars locally, doesn't SSH into container
- `railway connect` is for databases only

### Shopify CLI Webhooks
- `shopify app webhook trigger --topic <topic> --address <url> --api-version <version>`
- Sends properly signed payloads with sample/fake data
- Test domains use `{shop}.myshopify.com` placeholder
- API version must match TOML config (currently `2026-04`)

### Network Access for Extensions
- Theme extensions making external API calls need "Allow network access" approved in Dev Dashboard
- Deploy will succeed but version won't be released until approved
- Check the version URL in deploy output for approval link

### Session Tokens in Iframes and Third-Party Cookies (Feb 12, 2026)
- Safari blocks third-party cookies by default; Chrome is phasing this in
- The embedded page (`app.happypages.co`) inside the Shopify admin iframe is a third-party context
- Cookies set via fetch inside the iframe may be silently dropped
- The "go to dashboard" link uses `target="_blank"` (first-party context in new tab), which helps
- **Lesson**: Don't rely on iframe-set cookies persisting in Safari — consider token-based auth for cross-context flows

### Hydrogen / Headless Storefront URLs (Feb 13, 2026)
- Hydrogen stores don't use `.myshopify.com` domain or the Shopify Online Store `/discount/` route
- Added optional `storefront_url` to shops table — `customer_facing_url` helper falls back to `https://{domain}`
- All customer-facing URLs (copy-link, back-to-store, config API) go through this helper
- The `/discount/:code` route is a **Shopify Online Store** feature — Hydrogen stores may need a custom route on their end to handle discount codes

### Hidden Form Inputs Still Submit (Feb 13, 2026)
- HTML inputs inside `display: none` containers (CSS `hidden` class, tab panels) are still submitted with the form
- A single `form_with` wrapping two tab panels means clicking either save button submits ALL inputs, including hidden tabs
- In our case, saving the slug card submitted `storefront_url=""` from the hidden Hydrogen tab, and `.presence` converted it to `nil`, wiping the saved value
- **Fix**: Split into two independent `<form>` elements — one per save action. Controller uses `params.key?(:storefront_url)` guard to only touch the field when explicitly submitted.
- **Lesson**: When tabs contain form fields, either use separate forms per tab, or disable/exclude inputs in inactive tabs

### Overwriting Existing Stimulus Controllers (Feb 13, 2026)
- A `tabs_controller.js` already existed with a different API (name-based tabs, `showTab()`, coral colors)
- Copying `superadmin_tabs_controller.js` over it replaced the API entirely
- In this case no breakage occurred because the old controller was dead code (no views referenced it)
- **Lesson**: Before overwriting a controller, grep for `data-controller="<name>"` to check if any views use it

### Active Storage + Stimulus Media Picker Pattern (Feb 13, 2026)
- MediaAsset model owns the metadata (filename, content_type, byte_size); Active Storage `has_one_attached :file` handles the blob
- Variants defined as model methods (`thumbnail_variant`, `referral_banner_variant`) — centralized sizing
- Controller serializes variant URLs via `url_for(asset.variant)` — produces stable `/rails/active_storage/representations/redirect/...` URLs
- Stimulus media picker writes the variant URL to a hidden `<input>` with the same `data-*-target` as the old URL input — existing preview controllers work without changes
- Dispatching `new Event("input", { bubbles: true })` on the hidden field triggers connected Stimulus controllers (save detection, preview update)

### Dead Code in Filename Fallbacks (Feb 16, 2026)
- `ImageryGenerator#store_image` had `processed[:filename] || "generated-#{surface}.webp"` — the fallback is dead code because `post_process` always sets `filename` to `SecureRandom.hex(8).webp`
- A migration backfill using `LIKE 'generated-referral_banner%'` was a no-op because no records ever had that filename pattern
- **Fix**: Removed the dead fallback; simplified migration to column-add only
- **Lesson**: When writing backfill migrations, verify the pattern you're matching actually exists in the data — test with a `SELECT COUNT(*)` first

### Surface Filtering — NULL-Inclusive Scope Pattern (Feb 16, 2026)
- `MediaAsset.for_surface(s)` uses `where(surface: [s, nil])` — this includes untagged assets in every filtered view
- This is intentional: user uploads default to `surface: nil` (appear everywhere), AI-generated images get tagged to a specific surface
- The `og_image` surface has no picker context — it's AI-only, set via `ImageryGenerator`. The referral banner is the OG meta tag fallback.
- Adding a new surface requires changes in 4+ places: `ImageryGenerator::SURFACES`, JS `surfaceForContext()`, controller `surface_from_context`, and model `SURFACES` validation constant

### scroll-snap-stop: always + IntersectionObserver Jiggle (Feb 17, 2026)
- Theme's `.snap-start` utility includes `scroll-snap-stop: always`, forcing programmatic `scrollTo` to pause at every intermediate slide
- An IntersectionObserver tracking 50% visibility fires for each intermediate slide during the scroll animation, updating state and causing thumbnail strip jiggle
- **Fix (CSS)**: Override with `scroll-snap-stop: normal` on the slide elements — manual swipes still snap, but programmatic scroll can skip intermediates
- **Fix (JS)**: Set a guard flag (`_heroScrolling`) in `scrollHeroTo`, cleared after 600ms timeout. Observer ignores index updates while flag is set.
- **Lesson**: When combining scroll-snap galleries with IntersectionObserver, always guard the observer during programmatic scrolls. And check inherited `scroll-snap-stop` values from theme utility classes.

### CSS translateX(100%) References Element's Own Width (Feb 17, 2026)
- `translateX(100%)` in CSS uses the **element's own width**, not the parent's
- A flex container with 12 children has its own width = ~4× the viewport — `translateX(calc(... * 100%))` produces absurdly large values
- **Fix**: Set `width: 100%` on the flex container so `100%` = viewport width. Children with `flex-shrink: 0` overflow as intended, hidden by the viewport's `overflow: hidden`.
- **Lesson**: When using percentage-based `translateX` for sliding viewports, always constrain the sliding element's width to match the viewport

### Alpine Computed Getters vs $watch (Feb 17, 2026)
- `$watch('computedGetter', ...)` can be fragile — Alpine *should* track getter dependencies but the reactivity isn't always reliable
- Replacing mutable state + `$watch` with a computed getter (`get prop()`) is simpler and guaranteed reactive since Alpine re-evaluates getters on dependency change
- The `:style` binding already triggers re-render when the getter's value changes
- **Lesson**: Prefer computed getters over `$watch` when a value is derivable from other state

### Cart Sync Race Condition with AbortController (Feb 19, 2026)
- Background cart syncing (for abandoned cart recovery) can race with checkout — a slow sync response arriving after `window.location` redirect can overwrite the cart
- `AbortController` pattern: store a controller instance, `abort()` it before checkout redirect, pass its `signal` to all sync `fetch()` calls
- Alpine `$watch` is unreliable for object property mutations (e.g., `quantities[id]++`) — call `syncCart()` explicitly in `incrementQty`/`decrementQty`
- **Lesson**: For any fetch-before-navigate pattern, use AbortController to cancel in-flight requests

### ERB Partial Naming: Leading Underscore vs Template (Feb 20, 2026)
- Rails partials must have leading underscore in filename (`_no_site.html.erb`) but are referenced without it (`render "no_site"`)
- Full templates (rendered via `render "setup"` from controller) must NOT have leading underscore
- A 500 error from `render "no_site"` was caused by the file being named `_no_site.html.erb` (partial) when the controller was rendering it as a template
- **Fix**: Renamed to `no_site.html.erb` (no underscore) for template rendering, or use `render partial: "no_site"` for partials
- **Lesson**: If a controller action calls `render "name"`, the file is a template (no underscore). If called via `render partial:`, it needs an underscore.

---
*Updated: Feb 24, 2026 (specs engine: Active Storage validators, ENV.fetch in tests, Anthropic parallel tool_use)*
