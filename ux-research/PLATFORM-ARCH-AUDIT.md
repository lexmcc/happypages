# Platform Architecture Spec — Audit Findings

**Date**: 2026-02-20
**Scope**: Audited `PLATFORM-ARCHITECTURE-SPEC.md` against the existing codebase at `happypages-app/`.
**Method**: 4 read-only investigators examined ~50 files across models, controllers, views, jobs, rake tasks, and config.
**Result**: 28 unique issues (7 CRITICAL, 8 HIGH, 10 MEDIUM, 3 LOW)

---

## Tier 1 — CRITICAL

### C1. ShopCredential blast radius underestimated

**Location**: 42 occurrences across 13 files (spec lists only 5 key files)

Files with `shop_credential` references:
- `app/models/shop.rb` (8 refs — 5 credential accessor methods)
- `app/controllers/shopify_auth_controller.rb` (3 refs)
- `app/controllers/admin/integrations_controller.rb` (2 refs)
- `app/controllers/superadmin/shops_controller.rb` (1 ref)
- `app/services/brand_scraper.rb` (1 ref)
- `app/views/admin/integrations/edit.html.erb` (1 ref)
- `lib/tasks/shop_setup.rake` (6 refs — setup, info, cleanup tasks)
- `db/schema.rb` (3 refs)
- `db/migrate/20260126100001_create_shop_credentials.rb` (1 ref)
- `db/migrate/20260216100000_add_granted_scopes_to_shop_credentials.rb` (1 ref)
- `LEARNINGS.md` (3 refs)
- `docs/plans/multi-tenant.md` (9 refs)
- `docs/plans/integration-onboarding-wizard.md` (3 refs)

**Impact**: Missing any reference means broken credential reads post-migration. Shop's 5 credential accessors (lines 33-66) return `nil` silently, disabling features without errors.

**Fix**: Spec needs a complete migration checklist. Swap Shop's 5 credential accessors to read from ShopIntegration first, fall back to ShopCredential during transition.

### C2. Domain identity collision

**Location**: `shop.rb:36`, `webhooks_controller.rb:68`, `shop_identifiable.rb`, `db/schema.rb:329`

`Shop.domain` serves three roles simultaneously:
1. Shopify API URL (`shopify_credentials` returns `{ url: domain }`)
2. Webhook shop lookup key (`Shop.find_by(domain:)` from `X-Shopify-Shop-Domain` header)
3. Database uniqueness key (`index_shops_on_domain`, unique: true)

Spec proposes non-Shopify shops use their website URL (e.g., `oatcult.com`) for `domain`. But existing Shopify shops use `store.myshopify.com` as their domain — changing semantics breaks API calls and webhook routing.

**Impact**: Shopify API calls get wrong URL. Webhook lookups fail (Shopify sends `.myshopify.com` in headers, but domain might now be the website URL).

**Fix**: `ShopIntegration.shopify_domain` must be the canonical Shopify lookup key. `Shop.domain` can be the website URL. Add `Shop.find_by_shopify_domain(d)` helper for webhook/API lookups. ShopIntegration already has `shopify_domain` in the spec — just ensure webhook controller uses it.

### C3. Email uniqueness migration failure risk

**Location**: `db/schema.rb:463` — current index: `[shop_id, email] UNIQUE`. Spec wants `[email] UNIQUE` (globally).

If two shops share an email address, the migration adding the global unique index will crash.

**Impact**: Migration failure in production.

**Fix**: Add pre-migration check:
```sql
SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;
```
Resolve collisions before adding the global unique index. Migration should be two-step: (1) check + report, (2) add index only if clean.

### C4. Encrypted column migration must use ActiveRecord models

**Location**: `shop_credential.rb:5-8`, `config/initializers/active_record_encryption.rb`

ShopCredential encrypts tokens with Active Record Encryption (`support_unencrypted_data = false`). Data migration MUST use model-level reads, not raw SQL.

**Impact**: `INSERT INTO shop_integrations SELECT ... FROM shop_credentials` copies encrypted blobs literally — the new model can't decrypt them. Silent data corruption.

**Fix**: Migration must:
1. Use `ShopCredential.find_each` to read decrypted values
2. Write to `ShopIntegration` model instances (which re-encrypt with new config)
3. Never use raw SQL for token columns

### C5. SessionsController#create doesn't exist

**Location**: `sessions_controller.rb:1-22`

The controller only has `new` (renders page) and `destroy`. There is no `create` action — no email/password authentication logic exists anywhere in the codebase.

**Impact**: Spec says "add email/password login" — but this is a net-new controller action. Needs: password verification, rate limiting, error handling, session management, account lockout.

**Fix**: Spec should call this out as a full build, not a modification. rack-attack already exists for rate limiting.

### C6. `shop:cleanup` rake task deletes migrated shops

**Location**: `lib/tasks/shop_setup.rake:104-128`

```ruby
shops_with_creds = Shop.joins(:shop_credential).pluck(:id)
orphans = Shop.where.not(id: shops_with_creds)
orphans.destroy_all
```

After migration, if ShopCredential is removed before this task is updated, ALL shops get deleted.

**Impact**: Data destruction if anyone runs `rails shop:cleanup` after migration.

**Fix**: Update to check for ShopIntegration OR ShopCredential. Or deprecate the task before migration.

### C7. `reset_session` destroys impersonation state

**Location**: `sessions_controller.rb:12-14`, `shopify_auth_controller.rb:88`

`reset_session` wipes ALL session keys including `session[:super_admin]` and the planned `session[:impersonating_shop_id]`. Both logout and OAuth session fixation protection use `reset_session`.

