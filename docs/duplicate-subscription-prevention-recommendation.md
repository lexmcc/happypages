# Duplicate Subscription Prevention: Final Recommendation

**Prepared for:** [Client]
**Date:** February 2026
**Status:** Final Recommendation

---

## Executive Summary

Existing customers are creating duplicate subscriptions — a problem rooted in navigation architecture and identity detection, not just missing login prompts. Our recommendation combines backend enforcement (the only 100% reliable prevention), navigation routing for logged-in users, early email collection during onboarding, and contextual recognition for returning visitors. This approach eliminates duplicates without introducing friction that damages new customer conversion.

The core principle: **prevent duplicates through system design, not by interrogating users.**

---

## 1. Areas of Unanimous Agreement

All three expert analyses converge on the following. These are **must-do** items with no dissent.

| # | Unanimous Position | Implication |
|---|---|---|
| 1 | **Backend enforcement at checkout** — no email can hold two active subscriptions simultaneously | Hard technical gate. Non-negotiable safety net regardless of all other UX decisions |
| 2 | **Navigation must adapt for logged-in users** — Range/Shop should route to edit-menu experience, not new-customer onboarding | Solves criterion 4 (discovery confusion) and criterion 6 (clear editing flow) directly |
| 3 | **Paused customers need a dedicated reactivation path** — distinct from both new-customer signup and active-customer management | Solves criterion 7 (easy restart) |
| 4 | **Differentiate messaging for active vs. paused customers** — these are fundamentally different user states requiring different treatment | Active = "manage your box"; Paused = "welcome back, restart" |
| 5 | **No gate on the menu/range page itself** — interrupting browsing feels punitive and is too late in the journey | All three experts reject the client's proposed "gate on add action" |
| 6 | **Hide new-customer promo pricing from logged-in users** — showing discounts they cannot access creates confusion and frustration | Solves criterion 3 directly |

---

## 2. Key Disagreements and Resolutions

### Disagreement A: Should there be a routing screen / splash gate before onboarding?

| Position | Advocate | Argument |
|---|---|---|
| Yes — routing screen at moment of commercial intent, weighted 65/35 toward new customers | UX Expert | Catches returning users early, gives them a clear path, prevents wasted time in wrong flow |
| No — any pre-checkout gate costs 15-25% new customer abandonment | CRO Expert | Math: ~225 lost subscribers/month at scale. Silent detection + contextual nudge achieves same goal |
| No — gates are the wrong abstraction; backend + nav routing eliminates the need | Contrarian Expert | Prevention hierarchy: engineer it out rather than warn about it |

**Resolution: No routing screen. The CRO and Contrarian positions win.**

Reasoning:
- The routing screen solves the problem for *logged-out returning customers only* — logged-in users are already handled by nav routing, and new customers gain nothing from it.
- The cost is borne entirely by new customers (the majority of traffic), while the benefit accrues to a minority segment that can be caught by other, less disruptive means.
- Email-first onboarding (see below) catches returning customers at step 1 of the flow with near-zero incremental friction, achieving the same identification goal.
- Backend checkout enforcement means even if someone slips through every soft layer, they still cannot create a duplicate.

The UX Expert's underlying concern — that users shouldn't invest time in the wrong flow — is valid. We address it through early email collection (catches them at step 1, not step 5) and contextual recognition (catches them before they even start).

### Disagreement B: Where should email collection sit in onboarding?

| Position | Advocate | Argument |
|---|---|---|
| Email at routing screen (pre-onboarding) | UX Expert | Earliest possible identification point |
| Email as onboarding step 1 (before preferences) | CRO Expert | Industry standard, <3% incremental drop-off, enables instant account lookup |
| No email gate; rely on backend + passive recognition | Contrarian Expert | Any forced input is friction; detect via cookies/session instead |

**Resolution: Email as onboarding step 1. The CRO position wins, with elements of both others.**

Reasoning:
- Moving email from step 3-4 to step 1 is a minor reorder with proven minimal impact (<3% incremental drop-off per industry benchmarks from HelloFresh, Gousto).
- It enables instant server-side lookup: if the email matches an existing account, we can surface a contextual message *within the flow* rather than through a separate gate.
- Pure passive detection (Contrarian position) is unreliable across devices, browsers, and cleared cookies. Email provides a deterministic signal.
- This is strictly better than a routing screen: same identification power, no extra page/modal, no decision fatigue for new customers.

### Disagreement C: How aggressive should the nudge be when a returning customer is detected?

