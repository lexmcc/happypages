# Oatcult Shop Page Redesign — Spec

**Goal:** Reduce visual overwhelm on the product page by simplifying layout, replacing the carousel with a 2×2 card grid, and moving flavor detail into drawers.

**Parent context:** Client-reported issue is visual overwhelm (not decision paralysis). We're reducing noise without reducing choices.

**Scope:** Layout change + flavor card redesign + info drawer. Nothing else.

---

## Layout

### Desktop (>768px)

```
┌─────────────────────────────────────────────┐
│              HEADER (full width)             │
│  title, subtitle, reviews, benefits — as-is │
├──────────────────────┬──────────────────────┤
│   LEFT COL (50%)     │   RIGHT COL (50%)    │
│                      │   sticky             │
│   2×2 Flavor Grid    │   Size Cards (as-is) │
│                      │   Sub & Save (as-is) │
│                      │   Checkout CTA       │
└──────────────────────┴──────────────────────┘
```

- 50/50 split, equal columns
- Right column is sticky (current behavior)
- Gallery: **removed**
- Flavor tabs + description text: **removed** (content lives in drawer now)

### Mobile (<768px)

Single column stack:
1. Header
2. 2×2 Flavor Grid
3. Size Cards
4. Sub & Save
5. Checkout CTA

---

## Flavor Card (2×2 Grid)

### Card Anatomy

```
┌──────────────────────────┐
│ BADGE ←─────────── (i)   │  Badge: half-off top edge, optional
│ FLAVOR NAME              │  Name: uppercase, bold, top-left
│                          │
│      [product image]     │  Image: centered, natural bg
│                          │
│  ┌──────────────────┐    │
│  │  Choose / Chosen │    │  Button: full-width pill at bottom
│  └──────────────────┘    │
└──────────────────────────┘
```

- **Aspect ratio:** 3:4 (portrait)
- **Grid:** 2 columns, gap TBD (~12-16px)
- **Corner radius:** ~12-16px (match existing card radius)

### Card Elements

| Element | Position | Details |
|---------|----------|---------|
| Badge | Top-left, 50% above card edge | Pink pill, star icon, text (e.g. "BEST SELLER"). Optional — space closes up when absent. |
| Info icon (ⓘ) | Top-right, inside card | Circular icon. Tap opens drawer. |
| Flavor name | Top-left, inside card | Uppercase, bold. Left-aligned. Wraps to 2 lines if needed (makes space for ⓘ icon). |
| Product image | Center | Product on its existing photography background. No crop. |
| Choose/Chosen button | Bottom, full-width | Pill-shaped (border-radius: 9999px). Tap selects/deselects flavor. |

### Card States

| Property | Unselected | Selected |
|----------|-----------|----------|
| Card background | White / cream | Pink wash (match existing selection style) |
| Card border | Light grey | Pink |
| Button background | Pink gradient | Cream / white |
| Button border | Pink | Light grey |
| Button text | "Choose" | "Chosen" |
| Transition | — | 200-300ms smooth crossfade |

### Interaction Zones

Two distinct tap zones on each card:

1. **Card body** (image area + flavor name + ⓘ icon): Opens the info drawer
2. **Choose/Chosen button**: Selects or deselects the flavor

Selection logic: **unchanged** — uses existing single-select radio button behavior (`<variant-picker>` custom element, `is-selected` / `is-disabled` classes).

---

## Info Drawer

### Trigger
- Tap card body (image area / name)
- Tap ⓘ icon

### Desktop: Side Panel
- Width: 680px (`drawer--lg`)
- Slides in from right
- Overlay with semi-transparent backdrop
- Close: X button / backdrop click / Escape key

### Mobile: Bottom Sheet
- Height: ~80vh
- Rounded top corners
- Overlay with backdrop
- Close: X button / backdrop tap / swipe down
- Auto-closes when user taps "Choose" inside drawer