**Impact**: Impersonation silently ends on any session reset. A superadmin re-authenticating via OAuth while impersonating loses their impersonation context.

**Fix**: Impersonation entry/exit must manage session keys explicitly. Consider: save impersonation state before `reset_session`, restore after. Or use selective key clearing instead of `reset_session` where possible.

---

## Tier 2 — HIGH

### H1. Login page is 100% Shopify

**Location**: `app/views/sessions/new.html.erb`

Only renders a Shopify OAuth button. No email/password form exists. This is a full page rebuild, not a tweak.

### H2. Sidebar is entirely hardcoded

**Location**: `app/views/admin/shared/_sidebar.html.erb` (120 lines of static links)

No feature gating, no collapsible groups, no dynamic nav. Zero existing infrastructure to build on — Chunk 3 is a from-scratch rewrite.

### H3. No alternative shop/user creation flow

**Location**: `shopify_auth_controller.rb:68-117`

ShopifyAuthController is the ONLY code path for creating shops and users. Chunk 2 (invite flow) and Chunk 4 (superadmin management) both need new creation flows that bypass Shopify OAuth.

**Fix**: Add to Chunk 4: superadmin create-shop form that creates Shop + User without OAuth.

### H4. BrandScrapeJob is Shopify-locked

**Location**: `app/services/brand_scraper.rb` (references `shop_credential`)

Uses `shopify_credentials` to call Shopify API for product data. Non-Shopify shops will crash.

**Fix**: Guard with `shop.shopify?` check, or make brand scraping provider-aware.

### H5. Admin layout has no impersonation banner slot

**Location**: `app/views/layouts/admin.html.erb`

No yield area or conditional render slot for a top-bar. Chunk 5 needs a 40px fixed bar.

**Fix**: Add conditional render area above main content.

### H6. FK ordering risk for ShopCredential drop

**Location**: `db/schema.rb:485` — `add_foreign_key "shop_credentials", "shops"`

Table drop order matters. ShopCredential can only be dropped after ALL code references are removed and FK constraints won't block.

**Fix**: Spec correctly says "keep temporarily" — add explicit note that table drop is the LAST step, in a separate migration after all code is switched.

### H7. `start.sh` slug backfill could crash after migration

**Location**: `start.sh:17` — `Shop.where(slug: nil).find_each(&:save!)`

Triggers all validations. If new User columns add validations that aren't satisfied, `save!` fails on boot.

**Fix**: Ensure new columns have defaults, or use `update_column(:slug, ...)` for slug backfill.

### H8. `valid_shopify_domain?` enforcement

**Location**: `shopify_auth_controller.rb:150-152`

Enforces `.myshopify.com` regex. Not a bug — this is correct for Shopify-only OAuth. But spec should note this stays Shopify-specific; the new "Connect Shopify" flow (Chunk 2) reuses it.

---

## Tier 3 — MEDIUM

### M1. ShopIdentifiable domain lookup may break

**Location**: `app/controllers/concerns/shop_identifiable.rb`

API auth via `X-Shop-Domain` header against `Shop.domain`. If domain semantics change for non-Shopify shops, API controllers won't find them.

### M2. Provider classes read tokens from ShopCredential

**Location**: `shop.rb:136-137`

`Providers::Shopify::*` classes instantiated via `provider_class` call `shop.shopify_credentials` → `shop_credential`. Part of C1 — credential accessor swap fixes this.

### M3. CustomerImportJob is Shopify-only

Non-Shopify shops shouldn't see the import UI. Gate behind `shop.shopify?`.

### M4. Webhook signature verification assumes Shopify

**Location**: `webhooks_controller.rb:82-83`

Falls back to `ENV["SHOPIFY_CLIENT_SECRET"]` when no shop found. Works today but needs updating for multi-provider webhooks.

### M5. User role column default not set by ShopifyAuthController

Spec says default "owner" — existing users get it automatically, but ShopifyAuthController should explicitly set role on new user creation.

### M6. `shop_setup.rake` hardcodes platform_type: "shopify"

Only useful for Shopify shops. Needs platform_type param for non-Shopify.

### M7. No rate limiting on invite endpoints

rack-attack exists but invite flow is net-new. Add rate limit for `/invite/:token` to prevent brute-force token guessing.

### M8. Stimulus controllers are clean (positive finding)

`analytics_chart`, `analytics_sparkline`, `analytics_filter` — no Shopify assumptions. No issues.

### M9. No test suite visible

No automated tests found. Migration confidence is lower without ability to verify correctness.

### M10. `storefront_url` not mentioned in spec

Used for `customer_facing_url`. Non-Shopify shops should set this during onboarding.

---

## Tier 4 — LOW

### L1. Sidebar Stimulus controller only handles mobile toggle

Must add new controller for feature group collapse/expand. Part of Chunk 3.

### L2. AuditLog schema supports impersonation actor strings

Existing `actor` string field works for `"super_admin_impersonating"`. No changes needed.

### L3. `tabs_controller.js` shared between admin and superadmin

May need updates if superadmin management page uses tabs. Existing controller is reusable.

---

## Summary by Chunk

| Chunk | Critical | High | Medium | Notes |
|-------|----------|------|--------|-------|
| 1: Data Models | C1, C3, C4, C6 | H6, H7 | M2, M5, M6, M9 | Most findings here — migration is the riskiest chunk |
| 2: Email Login | C5, C7 | H1, H3, H8 | M7 | Net-new builds underestimated |
| 3: Sidebar | — | H2 | M8 | Clean rewrite, no hidden risks |
| 4: Superadmin | — | H3 | M3, M10 | Needs create-shop form |
| 5: Impersonation | C2, C7 | H5 | M1, M4 | Domain identity + session management |