| Position | Advocate | Argument |
|---|---|---|
| Hard gate for logged-in users hitting onboarding — no path to new subscription | UX Expert | Non-negotiable; logged-in user creating new subscription is always an error |
| Soft nudge (banner/toast) for detected returning users; hard gate only at checkout | CRO Expert | Soft nudge informs; hard gate at checkout prevents |
| Passive top bar + backend prevention; no interrupting modals | Contrarian Expert | Minimal disruption, maximum prevention |

**Resolution: Hard gate for authenticated users. Contextual inline message (not modal) for detected-but-unauthenticated users. Hard gate at checkout as safety net.**

Reasoning:
- **Logged-in user entering new-customer onboarding is architecturally wrong.** All three experts agree nav should route them elsewhere. If they somehow reach onboarding despite nav routing (e.g., direct URL, shared link), a hard redirect is correct — this is not a UX gate, it is routing logic.
- **Detected returning user (via email at step 1):** A contextual inline message within the onboarding step — not a modal, not a toast — is the right balance. It explains the situation and offers a clear path to login/reactivation without blocking the form or feeling punitive.
- **Checkout enforcement** remains the non-negotiable backstop.

### Disagreement D: Edge cases — shared households, gift subscriptions

Only the Contrarian Expert raised these. They are valid and must be addressed.

**Resolution: Support intentional second subscriptions through an explicit "new subscription for a different person" path.**

- At the email-match detection point (onboarding step 1), the inline message includes: "Already have an account? **Log in to manage your subscription** or **continue if this is for someone else**."
- At checkout backend enforcement: if the email matches an active subscription, require confirmation that this is intentional (e.g., gift, second household member) before allowing it.
- This preserves the safety net while not blocking legitimate use cases.

---

## 3. Final Recommended Flow by User Type

### (a) New Customer — Never Had an Account

This user must experience **zero additional friction** compared to today's flow, aside from email moving to step 1.

```
LANDING PAGE
    |
    v
[Get Started / See Menu / Subscribe]
    |
    v
ONBOARDING STEP 1: Email
    |
    +---> Email NOT in system
    |         |
    |         v
    |     ONBOARDING STEP 2: Preferences
    |         |
    |         v
    |     ONBOARDING STEP 3: Menu Selection
    |         |
    |         v
    |     CHECKOUT (standard new customer flow)
    |         |
    |         v
    |     ACCOUNT CREATED + SUBSCRIPTION ACTIVE
    |
    +---> [Edge: email matches existing account]
              |
              v
          See flow (b) or (c) below
```

**Friction delta vs. current:** Near zero. Email input moves earlier in the flow. No new pages, modals, or decisions added.

### (b) Returning Customer — Logged Out, Active Subscription

This user has an active subscription but is not logged in. They may have forgotten they subscribe, or they may be browsing from a new device.

```
LANDING PAGE
    |
    v
[Get Started / See Menu / Subscribe]
    |
    v
ONBOARDING STEP 1: Email
    |
    +---> Email matches ACTIVE subscription
    |         |
    |         v
    |     INLINE MESSAGE (within step 1, not a modal):
    |     "Welcome back! You already have an active subscription.
    |      Log in to edit your box, skip a week, or manage
    |      your account. [Log In button]
    |      Ordering for someone else? [Continue as new]"
    |         |
    |         +---> [Log In] --> LOGIN --> DASHBOARD (edit box)
    |         |
    |         +---> [Continue as new] --> Proceed to step 2
    |                   |
    |                   v
    |               CHECKOUT: Backend confirms intent
    |               "This email has an active subscription.
    |                Confirm this is a separate order."
    |                   |
    |                   v
    |               ORDER PLACED (flagged for review)
    |
    +--- ALSO: If site recognizes returning visitor via
         cookie/session BEFORE they reach onboarding:
              |
              v
         PERSISTENT TOP BAR (dismissible):
         "Welcome back, [Name]. [Manage Subscription] [Dismiss]"
```

**Key decisions:**
- Inline message, not a modal — it doesn't block the page or feel like a wall.
- "Continue as new" escape hatch for legitimate edge cases (gifts, shared households).
- Backend checkout enforcement as final safety net.
- Passive cookie-based recognition provides an *additional* early signal but is not relied upon (cookies are unreliable).

### (c) Returning Customer — Logged Out, Paused Subscription

This user paused their subscription and is now returning. They are the highest-intent reactivation opportunity.

