# Project History

A chronicle of the referral app's evolution from initial commit to production-ready multi-tenant platform.

## Timeline

### Week 1: Foundation (Jan 8-13, 2026)

- **Jan 8** - Checkout extension on thank you page with personalized customer names
- **Jan 9** - Rails backend with PostgreSQL database
- **Jan 13** - Referral code generation and webhook-triggered rewards
- **Jan 13** - Admin UI for extension and discount configuration

### Week 2: Polish & UI Overhaul (Jan 14-21, 2026)

- **Jan 14** - Neumorphic design system with live preview and undo support
- **Jan 14** - Analytics dashboard with event tracking
- **Jan 21** - Shared discount architecture with generations and scheduled boosts
- **Jan 21** - Configurable referral page with admin UI

### Week 3: Integrations (Jan 22-23, 2026)

- **Jan 22** - Awtomic subscription integration with auto-applied rewards
- **Jan 23** - Klaviyo integration for referral lifecycle events
- **Jan 23** - Duplicate reward prevention and expiration handling
- **Jan 23** - Reward status display on customer referral page

### Week 4: Scale & Production (Jan 26+, 2026)

- **Jan 26** - Multi-tenant architecture with encrypted credentials and provider pattern
- **Jan 26** - Self-service onboarding via Shopify OAuth
- **Jan 29** - Railway deployment: Rails + PostgreSQL at app.happypages.co
- **Jan 29** - White-labeled referral URLs with auto-generated shop slugs

### Week 5: PII Compliance & App Distribution (Feb 6, 2026)

- **Feb 6** - PII compliance: encryption, audit logging, privacy policy
- **Feb 6** - Compliance webhooks with HMAC verification
- **Feb 6** - Public distribution Shopify app for multi-merchant installs
- **Feb 6** - Data protection questionnaire submitted

### Week 6: Oatcult Shop Page Polish + Integrations (Feb 10-11, 2026)

- **Feb 10** - Mobile sticky basket fixes: full-width slots, progress bar + badge always visible, scroll no longer closes drawer
- **Feb 11** - Awtomic API key connect/disconnect flow on integrations page

### Week 7: Security Hardening + Embedded Auth + Hydrogen Readiness (Feb 12-13, 2026)

- **Feb 12** - Fixed webhook HMAC validation to reject invalid signatures (Shopify app check compliance)
- **Feb 12** - App Bridge + session token auth on embedded page for Shopify automated checks
- **Feb 12** - Security audit: hardened JWT verification (required claims, iss↔dest validation, domain checks)
- **Feb 13** - Hydrogen readiness: storefront URL setting, API base controller, rate limiting, GET referral endpoint
- **Feb 13** - Media upload & image management: admin media library, inline media pickers on editors, Railway Bucket (Tigris) storage with automatic WebP variant generation
- **Feb 13** - Super admin dashboard: `/superadmin` with shop list, detail tabs, suspend/reactivate, audit logging, env-var BCrypt auth
- **Feb 13** - Tabbed theme integration UI with Hydrogen discount route snippet for headless stores

### Week 8: AI Imagery Pipeline + Tooling (Feb 14-16, 2026)

- **Feb 14** - Brand scraper + AI imagery generator: automatic brand analysis on install, Gemini-powered marketing image generation for three surfaces
- **Feb 14** - SolidQueue for background jobs, superadmin prompt template & scene asset management
- **Feb 16** - Surface-filtered media pickers: each admin tab shows only relevant images (referral banner / extension card)
- **Feb 16** - 3-layer CLAUDE.md architecture: global rules, project context, session memory separated

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
