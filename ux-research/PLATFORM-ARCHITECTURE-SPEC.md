# Happypages Platform Architecture Spec

## Goal

Evolve Happypages from a Shopify referral app into a platform-agnostic, multi-feature growth toolkit where shops can independently unlock features (referrals, web analytics, CRO, landing pages, etc.), authenticated via email-first identity with Shopify as a "connect" integration rather than the login method.

## Direction Decisions

| Decision | Choice |
|----------|--------|
| Auth model | Email-first. Shopify OAuth is "Connect Shopify," never login. |
| Nav paradigm | "The Linear" — collapsible feature groups in sidebar, built from day 1 |
| Superadmin | 3-layer: shop list → shop management page → impersonation |
| Feature gating | Show don't hide. Locked features visible + muted in sidebar. |
| Onboarding | Invite-only (superadmin creates shop → sends magic link). No focus picker — just land on first enabled feature. |
| Existing shop migration | Auto-migrate: create password-capable User records, move Shopify tokens to ShopIntegration |
| Services workspace | Deferred — not in this phase |
| User:shop model | 1:1 for now |

## Current State (What Exists)

### Models
- **User** — already exists! `email`, `password_digest` (nullable, `has_secure_password validations: false`), `shopify_user_id`, `belongs_to :shop`. Email unique per shop.
- **Shop** — `name`, `domain`, `status`, `platform_type` (shopify/custom/woocommerce), `slug`, `brand_profile` (JSONB), `storefront_url`
- **ShopCredential** — Shopify access token, granted scopes, API keys for custom/Awtomic/Klaviyo. One per shop.

### Auth Flows
- **Admin**: Shopify OAuth → creates Shop + ShopCredential + User → `session[:user_id]` → 24h timeout
- **Superadmin**: env-var BCrypt auth → `session[:super_admin]` → 2h timeout
- **Embedded app**: redirect to main admin UI

### Admin Sidebar (current)
```
Dashboard
────────────
Campaigns
Analytics
────────────  Customize
Thank-You Card
Referral Page
Media
────────────  Connect
Integrations
Settings
────────────
[domain] | Logout
```

---

## Chunk 1: New Data Models + Auth Foundation

### New Models

**ShopFeature** — tracks which features a shop has access to
```ruby
# shop_features
shop_id     :bigint, null: false, index: true
feature     :string, null: false  # "referrals", "analytics", "cro", "insights", etc.
status      :string, null: false, default: "active"  # active, locked, trial, expired
activated_at :datetime
expires_at   :datetime, nullable
# index: [shop_id, feature], unique: true
```

**ShopIntegration** — replaces ShopCredential for multi-provider future
```ruby
# shop_integrations
shop_id      :bigint, null: false, index: true
provider     :string, null: false  # "shopify", "woocommerce", "custom"
status       :string, null: false, default: "active"  # active, expired, revoked
# Shopify-specific
shopify_domain       :string, nullable
shopify_access_token :string, nullable  # encrypted
granted_scopes       :string, nullable
# Generic / future providers
api_endpoint  :string, nullable
api_key       :string, nullable  # encrypted
webhook_secret :string, nullable
# Third-party integrations (move from ShopCredential)
awtomic_api_key      :string, nullable  # encrypted
awtomic_webhook_secret :string, nullable
klaviyo_api_key      :string, nullable  # encrypted
# index: [shop_id, provider], unique: true (one integration per provider per shop)
```

### User Model Changes

Add to existing `users` table:
```ruby
# New columns
role          :string, default: "owner"  # owner, admin, member (future)
invite_token  :string, nullable, index: { unique: true }
invite_sent_at :datetime, nullable
invite_accepted_at :datetime, nullable
last_sign_in_at :datetime, nullable
```

Enable password validations for non-Shopify users (users with no `shopify_user_id` must have a password).

### Migration Steps