```
LANDING PAGE
    |
    +--- Cookie/session recognition (if available):
    |    PERSISTENT TOP BAR:
    |    "Welcome back, [Name]. Ready to restart?
    |     [Reactivate Subscription] [Dismiss]"
    |         |
    |         +---> [Reactivate] --> LOGIN --> REACTIVATION FLOW
    |
    v
[Get Started / See Menu / Subscribe]
    |
    v
ONBOARDING STEP 1: Email
    |
    +---> Email matches PAUSED subscription
              |
              v
          INLINE MESSAGE (within step 1):
          "Welcome back! Your subscription is paused.
           You can restart it in seconds with your
           previous preferences. [Reactivate Now]
           Starting fresh? [Continue as new]"
              |
              +---> [Reactivate Now] --> LOGIN -->
              |         |
              |         v
              |     REACTIVATION FLOW:
              |     - Pre-filled preferences from last active box
              |     - Option to update menu/preferences
              |     - Confirm restart (no re-entering payment
              |       if details still on file)
              |         |
              |         v
              |     SUBSCRIPTION REACTIVATED
              |
              +---> [Continue as new] --> Proceed to step 2
                        |
                        v
                    CHECKOUT: Backend offers choice:
                    "Reactivate existing subscription or
                     create a new one?"
                        |
                        v
                    APPROPRIATE ACTION TAKEN
```

**Key decisions:**
- Reactivation is framed positively ("restart in seconds") not as a barrier ("you already have an account").
- Pre-filled preferences reduce friction dramatically — the user doesn't repeat the full onboarding wizard.
- Payment details on file means reactivation can be faster than new signup.
- "Continue as new" escape hatch remains available.

### (d) Logged-In Customer Navigating via Range/Shop

This user is already authenticated. The navigation itself must prevent them from entering the new-customer flow.

```
LOGGED-IN USER ON SITE
    |
    +---> Clicks "Range" / "Shop" / "See Menu"
    |         |
    |         v
    |     EDIT-MENU EXPERIENCE (not new-customer menu)
    |     - Same products, same browsing
    |     - "Add to Box" language (not "Subscribe")
    |     - No new-customer promo pricing shown
    |     - Changes apply to existing subscription
    |         |
    |         v
    |     [Save Changes to Box]
    |
    +---> Clicks "Get Started" / "Subscribe" (e.g., from
    |     cached page, shared link, promo email)
    |         |
    |         v
    |     REDIRECT TO DASHBOARD with message:
    |     "You're already subscribed! Manage your box here."
    |     (No onboarding flow accessible while logged in
    |      with an active subscription)
    |
    +---> Navigates to onboarding URL directly
              |
              v
          SAME REDIRECT TO DASHBOARD
          (Server-side: authenticated user + active sub
           cannot access /onboarding routes)
```

**Key decisions:**
- Navigation labels can stay the same ("Range", "Shop") but the destination changes based on auth state. This avoids confusing label changes while solving the routing problem.
- "Add to Box" language makes the context unambiguous.
- No promo pricing visible — existing customers see their actual pricing.
- Hard redirect from onboarding routes for authenticated users with active subscriptions. This is not a "gate" — it is correct routing.

### (e) Paused Customer Reactivation (Logged In)

This user is logged in and their subscription is paused.

```
LOGGED-IN PAUSED CUSTOMER
    |
    +---> DASHBOARD shows prominent reactivation CTA:
    |     "Your subscription is paused.
    |      [Restart My Subscription]"
    |         |
    |         v
    |     REACTIVATION FLOW:
    |     1. Review last preferences (pre-filled)
    |     2. Browse menu / make changes (optional)
    |     3. Confirm delivery schedule
    |     4. Confirm (payment on file: one-click)
    |         |
    |         v
    |     SUBSCRIPTION REACTIVATED
    |
    +---> Clicks "Range" / "Shop"
    |         |
    |         v
    |     MENU BROWSING with "Reactivate + Add" framing
    |     Banner: "Your subscription is paused.
    |              Items you select will be in your
    |              first box when you restart."
    |
    +---> Clicks "Get Started" / "Subscribe"
              |
              v
          REDIRECT TO REACTIVATION FLOW
          (Not new-customer onboarding)
```

**Key decisions:**
- Reactivation is fast: pre-filled preferences + payment on file = potentially 2 clicks.
- Menu browsing is allowed but framed within reactivation context.
- No path from logged-in paused state to new subscription onboarding.

---

## 4. Comparison to Client's Original Proposal

