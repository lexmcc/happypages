# Platform Navigation Patterns: UX Research Report

**Date:** 2026-02-20
**Purpose:** Inform Happypages platform navigation architecture as it evolves from single Shopify referral app to multi-feature ecommerce growth toolkit.

---

## 1. Reference Analysis

### Linear (linear.app)

**Nav paradigm:** Workspace > Team > Feature hierarchy with an inverted-L chrome (sidebar + top bar).

**Sidebar structure:**
- Top: workspace switcher (multiple workspaces per account)
- Global views: Inbox, My Issues, Views, Initiatives
- Per-team sections: Issues (with workflow states), Projects, Cycles, Triage, Views
- Teams are collapsible groups in the sidebar; sub-teams nest beneath parents
- Bottom: Settings, help

**What works well:**
- The sidebar mirrors organizational structure directly -- teams own issues, projects span teams. The nav *is* the mental model.
- Keyboard-first design (Cmd+K command palette, shortcuts for every action) means power users rarely touch the sidebar at all.
- Density is high but hierarchy is clear: bold team names, indented feature sections, muted icons.
- Views (saved filters) appear inline with first-class nav items, so custom workflows don't require leaving the standard structure.

**What doesn't work:**
- At scale (10+ teams), the sidebar gets long. Linear mitigates with collapsible sections but it can still feel like a wall of text.
- The team-centric model doesn't map perfectly to products that aren't team-organized (e.g., a solo founder using Happypages wouldn't have "teams").
- No concept of locked/disabled features -- everything in your plan is just there.

**Key takeaway:** The sidebar *is* the information architecture. No separation between "navigation" and "structure." This only works when the product's conceptual model is clean and hierarchical.

---

### Shopify Admin

**Nav paradigm:** Unified vertical sidebar with flat-ish category grouping.

**Sidebar structure:**
- Home (overview dashboard)
- Orders, Products, Customers, Content, Finances, Analytics, Marketing, Discounts
- Apps section (installed apps appear as nav items)
- Settings (at bottom)
- Apps get their own internal navigation (up to 7 items visible, overflow into "View more")

**What works well:**
- Incredibly consistent. Every Shopify merchant, regardless of store size, gets the same nav structure. Predictability over customization.
- Apps integrate *into* the sidebar as first-class citizens but with their own internal nav, so the core structure stays clean even as merchants install 20+ apps.
- Object-oriented labeling (nouns: Orders, Products, Customers) keeps cognitive load low.
- Mobile-responsive: sidebar becomes bottom nav on small screens.

**What doesn't work:**
- The flat structure doesn't scale well conceptually for multi-product suites. Shopify's answer is "apps have their own nav" which fragments the experience.
- No concept of progressive disclosure based on plan tier -- it's all or nothing. Features missing from your plan simply aren't there.
- Settings is a catch-all dumping ground with 20+ subpages.
- No favorites, no customization, no personalization.

**Key takeaway:** Shopify proves that a simple, flat, noun-based sidebar works beautifully for a *single product* with clear object types. The apps-as-nav-items pattern is relevant for Happypages's modular features.

---

### Stripe Dashboard

**Nav paradigm:** Product-sectioned sidebar with progressive disclosure.

**Sidebar structure:**
- Home (customizable widget dashboard)
- Shortcuts (pinned + recent pages)
- Core data: Balances, Transactions, Customers, Product catalog
- Products section: Payments, Billing, Connect, Reporting (always visible)
- "More +" expander: Workflows, Tax, Identity, Atlas, Issuing, Financial Connections, Capital, Climate
- Developers section
- Settings

**What works well:**
- The "Shortcuts" section is genius -- it acknowledges that different users access different parts of Stripe, so let them pin what matters. This is far better than trying to predict the right default hierarchy.
- Progressive disclosure via "More +" keeps the sidebar manageable. Core products are always visible; niche products are one click away but not cluttering the view.
- The Home page is a customizable dashboard (add/remove/rearrange widgets), so it serves as both overview and launcher.
- Product-specific settings are accessed within each product section, not in a monolithic settings page.
- Clean visual hierarchy: section headers are subtle, icons are minimal, density is high without feeling cramped.

**What doesn't work:**
- The "More +" bucket is a known UX anti-pattern (out of sight, out of mind). Users forget about features hidden there.
- No visual distinction between products you actively use and ones you've never touched -- they all look the same in the sidebar.
- The distinction between "core data" (Balances, Transactions) and "products" (Payments, Billing) isn't immediately obvious to new users.

**Key takeaway:** Stripe's Shortcuts + progressive disclosure + customizable Home is the strongest model for a multi-product platform. The "More" bucket problem is solvable with better feature-state signaling.

---

### Attio (attio.com)

**Nav paradigm:** Workspace-centric sidebar with six distinct sections.

**Sidebar structure:**
1. Control panel: workspace switcher, settings, team invites, sign out
2. Quick access: Cmd+K command palette, search
3. Navigation panel: Home, Notifications, Tasks, Notes, Emails, Calls, Reports, Automations, Sequences, Workflows
4. Records: all CRM record types (People, Companies, Deals, custom objects)
5. Lists: user-created and shared lists
6. Chats: AI conversation history (Ask Attio)

Sidebar is collapsible. Favorites section with folder organization.

**What works well:**
- Favorites with folders is powerful -- users build their own nav structure on top of the standard one. This is the Notion/workspace model applied to CRM.
- Clear separation between "navigation" (what you do) and "records" (what you look at) is cognitively clean.
- Custom objects appear in the sidebar automatically, so the nav grows with configuration without requiring admin layout work.
- The expandable/collapsible sidebar with hover-to-peek respects screen real estate.

**What doesn't work:**
- Six sidebar sections is a lot. New users face decision paralysis about where to look.
- The "everything is customizable" philosophy means no two Attio instances look the same, which hurts tribal knowledge and onboarding.
- No clear feature gating story -- Attio is priced per-seat, not per-feature, so they don't face the locked feature problem.

**Key takeaway:** Favorites-as-personal-nav and custom objects as dynamic nav items are both patterns worth stealing. The six-section sidebar is too many sections.

---

### Skio (skio.com)

**Nav paradigm:** Standard Shopify embedded app sidebar with flat feature list.

**Sidebar structure (from docs and changelogs):**
- Dashboard (overview with MRR, subscribers, revenue breakdown)
- Subscribers, Subscriptions, Orders
- Products > Selling Plans
- Analytics (V3 dashboard with Net Sub/Subscriber Change)
- Settings, Integrations
- API access
- Help / Documentation links

Collapsible sidebar redesigned in recent updates.

**What works well:**
- Simple, predictable, follows Shopify conventions. Merchants who use Shopify admin feel immediately at home.
- Overview dashboard as home page gives quick health check before diving into details.
- Flat structure is appropriate for a focused, single-purpose app (subscriptions).

**What doesn't work:**
- No progressive disclosure -- every feature visible at all times, which only works because the feature set is small.
- No customization, no shortcuts, no favorites.
- Doesn't have a multi-product navigation problem to solve.

**Key takeaway:** Skio validates that for a single-feature app, a flat sidebar with a dashboard home is the right call. This is where Happypages started. The question is how to evolve past it.

---

### Railway (railway.com)

**Nav paradigm:** Project > Service > Resource hierarchy with a canvas/spatial interface.

**Navigation model:**
- Top bar: workspace/team switcher, project switcher
- Main canvas: visual representation of services, databases, and their connections
- Service detail: slide-out panel or dedicated page with tabs (Deployments, Settings, Variables, Logs, Metrics)
- Observability tab accessible from project top bar
- Customizable dashboard widgets (drag, resize, rearrange)

**What works well:**
- The spatial canvas metaphor is powerful for infrastructure -- you *see* how services relate. This is unusual among the reference products and specific to Railway's domain.
- Project switching is fast and always accessible from the top bar. You never lose context about *which* project you're in.
- The service detail slide-out preserves canvas context while showing depth.

**What doesn't work:**
- The spatial model doesn't translate well to non-infrastructure domains. You can't "canvas" analytics + referrals + CRO.
- Limited sidebar -- Railway relies on the canvas to replace traditional nav, which means there's no persistent list of "all the things you can do."
- Discoverability is lower than sidebar-based products; new users don't know what's available until they explore.

**Key takeaway:** The project/workspace switcher in the top bar is a clean pattern. The canvas model isn't transferable, but the principle of "always show which context you're in" absolutely is.

---

## 2. Pattern Taxonomy

From the six reference products, five distinct navigation paradigms emerge:

### A. Flat Unified Sidebar
**Products:** Shopify, Skio
**Structure:** Single-level sidebar with all features visible as top-level items.
**Best for:** Products with <10 feature areas, single-purpose apps, predictable user journeys.
**Weakness:** Doesn't scale past ~12 items without becoming a wall of text.

### B. Sectioned Sidebar with Progressive Disclosure
**Products:** Stripe
**Structure:** Sidebar divided into named sections. Core items always visible, secondary items behind an expander.
**Best for:** Multi-product platforms where users access different subsets of features.
**Weakness:** "More" bucket becomes a graveyard for undiscovered features.

### C. Workspace / Favorites Hybrid
**Products:** Attio, Linear (partially)
**Structure:** Standard sidebar + user-curated Favorites section that acts as personalized nav.
**Best for:** Products where different users have radically different workflows.
**Weakness:** Requires investment from users to configure; empty by default.

### D. Hub-and-Spoke (Category Grouping)
**Products:** HubSpot
**Structure:** Top-level categories (Marketing, Sales, Service, etc.) each containing feature sub-items. Categories are conceptual "hubs."
**Best for:** Large suites where features cluster naturally by business function.
**Weakness:** Users must learn the taxonomy before they can navigate. Cross-cutting features don't fit cleanly in one hub.

### E. Spatial / Canvas
**Products:** Railway
**Structure:** Visual canvas replaces traditional nav; items are arranged spatially.
**Best for:** Infrastructure, design tools, and other domains where relationships between items matter more than lists.
**Weakness:** Doesn't generalize to most SaaS products.

---

## 3. Three Proposed Navigation Paradigms for Happypages

### Paradigm 1: "The Stripe" -- Sectioned Sidebar with Shortcuts

**Description:** A vertical sidebar with three tiers: Shortcuts (user-pinned), Core (always visible, enabled features), and Discover (locked features + overflow). A customizable Home dashboard serves as the landing page.

**Rationale:** Stripe's model is the closest fit for Happypages's trajectory -- multiple independent products, different users with different subsets, per-feature pricing. The Shortcuts section solves the "I only use 3 things" problem. The Discover section turns locked features into an upsell surface.

**Text wireframe:**

```
+----------------------------------+
| [HP logo]  happypages            |
| Shop: Oatcult           [v]     |
+----------------------------------+
| * Home                           |
+----------------------------------+
| SHORTCUTS                        |
|   Referrals Dashboard            |
|   Analytics > Real-time          |
|   + Add shortcut                 |
+----------------------------------+
| TOOLS                            |
|   Analytics           [active]   |
|     Dashboard                    |
|     Real-time                    |
|     Reports                      |
|   Referrals           [active]   |
|     Dashboard                    |
|     Links                        |
|     Settings                     |
|   CRO / A-B Testing  [active]   |
+----------------------------------+
| DISCOVER                  [^]    |
|   Landing Pages       [lock]    |
|   Customer Insights   [lock]    |
|   Ad Manager          [lock]    |
|   Ambassadors         [lock]    |
+----------------------------------+
| SERVICES                         |
|   Workspace                      |
|   Messages                       |
+----------------------------------+
|   Settings                       |
|   Help                           |
+----------------------------------+
```

**How it handles:**

- **1 feature vs many:** With 1 feature, TOOLS has one expanded section. Shortcuts might be hidden until >1 feature is active. The sidebar feels focused, not empty.
- **Locked features:** DISCOVER section shows locked features with a lock icon. Clicking opens a feature detail modal with benefits + upgrade CTA. Section is collapsible.
- **Services workspace:** Gets its own dedicated section at the bottom, visually separated. Only appears for managed-services clients.

**Pros:**
- Natural upsell surface (DISCOVER section)
- Shortcuts let power users build their own fast paths
- Each tool expands to show its own sub-nav, keeping the top level scannable
- Scales cleanly from 1 to 10+ features

**Cons:**
- Three-tier sidebar (Shortcuts, Tools, Discover) might feel like three competing navigation paradigms
- Locked features in a "Discover" section might feel like an ad
- More complex to implement than a flat sidebar

**Draws from:** Stripe (shortcuts, progressive disclosure), Shopify (flat top-level structure), PostHog (locked feature philosophy)

---

### Paradigm 2: "The Linear" -- Feature-as-Team Collapsible Groups

**Description:** Each enabled feature is a collapsible group in the sidebar, similar to how Linear treats teams. Features expand to show their sub-pages. Home is an overview dashboard. Locked features appear as collapsed, muted groups with a badge.

**Rationale:** Linear proves that collapsible groups work at scale (teams with sub-teams). Happypages features are conceptually similar to Linear's teams -- each is an independent domain with its own pages. This model maps cleanly to Happypages's "independently unlockable" pricing.

**Text wireframe:**

```
+----------------------------------+
| [HP logo]  happypages            |
| Oatcult                  [v]    |
+----------------------------------+
|   Home                           |
|   Notifications                  |
+----------------------------------+
| > Analytics              [=]    |
|     Dashboard                    |
|     Real-time                    |
|     Goals                        |
|     Reports                      |
| > Referrals              [=]    |
|     Dashboard                    |
|     Links & Codes                |
|     Rewards                      |
|     Settings                     |
| > CRO                    [=]    |
|     Experiments                  |
|     Results                      |
+----------------------------------+
|   Landing Pages       [locked]  |
|   Insights            [locked]  |
|   Ad Manager          [locked]  |
|   Ambassadors         [locked]  |
|   Funnels             [locked]  |
+----------------------------------+
| > Services               [=]    |
|     Issues                       |
|     Messages                     |
+----------------------------------+
|   Settings                       |
+----------------------------------+
```

**How it handles:**

- **1 feature vs many:** With 1 feature, only that group is expanded. The sidebar is short and focused. As features are unlocked, groups appear. The user's sidebar grows with their subscription.
- **Locked features:** Locked features appear as non-expandable items below the active features, with a subtle "locked" badge. Clicking opens an info sheet, not a hard paywall modal. Muted text color (50% opacity).
- **Services workspace:** Another collapsible group, but visually separated (divider line). Only rendered for managed-services accounts.

**Pros:**
- Sidebar literally mirrors subscription state -- what you see is what you have
- Collapsible groups handle density gracefully (collapse what you're not using)
- Adding a new feature = adding a new group. Very modular for engineering.
- Feels premium and opinionated, like Linear

**Cons:**
- All-expanded state with 5+ features gets long
- Locked features taking up sidebar space could feel cluttered for users who don't want them
- No Shortcuts/personalization layer -- every user sees the same thing (for their plan)
- Requires good defaults for which groups start expanded vs collapsed

**Draws from:** Linear (collapsible team groups), Shopify (apps as nav items), Attio (expandable sections)

---

### Paradigm 3: "The Workspace" -- Favorites-First with Feature Launcher

**Description:** The sidebar has a compact, user-curated Favorites section as the primary navigation surface. Below it, a "Feature Launcher" grid (think macOS Launchpad or Notion's sidebar switcher) shows all enabled and available features as icon tiles. Clicking a feature tile navigates to it and optionally pins it to Favorites.

**Rationale:** The workspace model (Notion, Attio) acknowledges that different users have different workflows. Instead of designing one sidebar hierarchy for all users, let each user build their own. The Feature Launcher provides discoverability without cluttering the sidebar.

**Text wireframe:**

```
+----------------------------------+
| [HP logo]                        |
| Oatcult                  [v]    |
+----------------------------------+
| FAVORITES                        |
|   Referral Dashboard             |
|   Analytics Dashboard            |
|   Real-time Analytics            |
|   Service Issues                 |
|   [+ Add to favorites]          |
+----------------------------------+
| FEATURES              [grid]    |
| +--------+  +--------+          |
| |Analytics|  |Referral|          |
| | [icon]  |  | [icon] |          |
| +--------+  +--------+          |
| +--------+  +--------+          |
| |  CRO   |  |Services|          |
| | [icon]  |  | [icon] |          |
| +--------+  +--------+          |
| +--------+  +--------+          |
| |Land.Pgs|  |Insights|          |
| | [lock]  |  | [lock] |          |
| +--------+  +--------+          |
+----------------------------------+
|   Settings                       |
|   Help                           |
+----------------------------------+
```

**How it handles:**

- **1 feature vs many:** With 1 feature, Favorites auto-populates with that feature's key pages. The grid shows 1 active tile and several locked tiles. As more features unlock, the user curates their Favorites.
- **Locked features:** Appear as muted tiles in the Feature Launcher grid with a lock overlay. Clicking opens a feature preview page (description, screenshots, pricing). They're visible but clearly distinct from active features.
- **Services workspace:** Appears as a tile in the grid and a pinnable section in Favorites. When pinned, it expands to show Issues and Messages sub-items.

**Pros:**
- Maximum personalization -- users own their nav
- Feature Launcher is a natural upsell surface without feeling like ads
- Works for 1 feature (simple favorites list) and 10 features (curated favorites + full grid)
- Novel and memorable -- differentiates Happypages from Shopify-style apps

**Cons:**
- Requires onboarding investment ("here's how to set up your sidebar")
- Empty favorites on first launch is a cold-start problem
- Two navigation paradigms (favorites vs grid) is cognitively more complex
- Grid layout in a sidebar is unconventional and might waste vertical space
- Power users might find the extra step (launch grid > click feature) slower than a direct sidebar link

**Draws from:** Attio (favorites with folders), Notion (workspace model), Railway (visual layout), macOS Launchpad (grid metaphor)

---

## 4. Locked vs. Unlocked Features: Recommendation

After analyzing how Stripe, HubSpot, PostHog, and general PLG best practices handle feature gating, here is the specific recommendation for Happypages:

### Show, Don't Hide

**Always show locked features in navigation.** Hiding them (HubSpot's approach) removes the upsell surface entirely and means users don't know what they're missing. The research is clear: disabled-and-visible outperforms hidden for both user education and conversion.

### The Lock Icon Pattern

Use a small lock icon (not a badge, not grayed-out text) next to the feature name. The feature name itself should be at ~60% opacity compared to active features. This makes the hierarchy clear at a glance: bright = yours, muted + lock = available.

### Click Behavior

Clicking a locked feature should open a **feature preview page** (not a modal, not a tooltip). This page lives at its own URL (e.g., `/analytics/preview`) and contains:
- One-line description of what the feature does
- 2-3 screenshots or a short video
- Key metrics or social proof ("Used by 200+ stores")
- Clear pricing for this specific feature
- "Start free trial" or "Add to plan" CTA

Why a page, not a modal? Pages are linkable, bookmarkable, and shareable. A team member can send the preview URL to their boss for budget approval.

### Positioning in Sidebar

Locked features should appear **below** active features, separated by a subtle divider or section header ("Available" or "Discover"). This avoids interleaving active and locked items, which creates visual noise and makes the active-feature section feel cluttered.

### Collapse Option

Provide a small toggle to collapse the locked features section. Users who don't want to see them can hide them. Default: expanded for accounts with <3 active features (maximize discovery), collapsed for accounts with 5+ (they know the platform, reduce noise).

### Never Block Navigation

Even in the locked state, the feature preview page should include real (anonymized/demo) data or interactive previews where possible. PostHog's philosophy applies: "show what they're missing, not an error." The gate moment is marketing, not access control.

---

## 5. Recommendation: Paradigm 2 -- "The Linear" (Feature-as-Group Collapsible Sidebar)

### Why Paradigm 2

**It matches the product model.** Happypages sells features independently. The sidebar should reflect this directly: each feature is a collapsible group. What you see is what you have. This is the same insight that makes Linear's team-based sidebar so effective -- the nav *is* the mental model.

**It scales cleanly.** A solo founder with just Analytics sees a short, focused sidebar. A growing brand with Analytics + Referrals + CRO sees three groups. An agency with the full suite sees all nine. The sidebar grows with the subscription, and collapsing unused groups keeps it manageable.

**It's engineering-friendly.** Each feature group is a self-contained nav component. Adding a new feature to the platform = adding a new group. No changes to shortcuts logic, no grid layout updates, no favorites system to maintain.

**It avoids cold-start problems.** Unlike Paradigm 3 (Workspace), there's no empty Favorites section on first launch. The sidebar is immediately useful with sensible defaults.

**It handles locked features naturally.** Locked features appear as non-expandable items below the active groups. They're visible but obviously different. This is the cleanest visual separation of "yours" vs "available" of the three paradigms.

### Why Not Paradigm 1 (Stripe)

Stripe's Shortcuts model is powerful but adds implementation complexity (pinning, ordering, persistence) for a benefit that matters more at Stripe's scale (hundreds of settings pages) than Happypages's (tens of pages). Shortcuts can be added later as a progressive enhancement once the user base demonstrates the need.

### Why Not Paradigm 3 (Workspace)

The Workspace model is the most novel but also the riskiest. It requires users to configure their own nav, which is friction. It introduces two navigation paradigms (favorites + grid) which is cognitively heavy. And the grid-in-sidebar layout is unconventional enough to confuse users coming from Shopify, Stripe, or any other sidebar-based tool. Innovation in navigation is high-risk -- users want nav to be predictable, not clever.

### Refinements to Paradigm 2

1. **Add a Cmd+K command palette from day one.** This is the escape hatch for power users and reduces pressure on the sidebar to be perfect. Linear, Attio, Stripe, and every modern SaaS product has one.

2. **Auto-collapse inactive groups.** If a user hasn't visited a feature in 7+ days, collapse its group. This keeps the sidebar focused on recent activity without requiring manual management.

3. **Contextual "active" indicator.** The currently-active feature group gets a subtle left-border highlight (like Linear's active team). This provides wayfinding without adding visual clutter.

4. **Shop/brand switcher in top bar.** Following Railway and Linear's workspace switcher pattern, put the current shop context at the very top of the sidebar. Agencies managing multiple brands switch here.

5. **Services workspace as a distinct visual section.** Managed-services clients get a visually separated group at the bottom with a different background shade, clearly signaling "this is a different kind of thing" vs self-serve tools.

6. **Home dashboard adapts to active features.** With 1 feature, Home shows that feature's dashboard directly. With 3+ features, Home shows a cross-feature overview with KPI cards from each active feature.

### Implementation Priority

1. **Phase 1:** Flat sidebar with the features you have today (Analytics, Referrals). No collapsible groups needed yet. Just icons + labels + sub-pages. This is the Shopify/Skio pattern and it's correct for 2 features.

2. **Phase 2:** When feature 3 ships, introduce collapsible groups. Add the locked-features section below active groups. Add Cmd+K.

3. **Phase 3:** When agencies or multi-brand users arrive, add the shop switcher in the top bar. Add auto-collapse behavior.

This phased approach avoids over-engineering the nav before it's needed while establishing the architectural direction now.

---

## Appendix: Source References

- [Linear UI Redesign](https://linear.app/now/how-we-redesigned-the-linear-ui) -- Design philosophy and sidebar refinement process
- [Linear Conceptual Model](https://linear.app/docs/conceptual-model) -- Workspace > Team > Issue hierarchy
- [Linear Teams Documentation](https://linear.app/docs/teams) -- Team sidebar sections
- [Linear Sub-teams](https://linear.app/changelog/2025-03-06-sub-teams) -- Nested team hierarchy
- [Stripe Dashboard Basics](https://docs.stripe.com/dashboard/basics) -- Sidebar structure, Shortcuts, Home customization
- [Stripe Sessions 2025 Product Updates](https://stripe.com/blog/top-product-updates-sessions-2025) -- Multi-product strategy
- [Shopify App Navigation](https://shopify.dev/docs/apps/design/navigation) -- App nav patterns, 7-item limit
- [Attio Navigation Guide](https://attio.com/help/reference/attio-101/introduction-to-navigating-attio) -- Six-section sidebar, Favorites
- [Attio Figma Screens](https://www.figma.com/community/file/1533024283737732966) -- 250+ UI screenshots
- [Skio Overview Dashboard](https://help.skio.com/docs/overview-dashboard) -- Dashboard structure
- [HubSpot Navigation Guide](https://knowledge.hubspot.com/help-and-resources/a-guide-to-hubspots-navigation) -- Hub-and-spoke model, category grouping
- [Hidden vs Disabled in UX (Smashing Magazine)](https://www.smashingmagazine.com/2024/05/hidden-vs-disabled-ux/) -- When to show vs hide locked features
- [PostHog Paid Features UI Discussion](https://github.com/PostHog/posthog/issues/6413) -- Feature gating philosophy
- [SaaS Navigation UX Patterns (Pencil & Paper)](https://www.pencilandpaper.io/articles/ux-pattern-analysis-navigation) -- Object-oriented vs task-oriented nav
- [Sidebar UX Best Practices (ALF Design)](https://www.alfdesigngroup.com/post/improve-your-sidebar-design-for-web-apps) -- Visual hierarchy, 2026 patterns
