# Returning Customer Flow Redesign — Spec

**Date:** February 2026
**Status:** Proposal

---

## Problem

Existing customers frequently create duplicate subscriptions. They miss the login button, go through the signup wizard or browse via Range/Shop, and end up with two active subscriptions, losing their existing discounts.

## Goals

1. Stop existing customers going through the signup wizard again
2. Prevent dual subscription states
3. Stop existing customers seeing new-customer discounts they can't use
4. Fix navigation confusion from Shop/Range routes
5. Minimise friction for new customers
6. Make menu editing clear and simple for existing customers
7. Make it easy for paused customers to restart

---

## Changes

### 1. "Login to see your preferences" nudge at wizard start

Small, non-blocking prompt at the top of the onboarding wizard entry. Not a gate — new customers can ignore it and proceed. Gives returning customers a clear path to log in before investing time in the wizard.

### 2. Auto-detection at email capture (existing position)

When the customer enters their email (currently at the end of the wizard), perform a real-time account lookup. If the email matches an existing account:

- Show an inline message prompting them to log in
- Preserve their wizard selections so they carry forward into their account's edit-menu flow after login
- Differentiate messaging for active vs paused subscriptions

### 3. "Login to see your preferences" nudge on menu page (Range/Shop routes)

When a non-logged-in user arrives at the menu via Range or Shop navigation, show a small, non-blocking prompt at the top of the page. Same treatment as the wizard nudge — visible but not a gate.

### 4. Route logged-in customers to edit menu from all routes

Any navigation path (Range, Shop, direct links) resolves to the edit-menu experience for logged-in customers:

- "Add to Box" language instead of "Subscribe"
- No new-customer promo pricing shown
- Changes apply to their existing subscription

### 5. Restart deliveries CTA for paused customers on menu save

When a paused, logged-in customer saves their menu selections, show a contextual "Restart deliveries" CTA. They've just chosen their meals — this is the natural moment to reactivate.

### 6. Backend duplicate prevention (recommended)

Server-side rule: no email can have more than one active subscription. If a duplicate is attempted at checkout, block it and redirect to account management. This is the safety net that catches every edge case regardless of UI.

### 7. Standard pricing on Range/Shop browse pages

Show standard member pricing (not promotional pricing) on Range/Shop pages for non-logged-in users. New-customer promos are revealed inside the onboarding wizard after identity is established. CTA banners on browse pages can still advertise the offer to drive users into the wizard.

---

## Accepted tradeoffs

- **Email capture stays at end of wizard.** This means detection happens late for users who go through the full wizard. The nudge at wizard start is intended to catch most returning customers before they invest time. For those who miss it, the late detection is a safety catch — not ideal UX, but avoids impacting new-customer conversion by moving email earlier.
- **Range/Shop path relies on passive nudge + backend safety net.** Non-logged-in existing customers browsing via Range/Shop are caught by the "login to see your preferences" link or the backend de-dupe at checkout. There is no active detection layer between these two for this path. If the passive link has low engagement, some customers will still hit the checkout block after building a box. The standard pricing change mitigates this — the checkout catch is less painful when they haven't been browsing at promo prices they can't access.

---

## Implementation priority

1. **Nav routing for logged-in users** (change 4) — highest impact, eliminates the problem for all authenticated users
2. **Backend duplicate prevention** (change 6) — safety net, catches everything else
3. **Standard pricing on browse pages** (change 7) — removes false expectations
4. **Wizard nudge + email auto-detection** (changes 1 + 2) — catches returning customers in the signup flow
5. **Menu page nudge for Range/Shop** (change 3) — passive catch for browse path
6. **Paused customer restart CTA** (change 5) — reactivation opportunity