| Aspect | Client Proposal | Our Recommendation | Rationale |
|---|---|---|---|
| **Primary gate location** | Gate on menu page when user tries to add an item | Gate at onboarding step 1 (email) + checkout backend enforcement | Menu-page gate is too late (user already invested time) and too early for payment prevention (can be bypassed). Email at step 1 catches users at the start. |
| **Gate type** | Splash screen / modal with equal-weight options | Inline contextual message within existing step (not a modal or separate page) | Equal-weight splash screens cause 15-25% abandonment for new customers. Inline message within an existing step adds near-zero friction. |
| **Navigation fix** | Not mentioned | Nav routes to edit-menu for logged-in users; "Add to Box" language | This alone solves criterion 4 and half of criterion 2. It was the largest gap in the original proposal. |
| **Paused customer flow** | Not mentioned | Dedicated reactivation path with pre-filled preferences | Paused customers are high-intent and high-value. A dedicated flow converts them at much higher rates than routing them through generic flows. |
| **Backend enforcement** | Not mentioned | Hard server-side block: no duplicate active subscriptions per email | The only 100% reliable prevention. All UX measures are defence-in-depth; backend enforcement is the foundation. |
| **New customer impact** | Splash screen adds a decision step for all visitors | Email moves to step 1; no new pages or decisions added | Preserves conversion rate for the majority segment (new customers). |

**Where we agree with the client:**
- The problem is real and urgent — existing customers creating duplicates is a revenue and experience issue.
- Some form of identity check is needed before checkout.
- Existing customers should not see new-customer promo pricing.

**Where we differ:**
- The client's instinct to gate at the menu page catches users too late and in the wrong context.
- A splash screen / routing screen adds friction to 100% of visitors to solve a problem affecting a minority.
- The proposal lacks the architectural fixes (nav routing, backend enforcement) that prevent the problem structurally rather than through UI warnings.

---

## 5. Criteria Assessment

| # | Criterion | How Addressed | Confidence |
|---|---|---|---|
| 1 | Avoid existing customers going through signup wizard again | Email at step 1 detects them immediately; inline message routes them to login/reactivation. Logged-in users cannot access onboarding routes. | High |
| 2 | Stop dual subscription state | Backend enforcement: no email can hold two active subscriptions without explicit confirmation. Nav routing prevents logged-in users from entering new-sub flow. | Very High |
| 3 | Stop existing customers seeing/expecting new customer discounts | Logged-in users see actual pricing, not promo pricing. Nav routes to edit-menu experience. Detected returning users (via email match) see messaging that sets correct expectations. | High |
| 4 | Stop discovery confusion from shop/range navigation | Nav adapts based on auth state: same labels, different destination. "Add to Box" language for subscribers. | High |
| 5 | Minimal negative friction for new customers | No new pages, modals, or decision points. Email input moves to step 1 (<3% incremental drop-off). All detection is passive or embedded in existing steps. | High |
| 6 | Clear editing/menu management flow for existing customers | Edit-menu experience is the default for logged-in users. Changes apply to existing subscription. No ambiguity about whether they're creating something new. | High |
| 7 | Easy restart for paused customers | Dedicated reactivation flow: pre-filled preferences, payment on file, 2-click restart. Proactive messaging when paused customer detected. | High |

---

## 6. Implementation Phases

### Phase 1: Foundation (Weeks 1-3)
*Eliminates the problem structurally. Zero UX risk.*

1. **Backend enforcement** — Server-side rule: no email can have >1 active subscription. Block at checkout API level. Return clear error with redirect to account management.
2. **Nav routing for logged-in users** — Range/Shop/Menu links resolve to edit-menu experience when user is authenticated with active subscription. Suppress new-customer promo pricing.
3. **Onboarding route protection** — Authenticated users with active subscriptions are redirected from onboarding URLs to dashboard.

**Criteria addressed:** 2 (fully), 3 (for logged-in), 4 (fully), 6 (fully)

### Phase 2: Early Detection (Weeks 4-5)
*Catches returning users before they invest time in the wrong flow.*

4. **Email-first onboarding** — Move email to step 1 of the onboarding wizard. Server-side lookup on submission.
5. **Inline detection message** — When email matches existing account: inline contextual message with login/reactivation path and "continue as new" escape hatch. Differentiate active vs. paused messaging.
6. **Checkout confirmation for edge cases** — If someone proceeds past inline message with a matching email, checkout requires explicit confirmation that this is intentional.

**Criteria addressed:** 1 (fully), 2 (defence-in-depth), 3 (for logged-out), 5 (preserved)

