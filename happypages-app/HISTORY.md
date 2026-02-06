# Project History

A chronicle of the referral app's evolution from initial commit to production-ready multi-tenant platform.

## Timeline

### Week 1: Foundation (Jan 8-13, 2026)

- **Jan 8** - Project inception: "It Works" checkout extension displayed on thank you page
- **Jan 8** - Watch Now button and refer-a-friend card with personalized customer names
- **Jan 9** - Rails backend added with PostgreSQL database
- **Jan 9** - Shipping address fallback for guest checkout
- **Jan 9** - Referral system core documented
- **Jan 13** - Webhook registration and referrer rewards system
- **Jan 13** - Customer-specific rewards with customer notes
- **Jan 13** - Automatic referral code creation from customer data
- **Jan 13** - Admin UI for extension and discount configuration
- **Jan 13** - Network access enabled for checkout extension
- **Jan 13** - Loading states with skeleton placeholders
- **Jan 13** - CORS configuration for API endpoints

### Week 2: Polish & UI Overhaul (Jan 14-21, 2026)

- **Jan 14** - Responsive two-column layout with live preview
- **Jan 14** - Action buttons in header with spinner and success tooltip
- **Jan 14** - Analytics dashboard with event tracking
- **Jan 14** - Top navigation tabs
- **Jan 14** - Neumorphic design with coral accent colors
- **Jan 14** - Variable insertion buttons for {discount} and {reward}
- **Jan 14** - Auto-expanding textareas
- **Jan 14** - Floating sticky action buttons with full undo support
- **Jan 14** - Documentation checkpoint skill created
- **Jan 21** - Shared discount architecture for mass updates
- **Jan 21** - Discount groups with generations and scheduled boosts
- **Jan 21** - Configurable referral page with admin UI
- **Jan 21** - 16:9 banner aspect ratio
- **Jan 21** - Responsive two-column grid layout
- **Jan 21** - Validation for discount value fields

### Week 3: Integrations (Jan 22-23, 2026)

- **Jan 22** - Awtomic subscription integration
- **Jan 22** - Auto-applying referrer rewards to subscriptions
- **Jan 22** - Subscription eligibility settings
- **Jan 22** - Retry logic with delay for discount code application
- **Jan 22** - Detailed logging for API responses
- **Jan 22** - GID and numeric format handling for Awtomic API
- **Jan 22** - Reward lifecycle tracking system
- **Jan 23** - Klaviyo integration for event tracking
- **Jan 23** - Profile sync and nurture flow support
- **Jan 23** - Duplicate reward prevention from webhook retries
- **Jan 23** - Delayed job for subscription reward application
- **Jan 23** - Reward expiration checks
- **Jan 23** - Configurable subscription pause behavior
- **Jan 23** - Reward status display on customer referral page

### Week 4: Scale & Production (Jan 26+, 2026)

- **Jan 26** - Shop and ShopCredential models for multi-tenancy
- **Jan 26** - Active Record encryption for credentials
- **Jan 26** - Current.shop thread-isolated context
- **Jan 26** - Provider pattern for platform abstraction (Shopify, Custom, WooCommerce)
- **Jan 26** - Refactored webhooks and API controllers
- **Jan 26** - Auto shop setup from ENV on first deployment
- **Jan 26** - Self-service onboarding via Shopify OAuth
- **Jan 26** - Session management with 24-hour timeout
- **Jan 28** - White-labeled URL configuration planned
- **Jan 28** - Integration onboarding wizard planned
- **Jan 28** - Production launch planning and roadmap
- **Jan 28** - Production launch Phase 1 complete (UK Ltd, bank, email)
- **Jan 28** - Happy Pages integration added to production plan
- **Jan 28** - Consolidated DNS to single subdomain (app.happypages.co)
- **Jan 29** - Railway deployment complete: Rails app + PostgreSQL at app.happypages.co
- **Jan 29** - Shopify extension deployed and released (version 7)
- **Jan 29** - OAuth redirect URLs fixed (shopify.app.*.toml configuration)
- **Jan 29** - Railway multi-service configuration (separate railway.toml per service)
- **Jan 29** - First successful OAuth installation on dev store
- **Jan 29** - White-labeled URLs: shop-specific referral pages (/:shop_slug/refer)
- **Jan 29** - Auto-generated slugs with backfill for existing shops
- **Jan 29** - Database startup improvements: db:prepare + slug backfill in start.sh

### Week 5: PII Compliance & App Distribution (Feb 6, 2026)

