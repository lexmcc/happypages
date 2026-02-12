# Referrals App Spec

Shopify referral rewards app — merchants install it, customers share referral links, referred orders earn rewards applied automatically.

**Live:** https://app.happypages.co
**Client ID:** `98f21e1016de2f503ac53f40072eb71b` (public distribution, unlisted)

## Architecture

Rails 8.1 + PostgreSQL on Railway. Multi-tenant via `Current.shop` thread-isolated context. Shop lookup from `X-Shop-Domain` header or session user.

### Key Components

- **Shopify OAuth** — self-service install flow, creates Shop + ShopCredential + User in one transaction
- **Checkout UI Extension** — Preact + Polaris thank you page widget showing referral link
- **White-labeled URLs** — `/:shop_slug/refer` routes with auto-generated slugs
- **Webhook pipeline** — `orders/create` triggers referral matching and reward generation, HMAC-verified against `SHOPIFY_CLIENT_SECRET` (Shopify) or per-shop `webhook_secret` (Custom)
- **Encrypted credentials** — Active Record Encryption on all sensitive fields (API keys, tokens, PII)
- **Audit logging** — AuditLog model with JSONB details for compliance events
- **Embedded app page** — `/embedded` loads inside Shopify admin iframe with App Bridge 4.x CDN. Session token (JWT) auth via `POST /embedded/authenticate` — App Bridge auto-injects Bearer token, backend verifies HS256 signature against client secret, validates required claims (exp, nbf, aud, iss↔dest consistency), and establishes cookie session.

### Integrations

- **Awtomic** — subscription management, auto-applies referral rewards to subscriptions. Connect/disconnect flow via admin integrations page. Webhook listener for billing attempt lifecycle.
- **Klaviyo** — email marketing integration (coming soon, card placeholder on integrations page)

### Admin UI

- **Dashboard** — analytics overview with event tracking
- **Referral Page** — configurable customer-facing referral page editor
- **Thank You Card** — checkout extension configuration
- **Integrations** — Awtomic connect/disconnect, Klaviyo (coming soon)
- **Settings** — shop slug management

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
| Medium | Missing DB indices | `analytics_events(shop_id, created_at)`, `discount_configs(shop_id, config_key)` |
| Low | CORS gem included but unconfigured | `rack-cors` in Gemfile, no initializer |
| Low | No rate limiting | Public API endpoints have no throttling |

### Housekeeping
- [ ] Delete old custom distribution app from Partner Dashboard