### Phase 3: Reactivation (Weeks 6-8)
*Converts paused customers efficiently.*

7. **Reactivation flow** — Dedicated flow for paused customers: pre-filled preferences, optional menu changes, confirm delivery schedule, one-click restart (payment on file).
8. **Dashboard reactivation CTA** — Prominent restart prompt on paused-customer dashboard.
9. **Paused-customer nav context** — Menu browsing framed within reactivation: "Items you select will be in your first box when you restart."

**Criteria addressed:** 7 (fully)

### Phase 4: Passive Recognition (Weeks 9-10)
*Adds a non-intrusive early signal for returning visitors.*

10. **Cookie/session-based returning visitor detection** — Persistent dismissible top bar: "Welcome back, [Name]. [Manage Subscription] [Dismiss]"
11. **Proactive outreach** — Triggered email when paused customer visits site (detected via cookie), with magic link to reactivation flow.

**Criteria addressed:** 1 (defence-in-depth), 7 (proactive)

### Phase Summary

| Phase | Effort | Risk | Impact |
|---|---|---|---|
| 1: Foundation | Medium (backend + routing) | Very Low (no UX change for users) | Eliminates 100% of duplicates for logged-in users |
| 2: Early Detection | Medium (onboarding restructure) | Low (<3% conversion impact) | Catches logged-out returning users at step 1 |
| 3: Reactivation | Medium (new flow) | Very Low (additive, not changing existing flows) | Converts high-value paused customers |
| 4: Passive Recognition | Low (cookie logic + email trigger) | Very Low (fully dismissible, non-blocking) | Catches returning visitors before onboarding |

---

## 7. A/B Testing Plan

### Test 1: Email-First Onboarding (Phase 2)
- **Control:** Current onboarding step order (email later in flow)
- **Variant:** Email as step 1
- **Primary metric:** Onboarding completion rate (new customers)
- **Secondary metrics:** Step 1 drop-off rate, time to complete onboarding
- **Expected outcome:** <3% drop in completion; significant increase in returning-customer detection
- **Sample size:** 2,000 new onboarding starts per variant
- **Duration:** 2-3 weeks

### Test 2: Inline Message Format (Phase 2)
- **Control:** Standard inline text message when email matches existing account
- **Variant A:** Inline message with prominent "Log In" button and subtle "Continue as new" link
- **Variant B:** Inline message with equal-weight "Log In" and "Continue as new" buttons
- **Primary metric:** Rate of returning customers choosing login vs. continuing as new
- **Secondary metrics:** Duplicate subscription creation rate, customer support tickets
- **Sample size:** 500 returning-customer detections per variant
- **Duration:** 4-6 weeks (dependent on returning customer volume)

### Test 3: Reactivation Flow vs. Generic Dashboard (Phase 3)
- **Control:** Paused customers log in to standard dashboard with small "Reactivate" option
- **Variant:** Paused customers log in to dedicated reactivation flow (pre-filled, streamlined)
- **Primary metric:** Reactivation completion rate
- **Secondary metrics:** Time to reactivate, menu changes made, first-box retention
- **Sample size:** 300 paused-customer logins per variant
- **Duration:** 6-8 weeks

### Test 4: Passive Recognition Bar (Phase 4)
- **Control:** No returning-visitor recognition
- **Variant:** Persistent dismissible top bar for cookie-recognized returning visitors
- **Primary metric:** Rate of returning customers reaching onboarding (should decrease)
- **Secondary metrics:** Bar dismiss rate, click-through to account management, new customer false-positive rate
- **Sample size:** 5,000 site visits per variant (cookie-recognized subset)
- **Duration:** 3-4 weeks

### Testing Principles
- Run only one test at a time on the same user segment to avoid interaction effects.
- Phase 1 (backend + nav routing) ships without A/B testing — these are architectural fixes, not UX experiments.
- All tests require statistical significance (95% confidence) before declaring a winner.
- Monitor customer support ticket volume as a leading indicator across all tests.

---

## 8. Summary of Recommendations

**Do immediately (Phase 1):**
- Block duplicate active subscriptions at the backend
- Route logged-in users' Range/Shop clicks to edit-menu experience
- Block authenticated users from accessing onboarding routes
- Hide new-customer promo pricing from logged-in users

**Do next (Phase 2):**
- Move email to onboarding step 1
- Show inline contextual message when email matches existing account
- Add checkout confirmation for edge cases (gifts, shared households)