**Pre-flight checks** (before any migration runs):
- Check for duplicate emails across shops: `SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1` — resolve collisions before adding global unique index [audit C3]
- Update `shop:cleanup` rake task to check for ShopIntegration OR ShopCredential, so it doesn't delete migrated shops [audit C6]

**Schema migrations**:
1. Create `shop_features` table
2. Create `shop_integrations` table
3. Add new columns to `users` (ensure defaults so `start.sh` slug backfill doesn't crash) [audit H7]

**Data migration** (MUST use ActiveRecord models, not raw SQL — `support_unencrypted_data = false` means encrypted columns are unreadable in SQL) [audit C4]:
4. For each existing Shop, using `ShopCredential.find_each`:
   - Read decrypted values via model, write to new ShopIntegration instance (re-encrypts)
   - Set `ShopIntegration.shopify_domain` = `Shop.domain` (canonical Shopify lookup key) [audit C2]
   - Create ShopFeature records for "referrals" + "analytics" (both active)
   - Ensure User record exists with the shop's email

**Code switchover**:
5. Keep ShopCredential table temporarily (read-only fallback)
6. Update Shop model: `has_many :shop_integrations`, `has_many :shop_features`
7. **Swap all 5 credential accessors** on Shop (`shopify_credentials`, `platform_credentials`, `awtomic_credentials`, `klaviyo_credentials`, `webhook_secret`) to read from ShopIntegration first, fall back to ShopCredential [audit C1]
8. Add `Shop#feature_enabled?(feature_name)` helper
9. Add `Shop#integration_for(provider)` helper
10. Add `Shop.find_by_shopify_domain(domain)` helper for webhook/API lookups [audit C2]

**Last step** (separate migration, after ALL code is switched):
11. Drop `shop_credentials` table — only after zero code references remain [audit H6]

### Key Files to Modify

42 `shop_credential` references across 13 files — complete list [audit C1]:

**Models** (core):
- `app/models/shop.rb` — new associations + helpers + credential accessor swap (8 refs)
- `app/models/user.rb` — role, invite columns, password validation logic
- New: `app/models/shop_feature.rb`
- New: `app/models/shop_integration.rb`

**Controllers**:
- `app/controllers/shopify_auth_controller.rb` — create ShopIntegration instead of (in addition to) ShopCredential (3 refs)
- `app/controllers/admin/integrations_controller.rb` — read from ShopIntegration (2 refs)
- `app/controllers/superadmin/shops_controller.rb` — read from ShopIntegration (1 ref)

**Services**:
- `app/services/brand_scraper.rb` — read from ShopIntegration, guard with `shop.shopify?` [audit H4] (1 ref)

**Views**:
- `app/views/admin/integrations/edit.html.erb` — read from ShopIntegration (1 ref)

**Tasks/scripts**:
- `lib/tasks/shop_setup.rake` — update setup, info, and cleanup tasks (6 refs) [audit C6]
- `start.sh` — ensure slug backfill tolerates new validations [audit H7]

**Docs** (update references):
- `LEARNINGS.md`, `docs/plans/multi-tenant.md`, `docs/plans/integration-onboarding-wizard.md`

---

## Chunk 2: Email Login + Invite Flow

### Email Login

**Note**: This is a full page rebuild + net-new controller action. The existing login page is 100% Shopify OAuth (no email/password form), and `SessionsController` has no `create` action at all. [audit C5, H1]

New login page at `/login`:
- Email + password form (primary)
- "Install via Shopify" link (secondary — for shops that need to connect Shopify first)
- No social OAuth buttons yet

`SessionsController#create` (net-new):
- Find User by email (globally unique)
- Verify password via `has_secure_password` / `authenticate_by`
- Rate limit login attempts (rack-attack already exists, add rule) [audit M7]
- Set `session[:user_id]`, redirect to `/admin`
- Also rate limit `/invite/:token` endpoint to prevent brute-force token guessing

### Invite Flow

**Superadmin side** (on shop management page):
1. Click "Send invite" for a shop
2. System generates `invite_token` on the User record
3. Sends email with magic link: `/invite/:token`

**Owner side**:
1. Click link in email → `/invite/:token`
2. **Screen 1**: "Set your password" (email pre-filled, read-only)
3. On submit: set `password_digest`, clear `invite_token`, set `invite_accepted_at`
4. Auto-login → redirect to `/admin`

### Shopify OAuth Rework

Shopify OAuth no longer creates accounts. It connects an integration:

- **If user is logged in**: "Connect Shopify" from settings/feature prompt → OAuth → creates ShopIntegration → returns to where they were
- **If user is NOT logged in**: Shopify OAuth callback creates/updates Shop + ShopIntegration + User (backwards compat for Shopify app install flow) → logs them in

This preserves the existing install-via-Shopify flow while making email login the primary path.

### Session Management

**Warning**: `reset_session` destroys ALL session keys — including `session[:super_admin]` and the planned `session[:impersonating_shop_id]`. Both logout and OAuth session-fixation protection currently use `reset_session`. [audit C7]

Approach: Use selective key management instead of blanket `reset_session` where possible. On user logout, clear only `session[:user_id]`. On impersonation exit, clear only `session[:impersonating_shop_id]`. Reserve `reset_session` for security-critical flows (OAuth callback, password change).

### Key Files
- `app/controllers/sessions_controller.rb` — full rebuild: add `create` action with password verification + rate limiting [audit C5]
- New: `app/controllers/invites_controller.rb` — handle invite token
- `app/controllers/shopify_auth_controller.rb` — dual-mode: logged-in = connect, not-logged-in = create. `valid_shopify_domain?` stays Shopify-specific (correct) [audit H8]
- `app/views/sessions/new.html.erb` — full rebuild (currently 100% Shopify) [audit H1]
- New: `app/views/invites/show.html.erb` — password setup page
- New: `app/mailers/invite_mailer.rb`
- `config/initializers/rack_attack.rb` — add login + invite rate limit rules

---

## Chunk 3: Collapsible Sidebar + Feature Gating UI

### New Sidebar Structure

```
[HP logo] happypages
[Shop name]
─────────────────────────
  Home
─────────────────────────
▼ Analytics                    [active]
    Dashboard
    Real-time
    Reports
▼ Referrals                    [active]
    Dashboard
    Links & Codes
    Rewards
    Settings
─────────────────────────
  CRO                         [locked]
  Customer Insights            [locked]
  Landing Pages                [locked]
  Ad Manager                   [locked]
  Ambassadors                  [locked]
─────────────────────────
  Settings
─────────────────────────
[domain] | Logout
```

### Behavior
- **Active features**: Collapsible groups, expanded by default, click chevron to collapse
- **Locked features**: Single line, 60% opacity, lock icon. Click → feature preview page
- **Locked section**: Auto-collapses when shop has 5+ active features
- **Persistence**: Collapse state saved in localStorage
- **Home page**: With 1 feature, shows that feature's dashboard. With 2+, shows overview cards from each.

### Feature Preview Pages
When clicking a locked feature, navigate to `/admin/features/:feature_name`:
- One-line description
- Screenshot or illustration
- "Contact us to unlock" CTA (for invite-only phase) — later becomes "Upgrade" with Stripe
- Shareable URL

### Sidebar Component
- Reads `ShopFeature` records to determine what to show
- Groups features by status (active vs locked)
- Each active feature defines its sub-nav items (hardcoded mapping, not dynamic)

**Note**: The existing sidebar is 120 lines of entirely hardcoded static links with zero feature gating — this is a from-scratch rewrite, not a modification. The existing `sidebar_controller.js` only handles mobile hamburger toggle; a new Stimulus controller is needed for collapse/expand. [audit H2, L1]

### Key Files
- `app/views/admin/shared/_sidebar.html.erb` — full rewrite (no existing infrastructure to build on)
- New: `app/helpers/sidebar_helper.rb` or `app/models/concerns/feature_navigation.rb` — feature → nav items mapping
- New: `app/controllers/admin/features_controller.rb` — preview pages
- New: `app/views/admin/features/show.html.erb` — preview page template
- New: `app/javascript/controllers/sidebar_collapse_controller.js` — collapse/expand Stimulus controller
- `app/assets/stylesheets/` or inline styles — collapsible group CSS

---

## Chunk 4: Superadmin — Shop Management Page

### Three-Layer Superadmin

**Layer 1: Shop List** (`/superadmin`) — already exists, enhance:
- Add search
- Add status filters (All / Active / Needs Attention / Suspended)
- Each row: shop name, domain, status, key metric, "Manage →" button
- "Needs attention" = open issues, failed generations, stale analytics

**Layer 2: Shop Management Page** (`/superadmin/shops/:id/manage`) — NEW:
- **Create shop form**: Name, domain (website URL), platform_type, storefront_url [audit M10]. This is the ONLY non-Shopify shop creation path — ShopifyAuthController only creates Shopify shops [audit H3]
- Shop overview card (name, domain, status, created date)
- **Features panel**: Toggle features on/off, set status (active/trial/expired)
- **Users panel**: List users, send invites, reset passwords
- **Integrations panel**: View connected integrations (Shopify domain, status)
- **Usage panel**: Key metrics (referrals, analytics events, etc.)
- **Payments panel**: Placeholder for future billing
- **"View as shop owner →"** button: enters impersonation
- Gate Shopify-only UI (customer import, brand scrape trigger) behind `shop.shopify?` [audit M3, H4]

**Layer 3: Impersonation** — see Chunk 5

### Key Files
- `app/controllers/superadmin/shops_controller.rb` — add `manage` action
- New: `app/views/superadmin/shops/manage.html.erb`
- `app/controllers/superadmin/shops_controller.rb` — add feature toggle actions
- New: `app/controllers/superadmin/shop_features_controller.rb` — CRUD for features
- New: `app/controllers/superadmin/shop_users_controller.rb` — user management + invite sending
- `app/views/superadmin/shops/index.html.erb` — enhance with search + filters

---

## Chunk 5: Superadmin Impersonation

### Mechanism
- Session-based: `session[:impersonating_shop_id]`
- New concern: `Admin::Impersonatable` mixed into `Admin::BaseController`
- When impersonating: `Current.shop` set from `session[:impersonating_shop_id]` instead of `current_user.shop`
- `impersonating?` helper available to all admin views
- Audit all actions with `actor: "super_admin_impersonating"` (existing AuditLog schema supports this) [audit L2]
- **Session key management**: Never use `reset_session` during impersonation — it destroys all session state. Clear only `session[:impersonating_shop_id]` on exit [audit C7]

### Banner
- 40px fixed bar at top of admin layout, slate background (#1e293b)
- Content: `Viewing "Shop Name" as shop owner [Switch shop ▼] [Superadmin] [Exit]`
- "Switch shop" — dropdown with shop search
- "Superadmin" — opens `/superadmin` in new tab
- "Exit" — clears `session[:impersonating_shop_id]`, returns to `/superadmin/shops/:id/manage`
- 4-hour session limit

### Entry Points
- "View as shop owner →" button on shop management page
- Future: Cmd+K command palette with shop search

### What Gets Replaced
- Delete: `superadmin/web_analytics` controller + views
- Simplify: shop detail page becomes the shop management page (Chunk 4)
- All per-shop data viewing now happens through impersonation

### Permissions During Impersonation
- **Full access**: View and edit everything the shop owner can
- **Restricted** (confirmation dialog): Activate/deactivate campaigns, trigger brand scrape
- **Blocked**: Delete shop, change auth, compliance actions, customer-facing emails

### Key Files
- New: `app/controllers/concerns/admin/impersonatable.rb`
- `app/controllers/admin/base_controller.rb` — include concern
- `app/views/admin/shared/_impersonation_banner.html.erb` — new partial
- `app/views/layouts/admin.html.erb` — add conditional render slot for impersonation banner above main content [audit H5]
- New: `app/controllers/superadmin/impersonations_controller.rb` — create/destroy impersonation sessions
- `app/controllers/webhooks_controller.rb` — update `set_shop_from_webhook` to use `Shop.find_by_shopify_domain` instead of `Shop.find_by(domain:)` [audit C2]
- `app/controllers/concerns/shop_identifiable.rb` — update API domain lookup for non-Shopify shops [audit M1]
- Delete: `app/controllers/superadmin/web_analytics_controller.rb` + views

---

## Implementation Order

```
Chunk 1: Data models + migration     ← foundation, everything depends on this
  ↓
Chunk 2: Email login + invite flow   ← new auth system, can test end-to-end
  ↓
Chunk 3: Collapsible sidebar + gating ← visible UX change, uses ShopFeature from Chunk 1
  ↓
Chunk 4: Superadmin shop management   ← uses ShopFeature for toggle UI
  ↓
Chunk 5: Impersonation               ← depends on admin views being feature-aware (Chunk 3)
```

Chunks 3 and 4 could be parallelized since they touch different parts of the app (admin sidebar vs superadmin views).

## Resolved Questions

1. **Email uniqueness**: Globally unique. Migration: replace `index_users_on_shop_id_and_email` with `index_users_on_email` (unique). One email = one account. Multi-shop ownership comes later. **Audit note**: Must check for existing duplicates before migration — see pre-flight checks in Chunk 1 [audit C3].

2. **ShopCredential deprecation**: Keep for 1 sprint after ShopIntegration is live, then drop. **Audit note**: Drop must be the LAST step — 42 references across 13 files need updating first. `shop:cleanup` rake task must be updated before migration or it will delete valid shops [audit C1, C6, H6].

3. **Referral analytics**: Both. Summary metrics in Referrals > Dashboard. Deep referral analytics also accessible under Analytics group as a sub-tab.

4. **Non-Shopify domain**: Use the shop's website URL (e.g., `oatcult.com`). Domain field stays NOT NULL. **Audit note**: `ShopIntegration.shopify_domain` must be the canonical Shopify lookup key for webhooks and API calls. `Shop.domain` can diverge from Shopify domain for non-Shopify shops [audit C2].

5. **Feature enum values**: `referrals`, `analytics`, `cro`, `insights`, `landing_pages`, `funnels`, `ads`, `ambassadors`

## Open Questions

1. **Home dashboard KPIs**: With 2 features active, what shows on Home? Proposal: top referrals + top pages + recent activity.

2. **ShopCredential deprecation timeline**: Exact sprint to drop?

## Verification

After each chunk:
- **Chunk 1**: `rails console` — verify ShopFeature and ShopIntegration records exist for all shops. Existing admin flow still works unchanged.
- **Chunk 2**: Can login with email/password. Can send invite from superadmin. Invited user can set password and access admin. Shopify OAuth still works for connecting.
- **Chunk 3**: Sidebar shows collapsible groups. Locked features show preview pages. Nav items match ShopFeature records.
- **Chunk 4**: Superadmin can search shops, toggle features, send invites from shop management page.
- **Chunk 5**: Can impersonate from shop management page. Banner visible. Can switch shops. Exit returns to superadmin. Actions are audit-logged.

## References

### UX Research

Full research reports in `ux-research/`:
- `01-platform-nav-patterns.md` — sidebar paradigms, locked feature patterns
- `02-auth-onboarding-patterns.md` — auth architecture, onboarding flows
- `03-superadmin-services-patterns.md` — impersonation, services workspace (deferred)

### Engineering Audit

- **[`PLATFORM-ARCH-AUDIT.md`](./PLATFORM-ARCH-AUDIT.md)** — Full audit findings (28 issues: 7 critical, 8 high, 10 medium, 3 low). Annotations throughout this spec reference audit IDs like `[audit C1]`, `[audit H3]`, etc. — see the audit doc for full details, impact analysis, and fix descriptions.
