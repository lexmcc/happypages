# Auth, Onboarding & Feature Gating: UX Research Report

> Research for Happypages platform evolution from Shopify-only referral app to platform-agnostic multi-feature growth toolkit.

---

## 1. Reference Analysis

### Stripe

**Auth model:** Email + password as the primary method. SSO (SAML 2.0) available for teams. Multiple identity providers can coexist per organization, with per-domain configuration (required, optional, or disabled). No social login (Google/GitHub) for merchant accounts -- this is deliberate. Stripe's identity layer is serious, not casual.

**Onboarding:** Stripe pioneered incremental (progressive) onboarding. Their Connect platform explicitly offers two strategies:
- **Upfront onboarding**: Collect all `eventually_due` requirements at signup. Longer initial flow, but no interruptions later.
- **Incremental onboarding**: Collect only `currently_due` requirements. Fast initial setup, but requires re-engaging users later to collect deferred information.

The key insight: Stripe lets the *platform* choose which strategy to use. They don't force one pattern. Requirements have states (`currently_due`, `eventually_due`, `past_due`) that drive the UI. This maps directly to Happypages -- features have states (available, locked, needs-connection).

**Feature gating:** Stripe doesn't gate features behind tiers in the traditional SaaS sense. Instead, they gate behind *completion*. You can see your dashboard immediately, but you can't process payments until you've finished verification. The dashboard shows what you *could* do, with clear prompts about what's missing. Empty states are opportunities, not dead ends.

**What to steal:** The progressive requirement model. Don't block the user from seeing the product. Let them in immediately, then prompt for what's needed when they try to *use* a feature that requires more context (like Shopify OAuth for referrals).

---

### Railway

**Auth model:** Originally GitHub-only (tight 1:1 account link). Added email login as a fallback. The tight GitHub coupling caused pain when GitHub auth went down -- users couldn't log in at all. Railway has been slowly relaxing this, but the 1:1 model creates friction for users with multiple identities.

**Onboarding:** Minimal. After auth, you land on an empty dashboard with a prominent "New Project" button. Railway trusts that their users (developers) know what they want. The onboarding is the *doing* -- deploy something, see it work.

**What to steal:** The confidence to show an empty dashboard with a single clear action. Railway's post-auth experience is: "Here's your workspace. Here's one button. Go." No wizard, no tutorial, no 7-step setup. For Happypages' invite-only phase, this simplicity is perfect -- the superadmin already knows what the shop needs.

**What to avoid:** The tight 1:1 auth provider coupling. Railway's GitHub-only approach caused real problems. Happypages should treat auth providers as linkable identities from the start, not as the account itself.

---

### Linear

**Auth model:** Google SSO or email + password. Workspace-level email domain auto-join -- anyone with a matching company email can join the workspace without an invitation. Manual invites also available with team pre-assignment.