**Do after (Phases 3-4):**
- Build dedicated reactivation flow for paused customers
- Add passive cookie-based returning visitor recognition
- Set up triggered reactivation emails for returning paused customers

**Do not do:**
- Splash screen or routing screen before onboarding
- Modal gate on menu/range page when user tries to add item
- Any hard gate that affects new customers before checkout
- Equal-weight "new vs returning" decision screen

The overarching philosophy: **make the right thing happen automatically, rather than asking users to identify themselves.** Backend enforcement eliminates duplicates with certainty. Navigation routing guides logged-in users to the correct experience. Early email collection catches returning users gracefully. And a dedicated reactivation flow turns paused customers back into active subscribers with minimal effort.

---

*This recommendation synthesizes input from UX, conversion rate optimisation, and edge-case analysis. Implementation priority is ordered by impact certainty and reversibility — architectural fixes first, UX experiments second.*

---

# Addendum A: Range/Shop Browse Path — Non-Logged-In Existing Customers

**Added:** February 2026
**Status:** Amendment to Main Recommendation
**Triggered by:** Gap identified in post-review — the main recommendation did not adequately address the most common problem path.

---

## A.1 The Gap

The main recommendation handles:
- **Logged-in users** via Range/Shop → nav routing to edit-menu (Section 3d) ✓
- **Non-logged-in users entering via onboarding CTA** → email at step 1 catches them (Section 3a-c) ✓
- **Backend checkout enforcement** as safety net (Section 6, Phase 1) ✓

It does **not** handle:

> **Non-logged-in existing customer → clicks Range or Shop in nav → browses menu freely → selects meals → sees promo pricing → attempts checkout → caught only at backend**

This is arguably the *most common* problem path. The Range/Shop nav links are prominent, browsing is appealing, and the menu page is where the product sells itself. An existing customer on a new device, with cleared cookies, or who simply forgot they subscribe, will follow this path naturally — and the main recommendation's only answer is the backend block at checkout, *after* they have invested 10-15 minutes selecting meals at prices they cannot access.

The client's original proposal — a "Login / Create Account" splash screen when a user tries to add an item to their box — was rejected by all three experts as "too late and punitive." But the main recommendation left a vacuum: it said "no gate on the menu page" (Unanimous Position #5) without offering a positive alternative for this specific entry point.

This addendum fills that gap.

---

## A.2 The Three Expert Positions

| Expert | Proposal | Gate Point | Promo Pricing |
|---|---|---|---|
| **UX** | Soft identification banner at top of menu page + non-blocking email check at first "Add to Box" | "Add to Box" action (non-blocking) | Show standard pricing; promos via onboarding |
| **CRO** | Free browsing, lightweight email modal triggered at first "Add to Box" click, backend lookup forks to appropriate path | "Add to Box" action (blocking modal) | Keep as-is (shown to all) |
| **Contrarian** | No gate at all. Remove promo pricing from browse pages. Anonymous local cart. Email collected at "Checkout/Subscribe" (which routes to onboarding step 1) | "Checkout/Subscribe" button | Remove from browse; reveal in onboarding |

### Key tensions:

1. **Gate at "Add" vs. no gate** — UX and CRO both intervene at "Add to Box"; Contrarian argues this is a login wall by another name.
2. **Promo pricing on browse pages** — CRO accepts it; UX and Contrarian say it is the root cause.
3. **Where commitment begins** — UX/CRO say at "Add"; Contrarian says at "Subscribe/Checkout."
4. **Anonymous local cart** — only the Contrarian proposes this, but it has independent merit.

---

## A.3 Resolution: Hybrid Approach

### Decision 1: No gate at "Add to Box." The Contrarian wins on gate placement.

The CRO and UX experts are correct that "Add to Box" represents a meaningful intent signal. But the Contrarian's critique is sharper: the psychological contract of an "Add" button is *immediate selection*, not *identify yourself first*. An email modal at "Add" — however well-designed — breaks that contract. It is functionally a login wall at the point of highest engagement, and risks the same 15-25% abandonment the main recommendation warned against for routing screens.

The main recommendation already established the principle: **email collection happens at onboarding step 1, not before.** Introducing a second email collection point on the menu page contradicts this and creates two identification pathways to maintain.

### Decision 2: Allow anonymous "Add to Box" with a local cart. The Contrarian wins, with modification.

Users can browse and build a box without identifying themselves. Selections are stored client-side (localStorage). This is the standard e-commerce browsing paradigm and introduces zero friction for new customers.