- **Feb 6** - PII compliance implementation: privacy policy, audit logging, Active Record Encryption on email/first_name
- **Feb 6** - Compliance webhooks: customers/data_request, customers/redact, shop/redact with HMAC verification
- **Feb 6** - SSL and host authorization enabled in production
- **Feb 6** - Critical bug fix: removed Shop.active.first fallback that let test webhooks delete real shop data
- **Feb 6** - Recreated Shopify app with public distribution (custom distribution can't install on non-Plus stores)
- **Feb 6** - New client_id: 98f21e1016de2f503ac53f40072eb71b (old: a0199e1c2d876f0982e33fb33a1d1c0a)
- **Feb 6** - Data protection questionnaire submitted, protected customer data access requested
- **Feb 6** - All webhooks deployed and released (orders/create + 3 compliance topics)
- **Feb 6** - App re-installed on dev store with new credentials, verified working

## Key Milestones

1. **First checkout extension working** - Jan 8: "It Works" thank you page displayed
2. **First referral code generated** - Jan 13: Automatic code creation from customer data
3. **First webhook processed** - Jan 13: Order webhook triggers referrer rewards
4. **Admin UI live preview** - Jan 14: Real-time preview with undo functionality
5. **Neumorphic design system** - Jan 14: Coral accents, shadows, modern aesthetic
6. **First Awtomic reward applied** - Jan 22: Subscription discount auto-applied
7. **First Klaviyo event tracked** - Jan 23: Referral lifecycle events flowing
8. **Multi-tenant architecture complete** - Jan 26: Platform-agnostic, encrypted credentials
9. **Self-service OAuth onboarding** - Jan 26: Merchants can install independently
10. **Production deployment** - Jan 29: Rails app live at app.happypages.co with PostgreSQL
11. **PII compliance complete** - Feb 6: Encryption, audit logs, compliance webhooks, privacy policy
12. **Public distribution app** - Feb 6: Recreated app for multi-merchant installs

## Architecture Evolution

```
Week 1: Monolith
├── Single shop, hardcoded credentials
├── Direct Shopify API calls
└── Basic webhook handling

Week 2-3: Feature-Rich Monolith
├── Admin UI with live preview
├── Awtomic + Klaviyo integrations
└── Sophisticated reward lifecycle

Week 4: Multi-Tenant Platform
├── Shop model with encrypted credentials
├── Provider pattern (Shopify/Custom/WooCommerce)
├── OAuth-based self-service onboarding
└── Thread-isolated shop context
```

## Session Notes

_This section is updated by the doc-checkpoint skill at the end of each working session._

### Feb 6, 2026
- **Critical bug**: `Current.shop ||= Shop.active.first` fallback in `set_shop_from_webhook` caused test compliance webhooks (with fake `{shop}.myshopify.com` domain) to match the real shop. The `shop/redact` handler then called `shop.destroy!`, cascade-deleting all data. Fix: removed fallback entirely, webhooks now only match by exact domain.
- **Shopify distribution is permanent**: Can't change Custom → Public. Had to create a new app entirely.
- **Protected customer data chicken-and-egg**: Can't deploy `orders/create` or compliance webhooks until protected data access is approved. Workaround: deploy without webhooks first, request access, then re-deploy with webhooks.
- **Network access approval**: Theme extensions making external API calls need network access approved in Dev Dashboard before the version can be released.
- **Railway SSH path**: The Rails app lives at `/rails` in the container, not `/app`. Use `cd /rails && bin/rails console`.
- **Re-installing the app via OAuth** is the cleanest way to recreate shop records (rather than `shop:setup` which depends on `SHOPIFY_SHOP_URL` env var).

### Jan 28, 2026
- Simplified architecture decision: use single `app.happypages.co` subdomain for both API and dashboard (instead of separate `api.` and `app.` subdomains)
- Merged DNS and Happy Pages integration into single phase in production launch plan
- Phase 1 business setup confirmed complete (UK Ltd formed, bank account open, email configured)

### Jan 29, 2026
- **Railway Deployment Complete**: Rails backend deployed with PostgreSQL, all environment variables configured
- **Shopify OAuth Working**: Fixed redirect URL configuration - the linked TOML file (`shopify.app.happypages-friendly-referrals.toml`) was using defaults instead of custom URLs
- **Multi-Service Railway Config**: Two services from same repo require separate `railway.toml` files with `watchPatterns` to trigger correct deploys
- **Gotcha**: Railway services may reference secrets from other services in same project - adding dummy values unblocks builds
- **Login redirect bug fixed**: `sessions_controller.rb` was redirecting to non-existent `admin_config_path` instead of `edit_admin_config_path`
- **White-labeled URLs implemented**: Shop-specific referral URLs (e.g., `/happypages-test-store/refer`) fix multi-tenant bug where `/refer` had no shop context
- **Slug auto-generation**: `before_validation :generate_slug` creates URL-safe slugs from shop name; runs on every save (not just create) to backfill existing shops
- **Railway database gotcha**: Railway UI may show "no tables" even when tables exist - use `rails runner` to verify actual table count
- **db:prepare vs db:migrate**: Use `db:prepare` in production startup scripts - it handles both empty databases (schema load) and existing ones (migrate)
