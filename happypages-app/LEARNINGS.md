# Project Learnings

Detailed learnings, gotchas, and session discoveries. Claude reads this when working on related areas.

## Gotchas & Bug Fixes

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

---
*Updated: Feb 11, 2026*