### Drawer Styling
Custom styled to match card aesthetic (pink accents, pill buttons, rounded elements). Not the theme's native drawer styling.

### Content Order (top to bottom)

1. **Flavor name** — heading at top
2. **Image gallery** — square images, horizontal scroll, pagination dots below
3. **Description** — text block
4. **Testimonial quote** — uses existing theme blockquote style (decorative SVG quote mark, bold text)
5. **Choose / Remove button** — toggles selection state, matches card button styling (pink when actionable, cream when selected)

Button scrolls with content (not sticky footer).

---

## Unchanged Components

These are explicitly out of scope:

- **Header** (title, subtitle, reviews, benefits) — keep as-is, ensure it spans full width above both columns
- **Size cards** — keep current design, reposition to right column above sub & save
- **Sub & save section** — keep as-is
- **Checkout CTA** — keep as-is
- **Selection logic** — existing single-select radio button / variant picker behavior
- **All other page sections** — no changes

---

## Resolved Decisions

- **Gap size:** 12px (8px on mobile <768px)
- **Selected card state:** Uses existing `--gradient-selected` (pink) and `--color-pink-border`
- **Drawer close animation:** Handled by theme's `<x-drawer>` component (clip-path transition)
- **ⓘ icon:** No tooltip on hover (just opens drawer on click)

---

## Implementation Notes

All changes are in a single file: `sections/shop-purchase-flow.liquid` (CSS + HTML + JS in one file).

**Removed:** Gallery column, flavor tabs, flavor description block, flavor carousel, and related JS methods (touch/swipe, carousel scroll, gallery navigation).

**Added:** `.flavor-grid` (2×2 CSS grid), `.flavor-grid__card` components, `<x-drawer id="flavor-info-drawer">` reusing the theme's Shadow DOM drawer, and Alpine.js drawer state/methods (`openDrawer`, `toggleFromDrawer`, `isDrawerFlavorSelected`, `scrollDrawerTo`).

**Selection logic:** Unchanged — `selectOption()`, `selectedBundle`, `selectedFlavors`, `bundleProductIds` all preserved as-is.

---
---

# Shop Page V3 Merge — Spec

**Goal:** Merge the best features from v1 (hero gallery, size cards) and v2 (additive qty picker, basket builder, mobile sticky basket) into a unified shop page.

**Parent context:** v1 and v2 each have strengths — v1 has a polished gallery and familiar size selection, v2 has better basket-building UX. Neither is complete on its own.

**Scope:** Functional merge with minimal styling changes. Reuse existing components as-is wherever possible.

---

## Layout

### Desktop (≥1000px)

```
┌─────────────────────────────────────────────┐
│              HEADER (full width)             │
│  title, subtitle, reviews, benefits — as-is │
├──────────────────────┬──────────────────────┤
│   LEFT COL           │   RIGHT COL (sticky) │
│                      │                      │
│   Hero Image         │   Flavour Carousel   │
│   Carousel           │   (horizontal scroll)│
│   (section settings) │                      │
│                      │   Free Delivery Bar  │
│                      │   Size Cards (r/o)   │
│                      │   Sub & Save         │
│                      │   Checkout CTA       │
│                      │   Trust Badges       │
└──────────────────────┴──────────────────────┘
```

- Left column: hero image carousel (static product/lifestyle images from section settings)
- Right column: sticky, contains all interactive elements
- Column split: ~50/50 (match current v1 proportions)

### Mobile (<1000px)

Single column stack:
1. Header
2. Hero Image Carousel
3. Flavour Cards (2-column grid)
4. Size Cards (read-only)
5. Sub & Save
6. Checkout CTA
7. Trust Badges

Free delivery progress bar lives in the **mobile sticky bar only** (not inline).

---

## Hero Image Carousel (LEFT column)

