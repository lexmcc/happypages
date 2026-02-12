# Changelog

Dated record of shipped features across both products.

## 2026-02-12

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
