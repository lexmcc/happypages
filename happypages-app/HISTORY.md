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

### Jan 28, 2026
- Simplified architecture decision: use single `app.happypages.co` subdomain for both API and dashboard (instead of separate `api.` and `app.` subdomains)
- Merged DNS and Happy Pages integration into single phase in production launch plan
- Phase 1 business setup confirmed complete (UK Ltd formed, bank account open, email configured)