- **Source:** Section settings (admin uploads images in theme customizer)
- **Behaviour:** Horizontal scroll with snap, pagination dots
- **Desktop:** Fills left column, sticky alongside right column content
- **Mobile:** Full width at top, before flavour cards
- **Not flavour-reactive** — shows the same images regardless of selection state

---

## Flavour Cards

### Desktop: Horizontal Scroll Carousel

- Single row of cards, horizontally scrollable
- Arrow navigation (left/right) or swipe
- Sits at the top of the right column

### Mobile: 2-Column Grid

- Same card design, laid out as a 2×2+ grid
- Matches current v1 mobile layout

### Card Interaction

- **Tap card body / ⓘ icon** → opens info drawer (v2-style with image gallery + description + testimonial)
- **Tap Add button** → adds 1× 9-pack of that flavour to basket
- **Qty picker** (when qty > 0): shows −/qty/+ controls (v2 style)
- **No mutual exclusivity** — customer can add multiple flavours simultaneously

### Selection Model

- Each +1 in the picker = one 9-pack SKU of that flavour
- Minimum order: 1 SKU (9 packs total)
- No maximum
- SKU mapping: qty 1 → 9-pack SKU, qty 2 → 18-pack SKU, qty 3 → 27-pack SKU (per flavour)

---

## Info Drawer

Keep v2's info drawer as-is:
- Triggered by card body tap or ⓘ icon
- Desktop: side panel (680px, slides from right)
- Mobile: bottom sheet (~80vh)
- Content: flavour name → image gallery → description → testimonial → qty picker
- Close: X / backdrop / Escape

---

## Free Delivery Progress Bar

- **Desktop:** Sits above the size cards in the right column
- **Mobile:** Lives in the mobile sticky bar only (not shown inline)
- Same styling as v2 (cyan bar, percentage-based fill)
- Threshold: configurable via section settings (currently matches v2)

---

## Box Size Cards (Read-Only, Sliding Viewport)

- **12 tiers** (9, 18, 27, … 108 packs) displayed in a 3-card sliding viewport
- **Non-interactive** — no tap/click behaviour
- Current tier is **highlighted** based on basket total (e.g. 8 SKUs = 72 → "72" card highlighted)
- Viewport auto-slides to center the active tier in the visible 3-card window
- Cards beyond the first 3 tiers show computed prices (from variant breakdown) but no images until configured in theme editor
- Position: right column, below free delivery bar, above sub & save

---

## Sub & Save

Keep from v1/v2 with these removals:
- ✅ Toggle switch (subscribe on by default)
- ✅ Benefit list with checkmarks
- ✅ Frequency dropdown
- ✅ Savings pill
- ❌ **Remove:** 20% off benefit card
- ❌ **Remove:** Free delivery unlock benefit card

Pricing calculated from basket qty (v2 logic).

---

## Mobile Sticky Bar

Simplified from v2:
- ❌ **Remove:** Collapsible slot grid drawer
- ✅ Free delivery progress bar
- ✅ Free delivery badge
- ✅ CTA checkout button with price
- ✅ "subscribing & saving £x.xx" pill — shows when subscribe & save is on and items in box (dark brown bg, baby blue text, scale+fade transition)
- Appears when scrolling past the purchase section

---

## Checkout Flow

- Direct to checkout (no cart page) — same as v1/v2
- `checkout()` maps basket quantities to correct SKU sizes:
  - 1 qty of a flavour → 9-pack SKU
  - 2 qty → 18-pack SKU
  - 3 qty → 27-pack SKU
- Validation: must have ≥1 SKU in basket

---

## Open Questions

- **Hero carousel arrows vs dots:** Both? Dots only? Arrows + dots?
- **Free delivery threshold:** Same as v2 (12 packs)? Or different?

---

## Technical Notes

- All code in a single Liquid section file (CSS + HTML + JS)
- Alpine.js for state management
- Theme's `<x-drawer>` component for info drawer
- Section settings for hero images and configurable thresholds
- SKU data comes from Shopify product variants (metafield or tag-based size mapping)