The modification: we do NOT wait until a "Subscribe/Checkout" button. Instead, the local cart *is* the bridge into onboarding. When the user has selected enough items to constitute a box (or clicks "Continue" / "View My Box"), they enter the onboarding flow at step 1 (email), where the main recommendation's detection logic already applies. Their selections carry forward.

### Decision 3: Suppress promo pricing on Range/Shop browse pages. The Contrarian wins, with a testing caveat.

This is the most consequential decision and the one that most directly addresses the root cause.

**Why:** The core problem is not that existing customers *browse* — it is that they browse *at prices they cannot access*. Promo pricing on anonymous browse pages sets false expectations for existing customers and is the direct cause of the negative experience when they hit the backend gate. Removing it eliminates the expectation mismatch entirely.

**What replaces it:** Range/Shop pages show standard (non-promotional) pricing, or no pricing at all (just meal descriptions, images, and "Add to Box"). Promo pricing is revealed inside the onboarding flow after email collection at step 1 — where the system knows whether the user qualifies.

**The caveat:** This may reduce browse-to-subscribe conversion for new customers who are motivated by visible discounts. This MUST be A/B tested (see A.5). If the test shows significant conversion loss, fall back to showing promo pricing with a clear "new customer offer" label and fine print, rather than displaying it as the default price.

### Decision 4: Add a persistent "Already a customer?" link on Range/Shop pages. Drawn from UX and Contrarian positions.

