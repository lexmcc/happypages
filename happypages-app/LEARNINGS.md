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

---
*Updated: Feb 13, 2026*