**Onboarding:** This is the gold standard for focused onboarding.
- One input per step. Never two.
- Dark mode preference *before* account details (respects the user's environment first).
- Keyboard shortcut tutorial (teaches the interaction model early).
- Invite teammates step (built into the flow, not an afterthought).
- GitHub integration step (connecting an external service as a natural part of setup, not a separate settings page).

Linear's onboarding was designed end-to-end, not screen-by-screen. The sequence tells a story: "This is your workspace. This is how you'll interact with it. These are the people you'll work with. Here's how your tools connect."

**What to steal:** One input per step. The "connect an external service" as a natural onboarding step (maps to "Connect Shopify" for Happypages). Email domain auto-join for when Happypages eventually supports teams. The dark mode moment -- asking about preferences before asking about the product shows you care about the person, not just the account.

---

### Attio

**Auth model:** Google account or email + temporary password. Work email required (no personal Gmail/Hotmail). This is an intentional friction point -- it filters for serious business users.

**Onboarding:** Use-case-driven from the first screen.
- "What's your primary use case?" customizes the workspace during signup.
- Email and calendar connection happens early (this is Attio's version of "connect your data source").
- Workspace is pre-populated with enriched data from connected accounts within minutes.
- Six optional getting-started guides available post-setup, explorable at user's pace.
- Full setup in 15-30 minutes.

The key pattern: Attio asks *what you want to do* before asking *who you are*. The use-case selection drives the workspace template, so the user sees a relevant workspace immediately -- not a blank canvas.

**What to steal:** The use-case-first onboarding question. For Happypages, this maps to: "What brings you here? Referrals / Analytics / CRO / All of the above." The answer drives which features are highlighted in the dashboard, which empty states are shown, and which setup steps are prioritized.

---

### Skio

**Auth model:** This is the most relevant reference for Happypages. Skio is a Shopify app with a standalone identity system:
- **Merchant admin**: Separate Skio admin portal at `skio.com`, independent of Shopify admin.
- **Customer portal**: Passwordless login (SMS or email 4-digit code) at `/a/account/login` on the merchant's domain.
- **Shopify integration**: Multipass (Shopify Plus only) or embedded login link for seamless handoff between Shopify accounts and Skio portal.

Skio solves exactly the problem Happypages faces: they need Shopify OAuth for store integration, but their admin portal is a separate product. The merchant logs into Skio independently. The Shopify connection is a *configuration step*, not the auth method.

**What to steal:** The separation of identity from integration. Skio merchants don't "log in with Shopify." They log into Skio, and separately connect their Shopify store. This is the exact model Happypages should adopt. Email-based auth for the account. Shopify OAuth as "Connect your Shopify store" -- a settings action, not a login action.

---

### Vercel

**Auth model:** "Continue with GitHub", "Continue with GitLab", "Continue with Bitbucket", "Continue with Email". Multiple providers, one account. The primary identity is the email address. Auth providers are just ways to prove you own that email.

**Team management:** Teams are separate from personal accounts. Git provider connections happen at the team level. You can connect different git providers to different teams.

**Known pain point:** Vercel struggles with users who have multiple GitHub accounts. The 1:1 mapping between a Vercel account and a GitHub account creates friction for developers with work + personal GitHub accounts. This is a cautionary tale for Happypages.

**What to steal:** "Continue with [Provider]" as a UI pattern. The email address as the canonical identity, with OAuth providers as authentication methods (not identity sources). The team/personal account separation (maps to Happypages' future multi-shop support).

**What to avoid:** The tight 1:1 provider-to-account coupling. If a Happypages user has two Shopify stores, they should be able to connect both without creating two accounts.

---

### PostHog

**Auth model:** Self-hosted or cloud. Cloud uses email + password or Google SSO.

**Feature gating / billing:** This is PostHog's standout pattern. Every module has its own billing meter:
- Product Analytics: own free tier, own usage meter
- Session Replay: own free tier, own usage meter
- Feature Flags: own free tier, own usage meter
- Experiments: billed under Feature Flags
- Surveys: own free tier
- Data Warehouse: own free tier

Each product is independently activatable. You can use analytics heavily while ignoring session replay. Billing is purely usage-based -- no seats, no tiers, no "Pro vs Enterprise" gating. You pay for what you use per product.

**What to steal:** Per-feature independent activation and billing. This is exactly what Happypages needs. Each feature (referrals, analytics, CRO, etc.) should have its own activation state, its own setup flow, and eventually its own billing meter. The "all features available from day one" approach with a generous free tier removes the need for upgrade prompts during onboarding -- the user discovers value before hitting a paywall.

---

## 2. Proposed Auth Architecture

### Core Principle: Identity is Not Integration

The single most important architectural decision: **separate the user's identity from their platform integrations.**

- **Identity** = email address + auth method (email/password, Google SSO, future providers)
- **Integration** = Shopify OAuth, WooCommerce API key, custom site snippet (these are shop-level connections, not user-level auth)

This means:
- A user logs in with email/password or Google SSO
- A user *connects* their Shopify store via OAuth (settings action)
- A user *connects* their WooCommerce store via API key (settings action)
- A user can have multiple integrations per shop (Shopify + custom analytics site)
- Shopify OAuth is never the login method -- it's the "unlock Shopify features" method

### Auth Methods (Priority Order)

**Phase 1 -- Invite-Only (Now)**
1. **Email + magic link**: Superadmin creates shop, enters owner email. Owner receives invite email with magic link. First click sets up their account (name, password). Subsequent logins via email/password.
2. **Shopify OAuth as integration**: After logging in, owner can "Connect Shopify" from settings or from a feature that requires it (referrals, theme extensions).

**Phase 2 -- Self-Serve (Later)**
3. **Email + password signup**: Open registration from pricing page. Checkout creates the account.
4. **Google SSO**: "Continue with Google" on login/signup. Matched by email address to existing accounts.

**Phase 3 -- Enterprise (Future)**
5. **SAML SSO**: Per-organization, for agency/enterprise customers managing multiple shops.

### Data Model

```
User
  - email (canonical identity, unique)
  - name
  - password_digest (nullable -- magic link users set this on first login)
  - auth_provider (enum: email, google, saml)
  - auth_provider_uid (nullable -- for OAuth/SAML)

Shop
  - name
  - slug
  - owner_id -> User
  - plan / subscription info

ShopIntegration
  - shop_id -> Shop
  - provider (enum: shopify, woocommerce, custom)
  - credentials (encrypted -- access token, API key, etc.)
  - shopify_domain (for Shopify integrations)
  - status (enum: active, expired, revoked)

ShopFeature
  - shop_id -> Shop
  - feature (enum: referrals, analytics, cro, insights, landing_pages, ...)
  - status (enum: active, locked, trial, expired)
  - activated_at
  - requires_integration (enum: shopify, woocommerce, null)
```

### Auth Flow Diagrams

**Invite-Only Flow:**
```
Superadmin creates shop + enters owner email
  -> System sends invite email with magic link
  -> Owner clicks link -> lands on "Set up your account" page
  -> Name + password (one input per step, Linear-style)
  -> "What brings you here?" (Attio-style use-case picker)
  -> Dashboard (with relevant empty states based on use-case)
  -> Feature card says "Connect Shopify to get started" (if referrals selected)
```

**Self-Serve Flow (Future):**
```
Visitor lands on pricing page
  -> Selects plan/features -> Checkout (Stripe)
  -> Account created with email from checkout
  -> "Set your password" email
  -> Same onboarding as above (name -> use-case -> dashboard)
```

**Shopify OAuth Connect Flow:**
```
User is logged in -> clicks "Connect Shopify" (from settings or feature prompt)
  -> Redirect to Shopify OAuth consent screen
  -> Shopify redirects back with auth code
  -> System creates ShopIntegration record
  -> Shopify-dependent features unlock immediately
  -> User returns to where they were (not dumped on a settings page)
```

---

## 3. Onboarding Flow Proposals

### 3a. Invite-Only Flow (Near-Term)

This is the highest-priority flow. It needs to work before anything else.

**Step 1: Superadmin creates the shop**
- Superadmin enters: shop name, owner email, initial features to activate
- System generates: shop slug, ShopFeature records, invite email

**Step 2: Owner receives invite email**
- Subject: "You're invited to Happypages"
- Body: Brief value prop + prominent CTA button
- Links to: `/invite/:token` (one-time use, 7-day expiry)

**Step 3: Account setup (3 screens, one input each)**

Screen 1: "What's your name?"
- Single text input: full name
- Pre-filled email (from invite, read-only)
- "Continue" button

Screen 2: "Set a password"
- Single password input with strength indicator
- "Continue" button

Screen 3: "What's your focus?" (only if multiple features activated)
- Cards for each activated feature: Referrals, Analytics, CRO, etc.
- Pick one as primary (this drives the dashboard default view)
- "Get started" button

**Step 4: Dashboard**
- Primary feature is expanded/highlighted
- Other activated features visible but secondary
- Locked/unactivated features shown as greyed cards with "Coming soon" or "Upgrade to unlock"
- If primary feature requires Shopify: prominent "Connect your Shopify store" card replaces the feature's empty state

**Why this works:**
- 3 screens, under 60 seconds total
- No decisions that feel consequential (you can change everything later)
- The use-case question is *after* identity setup, so it feels like personalization, not qualification
- The dashboard is immediately useful (even if just analytics with a tracking snippet)

### 3b. Self-Serve Flow (Future)

**Step 1: Pricing page**
- Feature cards with independent pricing (PostHog model)
- "Start with [feature]" buttons on each card
- Bundle discounts visible but not pushed

**Step 2: Checkout**
- Stripe Checkout session
- Email collected here becomes the account email
- Payment success -> account created -> "Set your password" email sent

**Step 3: Onboarding**
- Same 3-screen flow as invite-only (name -> password -> focus)
- But the "focus" step is pre-selected based on what they purchased
- Dashboard shows purchased features as active, others as upgrade opportunities

### 3c. Shopify OAuth Flow (Integration, Not Entry Point)

This is critical: Shopify OAuth is *never* the way you create an account. It's always a secondary action.

**Trigger points (when the user encounters "Connect Shopify"):**

1. **Settings > Integrations**: Dedicated integrations page with "Connect Shopify," "Connect WooCommerce" (future), etc.

2. **Feature empty state**: When user clicks into Referrals but hasn't connected Shopify:
   ```
   ┌────────────────────────────────────────┐
   │  Referrals need a Shopify connection    │
   │                                         │
   │  To track referrals and reward          │
   │  customers, connect your Shopify store. │
   │                                         │
   │  [Connect Shopify]                      │
   │                                         │
   │  Not on Shopify? [Learn about other     │
   │  platforms] (links to waitlist/docs)    │
   └────────────────────────────────────────┘
   ```

3. **Onboarding step** (if referrals selected as primary focus):
   After the 3-screen setup, a 4th screen appears:
   "Connect your Shopify store to start tracking referrals"
   [Connect Shopify] | [I'll do this later]
   "I'll do this later" goes to dashboard with the prompt still visible.

**Connect flow:**
```
User clicks "Connect Shopify"
  -> Modal or page: "Which store?" (enter myshopify.com domain) -- skip if only one store
  -> Redirect to Shopify OAuth
  -> Shopify redirects back
  -> ShopIntegration created
  -> Feature unlocked with success toast
  -> Redirect back to the feature they were trying to use
```

The "redirect back to where they were" is crucial. Stripe does this well -- after completing a verification step, you land back where you left off, not on a generic dashboard.

---

## 4. Feature Gating UX

### 4a. How Locked Features Appear

Three states for features in the UI:

**Active**: Full access. The feature section in the nav is a normal link. Dashboard card shows live data or a setup wizard.

**Available but not set up**: The feature is included in the shop's plan but hasn't been configured yet. Nav link is normal. Dashboard card shows an actionable empty state:
```
┌─────────────────────────────────────────┐
│  📊 Web Analytics                        │
│                                          │
│  Add the tracking script to your site    │
│  to start collecting data.               │
│                                          │
│  [View setup instructions]               │
└─────────────────────────────────────────┘
```

**Locked (not in plan)**: The feature is visible but inaccessible. Nav link is dimmed with a lock icon or "upgrade" badge. Dashboard card shows value prop + upgrade path:
```
┌─────────────────────────────────────────┐
│  🎯 CRO Tools                    PRO    │
│                                          │
│  A/B test your pages, optimize           │
│  checkout flows, and increase            │
│  conversion rates.                       │
│                                          │
│  [Upgrade to unlock]                     │
└─────────────────────────────────────────┘
```

**Key principle: locked features are visible, not hidden.** The user should see what they're missing. This is the Stripe pattern -- show the dashboard with all possible sections, but prompt for completion/upgrade where needed. Never hide a feature the user doesn't have -- that's how you lose upsell opportunities and make the product feel smaller than it is.

### 4b. Upgrade Prompt Patterns

**Inline prompt (preferred)**: When the user clicks a locked feature in the nav, don't show a generic "upgrade" page. Show the feature's actual UI in a read-only/preview state with a banner:
```
┌──────────────────────────────────────────────────┐
│  ⚡ This feature is available on the Growth plan  │
│  [See pricing]  [Start free trial]               │
└──────────────────────────────────────────────────┘
```

Below the banner, show a demo/preview of what the feature looks like with data. Use sample data, not a blank page. This is the "show, don't tell" approach.

**Usage-based prompt**: For features with free tiers, let the user hit the limit naturally:
```
┌──────────────────────────────────────────────────┐
│  You've used 950 of 1,000 free analytics events  │
│  this month. Upgrade to keep tracking.           │
│  [Upgrade]  [Learn more]                         │
└──────────────────────────────────────────────────┘
```

**Never use modals for upgrade prompts.** Modals feel like ads. Banners feel like information.

### 4c. The "Connect Shopify to Unlock" Moment

This is a special case of feature gating. The feature is in the user's plan, but it requires a platform integration to function.

**Pattern: Contextual integration prompt**

When the user navigates to a Shopify-dependent feature without a Shopify connection:

1. Show the feature's UI shell (nav, tabs, layout)
2. Replace the content area with:
   ```
   ┌─────────────────────────────────────────┐
   │  Connect your Shopify store             │
   │                                         │
   │  Referrals integrates with Shopify to   │
   │  track purchases and reward customers   │
   │  automatically.                         │
   │                                         │
   │  [Connect Shopify store]                │
   │                                         │
   │  Takes about 30 seconds. We'll request  │
   │  access to orders and customers.        │
   └─────────────────────────────────────────┘
   ```

3. After connecting, the page reloads with the actual feature content.

**Why show the UI shell:** It reduces anxiety. The user can see the tabs, the navigation, the structure of what they're about to use. They're not connecting Shopify into a void -- they're connecting it into a visible destination.

---

## 5. Progressive Disclosure: Dashboard Evolution

### Single-Feature User

The simplest case. If a shop has only analytics activated:

```
┌──────────────────────────────────────────────────────────┐
│  Happypages                              Shop: Oatcult   │
├──────────────┬───────────────────────────────────────────┤
│              │                                           │
│  Dashboard   │  [Analytics Dashboard - full width]       │
│  Analytics   │                                           │
│  Settings    │  KPIs, charts, pages, referrers           │
│              │                                           │
│  ─────────── │                                           │
│  Explore     │                                           │
│  Referrals 🔒│                                           │
│  CRO      🔒│                                           │
│  Insights 🔒│                                           │
│              │                                           │
└──────────────┴───────────────────────────────────────────┘
```

- The sidebar has one active section (Analytics) and locked sections below a divider
- Locked sections use subtle lock icons, not aggressive "UPGRADE" badges
- "Explore" is the upgrade discovery area -- clicking shows all features with previews

### Multi-Feature User

When a shop has referrals + analytics + CRO:

```
┌──────────────────────────────────────────────────────────┐
│  Happypages                              Shop: Oatcult   │
├──────────────┬───────────────────────────────────────────┤
│              │                                           │
│  Dashboard   │  [Overview cards for each active feature] │
│              │                                           │
│  Referrals   │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  Analytics   │  │Referrals │ │Analytics │ │   CRO    │ │
│  CRO         │  │ 24 refs  │ │ 1.2k vis │ │ 3 tests  │ │
│  Settings    │  └──────────┘ └──────────┘ └──────────┘ │
│              │                                           │
│  ─────────── │  [Recent activity feed]                   │
│  Explore     │                                           │
│  Insights 🔒│                                           │
│              │                                           │
└──────────────┴───────────────────────────────────────────┘
```

- The Dashboard becomes an overview page with summary cards per feature
- Each feature gets its own nav section
- The nav order reflects the user's primary focus (selected during onboarding)

### The "Explore" Section

This replaces a traditional "pricing" or "upgrade" page. It lives in the sidebar as a soft discovery point.

```
Explore
├── All features (grid view with cards per feature)
├── Each card shows:
│   ├── Feature name + one-line description
│   ├── "Active" badge (if enabled) or "Available" badge
│   ├── Preview screenshot
│   └── [Learn more] or [Activate] button
```

This follows the PostHog model: all features visible, independently activatable, no artificial tier bundling.

---

## 6. Recommendation: The Auth/Onboarding Architecture

### The Architecture

**Email-first identity, provider-linked integrations, feature-level activation.**

1. **Auth layer**: Email + password (magic link for invites, password set on first login). Google SSO as a convenience method (Phase 2). SAML for enterprise (Phase 3). The canonical identity is always the email address.

2. **Integration layer**: Shopify OAuth, WooCommerce API, custom site snippet -- all at the shop level, not the user level. Stored as `ShopIntegration` records. Multiple integrations per shop supported.

3. **Feature layer**: Each feature independently activated per shop. Some features require integrations (referrals requires Shopify), others don't (analytics works with a JS snippet on any site). Feature activation drives nav structure, dashboard layout, and available actions.

### Why This Architecture

**It doesn't need rebuilding when you go self-serve.** The invite flow creates a User + Shop + ShopFeatures. The self-serve flow creates a User + Shop + ShopFeatures. Same data model, different entry point. The only difference is who triggers the creation (superadmin vs checkout).

**It doesn't lock you into Shopify.** A WooCommerce shop and a Shopify shop are the same `Shop` record with different `ShopIntegration` records. Features that work with any platform (analytics, landing pages) don't care about integrations at all.

**It supports the "connect later" pattern.** A user can sign up, explore the analytics dashboard, import some data, and *then* connect Shopify when they're ready for referrals. No premature OAuth flows, no wasted Shopify app installs.

**It maps to PostHog-style independent billing.** Each `ShopFeature` can have its own billing meter, free tier, and upgrade path. No tier matrix. No "you need Pro to get analytics + referrals." Just activate what you need.

### Implementation Priority

1. **Now**: Add email/password auth alongside existing Shopify OAuth. Make Shopify OAuth create a `ShopIntegration` rather than being the identity. Existing Shopify-installed shops get migrated: create a User record with their shop email, create a ShopIntegration record from their existing credentials.

2. **Next**: Build the invite flow. Superadmin creates shop + owner -> invite email -> account setup -> dashboard. This is the primary onboarding path for the near term.

3. **Later**: Self-serve checkout. Stripe Checkout -> account creation -> same onboarding flow. Feature page replaces "Explore" section with pricing.

4. **Eventually**: Google SSO, team/multi-user support, SAML. These are additive -- they don't change the core architecture.

### The Feeling to Aim For

The goal is Stripe's confidence + Linear's focus + PostHog's modularity.

**Stripe's confidence**: Show everything upfront. Don't hide features. Trust the user to understand "this is available, this needs setup, this needs an upgrade." Progressive requirements, not progressive concealment.

**Linear's focus**: One thing at a time during onboarding. Never two inputs on one screen. Respect the user's preferences (theme, primary feature) before asking them to do work.

**PostHog's modularity**: Features are independent. Billing is per-feature. Activation is per-feature. The user builds their own product by choosing what to enable. No monolithic tiers.

The worst possible outcome is a Shopify app that feels like it only works with Shopify. The best possible outcome is a growth toolkit that *also* works with Shopify when you need it to.

---

## Sources

- [Stripe Connect Onboarding Configuration](https://docs.stripe.com/connect/onboarding)
- [Stripe Embedded Onboarding](https://docs.stripe.com/connect/embedded-onboarding)
- [Stripe SSO Documentation](https://docs.stripe.com/get-started/account/sso)
- [Stripe Apps Onboarding Patterns](https://docs.stripe.com/stripe-apps/patterns/onboarding-experience)
- [Railway OAuth Documentation](https://docs.railway.com/integrations/oauth/creating-an-app)
- [Railway Login & Tokens](https://docs.railway.com/integrations/oauth/login-and-tokens)
- [Linear Invite Members](https://linear.app/docs/invite-members)
- [Linear Members & Roles](https://linear.app/docs/members-roles)
- [Linear Onboarding Analysis (Growth Dives)](https://www.growthdives.com/p/the-onboarding-linear-built-without)
- [Linear FTUX Breakdown (fmerian)](https://fmerian.medium.com/delightful-onboarding-experience-the-linear-ftux-cf56f3bc318c)
- [Attio Sign-In Documentation](https://attio.com/help/reference/account-settings/signing-into-attio)
- [Attio SSO Documentation](https://attio.com/help/reference/workspace-settings-billing/single-sign-on)
- [Attio CRM Setup Guide](https://www.superbcrew.com/how-to-use-attio-crm-step-by-step-guide/)
- [Skio Customer Login Options](https://help.skio.com/docs/choosing-your-customer-login-experience-in-skio)
- [Skio Multipass Setup](https://help.skio.com/docs/multipass)
- [Vercel Account Management](https://vercel.com/docs/accounts)
- [Vercel Team Member Management](https://vercel.com/docs/rbac/managing-team-members)
- [PostHog Pricing Guide (Flexprice)](https://flexprice.io/blog/posthog-pricing-guide)
- [PostHog Analytics Review (Userpilot)](https://userpilot.com/blog/posthog-analytics/)
- [PLG Feature Gating Guide (PricingSaaS)](https://substack.pricingsaas.com/p/your-guide-to-plg-feature-gating)
- [Feature Gating Strategies (Arkahna)](https://blog.arkahna.io/unlocking-scalability-with-smart-feature-gating-strategies)
- [SaaS Upgrade Prompt UI Examples (SaaSFrame)](https://www.saasframe.io/patterns/upgrade-prompt)
- [Multi-Tenant SaaS Guide (Logto)](https://logto.medium.com/build-a-multi-tenant-saas-application-a-complete-guide-from-design-to-implementation-d109d041f253)
- [SaaS Auth Best Practices (Descope)](https://www.descope.com/blog/post/saas-auth)
- [B2B SaaS Architecture Patterns (Appfoster)](https://medium.com/appfoster/architecture-patterns-for-saas-platforms-billing-rbac-and-onboarding-964ea071f571)
- [B2B SaaS UX Design 2026 (Onething)](https://www.onething.design/post/b2b-saas-ux-design)
- [Login & Signup UX Guide (Authgear)](https://www.authgear.com/post/login-signup-ux-guide)
- [Empty States in Onboarding (UserOnboard)](https://www.useronboard.com/onboarding-ux-patterns/empty-states/)