A non-intrusive, always-visible link (not a banner, not a modal) in the menu page header: **"Already a customer? Log in to edit your box."** This is:
- Zero friction for new customers (it's a link, not a gate)
- A clear escape hatch for existing customers who recognise themselves
- Consistent with the existing passive recognition pattern (Section 3b's cookie-based top bar)

---

## A.4 Recommended Flow: Non-Logged-In User via Range/Shop

```
SITE NAVIGATION
    |
    v
[Range] or [Shop] clicked
    |
    v
MENU / BROWSE PAGE
+-----------------------------------------------+
|  "Already a customer? Log in to edit your box" |  <-- subtle link, always visible
|                                                 |
|  [meal cards with STANDARD pricing or no price] |  <-- no promo pricing
|  [Add to Box] [Add to Box] [Add to Box]        |  <-- anonymous, no gate
|                                                 |
|  Selections saved to local cart (localStorage)  |
+-----------------------------------------------+
    |
    v  (user has selected items, clicks "Continue" / "View My Box")
    |
    v
ONBOARDING STEP 1: Email
(Main recommendation flow resumes here — Section 3a-c)
    |
    +---> Email NOT in system (new customer)
    |         |
    |         v
    |     Promo pricing NOW revealed:
    |     "Great news! As a new customer, your first box
    |      is [promo price]. Your selections have been saved."
    |         |
    |         v
    |     ONBOARDING STEP 2: Preferences (selections pre-filled)
    |         |
    |         v
    |     CHECKOUT at promo price
    |
    +---> Email matches ACTIVE subscription
    |         |
    |         v
    |     INLINE MESSAGE (per Section 3b):
    |     "Welcome back! You have an active subscription.
    |      Log in to add these items to your next box.
    |      [Log In]  |  Ordering for someone else? [Continue]"
    |         |
    |         +---> [Log In] --> selections offered as edit-box additions
    |         +---> [Continue] --> standard edge-case flow
    |
    +---> Email matches PAUSED subscription
              |
              v
          INLINE MESSAGE (per Section 3c):
          "Welcome back! Your subscription is paused.
           Restart and we'll add these selections to your
           first box back. [Reactivate]  |  [Continue as new]"
              |
              +---> [Reactivate] --> reactivation with selections pre-filled
              +---> [Continue] --> standard edge-case flow
```

### What this achieves:

- **Existing customer on new device:** Browses freely at standard pricing (no false expectations), builds a box, enters email at onboarding step 1, is immediately identified and routed correctly. Their selections are preserved.
- **New customer browsing before committing:** Browses freely, adds items, enters onboarding with selections pre-filled. Promo pricing revealed at step 1 as a *pleasant surprise* rather than an assumed baseline.
- **Existing customer who recognises themselves:** Clicks "Already a customer? Log in" link, goes to dashboard/edit-box. Zero friction.
- **Cookie-recognised returning visitor:** Still sees the persistent top bar from Section 3b (if cookies available), providing an additional early signal.

---

## A.5 A/B Testing Recommendations

### Test 5: Promo Pricing on Browse Pages (Phase 2, run alongside Test 1)

- **Control:** Current behaviour — promo pricing visible on Range/Shop browse pages for all visitors
- **Variant A:** Standard pricing shown on browse pages; promo pricing revealed at onboarding step 1 (email) for qualifying new customers
- **Variant B:** No pricing on browse pages (just meal cards with descriptions); pricing revealed at onboarding step 1
- **Primary metric:** Browse-to-onboarding conversion rate (new customers entering onboarding after browsing Range/Shop)
- **Secondary metrics:** Overall onboarding completion rate, average box value, returning-customer duplicate attempts, support tickets about pricing confusion
- **Expected outcome:** Possible 5-15% reduction in browse-to-onboarding entry (some new customers are promo-motivated); but improved onboarding completion and reduced duplicate attempts. Net effect may be positive.
- **Sample size:** 3,000 Range/Shop page visits per variant
- **Duration:** 3-4 weeks
- **Decision rule:** If Variant A or B shows >10% reduction in new-customer onboarding starts with no offsetting improvement in completion rate, revert to showing promo pricing with a clear "new customer offer" label.

### Test 6: Anonymous Local Cart Carry-Forward (Phase 2)

- **Control:** Range/Shop browsing with no cart; user enters onboarding with empty selections
- **Variant:** Anonymous local cart; selections carry into onboarding step 2 (menu selection pre-filled)
- **Primary metric:** Onboarding completion rate for users who entered via Range/Shop
- **Secondary metrics:** Time to complete onboarding, items changed after pre-fill, first-box satisfaction
- **Expected outcome:** Higher completion rate (invested effort carries forward; sunk cost works in our favour)
- **Sample size:** 1,500 onboarding starts via Range/Shop per variant
- **Duration:** 3-4 weeks

---

## A.6 Integration with Existing Phases

| Phase | Existing Scope | Addition from This Amendment |
|---|---|---|
| **Phase 1** (Weeks 1-3) | Backend enforcement, nav routing for logged-in users, onboarding route protection | Add "Already a customer? Log in" link to Range/Shop menu pages (trivial, no UX risk) |
| **Phase 2** (Weeks 4-5) | Email-first onboarding, inline detection message, checkout confirmation | Suppress promo pricing on browse pages (A/B tested). Build anonymous local cart with carry-forward into onboarding. Ensure inline messages reference user's browse selections ("add these to your box"). |
| **Phase 3** (Weeks 6-8) | Reactivation flow, dashboard CTA, paused-customer nav context | Reactivation flow should accept pre-filled selections from local cart (user's browse choices become their restart box). |
| **Phase 4** (Weeks 9-10) | Cookie-based recognition, proactive outreach | No changes needed; passive recognition bar on browse pages complements the "Already a customer?" link. |

**Net schedule impact:** Minimal. The anonymous local cart is the only net-new engineering work (localStorage + carry-forward logic). Promo pricing suppression is a configuration change with A/B test wrapper. The "Already a customer?" link is a single-line addition.

---

## A.7 Reasoning Summary

| Decision | Position Adopted | Drawn From | Key Reasoning |
|---|---|---|---|
| No gate at "Add to Box" | Contrarian | Contrarian (primary), Main Recommendation's own principle (email at step 1, not before) | "Add" contract is immediate selection; modal breaks it. Two identification points create maintenance burden. |
| Anonymous local cart | Contrarian | Contrarian (proposed), CRO (compatible — preserves browse engagement) | Standard e-commerce paradigm. Carries user investment forward. Trivial to implement (localStorage). |
| Suppress promo pricing on browse | Contrarian (with test caveat) | Contrarian (proposed root-cause fix), UX (agreed pricing confusion is a problem) | False price expectations are the root cause of the negative checkout experience, not the lack of a gate. Must A/B test. |
| "Already a customer?" link | Hybrid | UX (soft identification), Contrarian (non-intrusive) | Zero friction. Always available. Respects user agency without gating. |
| Selections carry into onboarding | Hybrid | Contrarian (local cart → onboarding step 1), CRO (preserving user investment improves conversion) | Sunk cost effect works for us. User's browse effort is rewarded, not discarded. |

The synthesis follows the main recommendation's overarching philosophy: **make the right thing happen automatically, rather than asking users to identify themselves.** The browse experience becomes identity-agnostic — no gates, no modals, no pricing that depends on who you are. Identity resolution happens where it always should: at onboarding step 1, where the system has the tools to act on it.

---

*This addendum should be read in conjunction with the main recommendation. All section references (3a-e, Phase 1-4) refer to the parent document.*
