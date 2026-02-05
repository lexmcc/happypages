# Shop Purchase Flow Design Spec

> **Status:** Authoritative design spec for the current pink gradient design system.
>
> This document supersedes [PRODUCT-PAGE-CRO-PLAN.md](./PRODUCT-PAGE-CRO-PLAN.md), which describes an earlier brown/cream design iteration.

---

## Design System

### Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| `--color-pink-dark` | `#F05E87` | Selected state primary, toggle active |
| `--color-pink-light` | `#FFBED6` | Selected state secondary, gradient end |
| `--color-pink-border` | `#B45B7E` | Selected card border |
| `--color-cream` | `#F0E9DE` | Unselected background, benefits section |
| `--color-border-light` | `#CDCDCD` | Unselected border |
| `--color-chevron` | `#361A05` | Chevron/arrow icons |
| `--color-locked-overlay` | `rgba(54, 26, 5, 0.9)` | Locked content overlay |
| `--color-locked-border` | `#361A05` | Locked content border |

### CTA Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--color-cta-yellow` | `#FFE500` | CTA button background |
| `--color-cta-yellow-hover` | `#E8C300` | CTA button hover |
| CTA button | `#FED700` | Actual button (slight variance) |
| CTA border | `#E0C426` | Button border |

### Badge Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--spf-badge-popular` | `#fbbf24` | POPULAR badge (gold) |
| `--spf-badge-success` | `#22c55e` | FREE SHIP badge (green) |
| `--spf-badge-hot` | `#ff6b35` | Hot/trending badge (orange) |
| `--spf-badge-featured` | `#ec4899` | Featured badge (pink) |

### Gradients

| Token | Value | Usage |
|-------|-------|-------|
| `--gradient-unselected` | `linear-gradient(to bottom, #FFFFFF 0%, #F0E9DE 100%)` | Unselected cards |
| `--gradient-selected` | `linear-gradient(to bottom, #F05E87 0%, #FFBED6 100%)` | Selected cards |
| `--gradient-sub-section` | `linear-gradient(to bottom right, #FFBED6 0%, #F05E87 100%)` | Subscribe section active |

### Z-Index Scale

| Token | Value | Usage |
|-------|-------|-------|
| `--z-base` | `1` | Base layer |
| `--z-card-hover` | `5` | Hovered cards |
| `--z-dropdown` | `10` | Dropdowns, carousel arrows |
| `--z-sticky` | `100` | Sticky CTA |

### Transitions

| Token | Value | Usage |
|-------|-------|-------|
| `--transition-fast` | `0.1s ease` | Quick interactions |
| `--transition-normal` | `0.15s ease-out` | Standard transitions |

Respects `prefers-reduced-motion` - sets durations to 0s.

---

## Layout

### Desktop (≥1000px)

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│   ┌──────────────────────┐     ┌──────────────────────────────┐   │
│   │                      │     │                              │   │
│   │    GALLERY COLUMN    │     │    PURCHASE COLUMN           │   │
│   │    (Product images)  │     │    (All purchase controls)   │   │
│   │                      │     │                              │   │
│   │    50% width         │     │    50% width                 │   │
│   │                      │     │                              │   │
│   └──────────────────────┘     └──────────────────────────────┘   │
│                                                                    │
│   Gap: var(--spacing-12) (48px)                                    │
│   Container max-width: 1200px                                      │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### Mobile (<1000px)

- Single column layout
- Gallery stacks above purchase column
- Sticky CTA bar at bottom
- Safe area inset for notched devices

---

## Components

### 1. Flavor Carousel

Horizontal scrollable carousel for flavor selection.

**Layout:**
- Cards: `width: calc(25% - 9px)`, `min-width: 140px`
- Mobile: `width: calc(33.333% - 8px)`, `min-width: 120px`
- Aspect ratio: 3:4
- Gap: 12px
- Scroll snap: `x mandatory`

**Card States:**

| State | Background | Border | Text |
|-------|------------|--------|------|
| Unselected | `--gradient-unselected` | `1px solid --color-border-light` | Dark |
| Hover | Same + scale(1.02) | Same | Dark |
| Selected | `--gradient-selected` | `1px solid --color-pink-border` | White |

**Structure:**
```
┌─────────────────────┐
│ [POPULAR badge]     │  ← Optional badge, top-right
│                     │
│    ┌───────────┐    │
│    │   IMAGE   │    │  ← Product image, centered
│    └───────────┘    │
│                     │
│    FLAVOR NAME      │  ← Uppercase, bold
│    Selected         │  ← Label (when selected)
└─────────────────────┘
```

**Arrows:**
- Desktop only (hidden on mobile)
- Position: absolute, centered vertically
- Background: `--gradient-unselected`
- Border: `1px solid --color-border-light`
- Size: 40×40px (44px min touch target)

---

### 2. Size Cards

3-column grid for pack size selection.

**Layout:**
- Grid: `repeat(3, 1fr)`
- Gap: 12px (desktop), 8px (mobile)
- Touch target: min-height 44px

**Card States:**

| State | Background | Border | Text |
|-------|------------|--------|------|
| Unselected | `--gradient-unselected` | `1px solid --color-border-light` | Dark |
| Hover | Same + scale(1.02) | Same | Dark |
| Selected | `--gradient-selected` | `1px solid --color-pink-border` | White |

**Structure:**
```
┌─────────────────────┐
│     [BADGE]         │  ← Position: absolute, top -10px, centered
│                     │
│    ┌───────────┐    │
│    │   IMAGE   │    │  ← Product image (80px height)
│    └───────────┘    │
│                     │
│      9 PACKS        │  ← Pack count, bold
│       £18.00        │  ← Price, bold
│    £2.00/pack       │  ← Per-pack, muted
└─────────────────────┘
```

**Badges:**

| Badge | Background | Text | Placement |
|-------|------------|------|-----------|
| POPULAR | `--spf-badge-popular` (#fbbf24) | Dark | 18-pack |
| FREE SHIP | `--spf-badge-success` (#22c55e) | White | 27-pack |

---

### 3. Subscribe Section

Toggleable subscription option with iOS-style switch.

**States:**

| State | Background | Border | Text |
|-------|------------|--------|------|
| Inactive | White | `1px solid --color-border-light` | Dark, 50% opacity, grayscale |
| Active | `--gradient-sub-section` | `1px solid --color-pink-border` | White |

**Toggle Switch:**
- Width: 52px, Height: 32px
- Track inactive: `--color-border-light`
- Track active: `--color-pink-dark` (#F05E87)
- Circle: 28px white with shadow
- Transition: 0.15s ease-out

**Structure:**
```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐    │
│  │  SUB & SAVE                    £28.80      [====O]  │    │  ← Header with toggle
│  │  Monthly delivery              £1.60/pack           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                       │
│  │ Benefit │ │ Benefit │ │ Benefit │                       │  ← Benefit cards
│  │  Card 1 │ │  Card 2 │ │ [LOCKED]│                       │
│  └─────────┘ └─────────┘ └─────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

**Benefit Cards:**
- Square aspect ratio (1:1)
- Locked state: dark overlay with lock icon
- Overlay: `--color-locked-overlay`

---

### 4. CTA Button

Full-width yellow action button.

**Specs:**
- Background: `#FED700`
- Border: `1px solid #E0C426`
- Border-radius: 60px (pill shape)
- Padding: var(--spacing-5) var(--spacing-6)
- Font: bold, uppercase

**States:**

| State | Background | Transform | Shadow |
|-------|------------|-----------|--------|
| Default | `#FED700` | none | none |
| Hover | `#E8C300` | translateY(-1px) | `0 4px 12px rgba(254, 215, 0, 0.4)` |
| Active | `#E8C300` | translateY(0) | none |
| Disabled | 20% opacity text-primary | none | none |

**Content:**
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                  SUBSCRIBE NOW · £28.80                     │  ← Primary text
│                1× Mixed Box (18 packs)                      │  ← Summary (optional)
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 5. Mobile Sticky CTA

Fixed bar at bottom of viewport on mobile.

**Specs:**
- Position: fixed, bottom: 0
- Padding: var(--spacing-3) var(--spacing-4)
- Padding-bottom includes `env(safe-area-inset-bottom)`
- Background: rgb(var(--background-primary))
- Border-top: 1px solid border color
- Shadow: `0 -4px 12px` with 8% opacity
- Z-index: 100

**Breakpoint:** Shows below 1000px

---

### 6. Gallery

Product image display with thumbnail navigation.

**Main Image:**
- Aspect ratio: 1:1
- Border-radius: 12px (desktop), 8px (mobile)
- Overflow: hidden

**Thumbnails:**
- Size: 72×72px
- Border-radius: 8px
- Gap: 8px
- Horizontal scroll on overflow
- Active state: 2px solid text color
- Hover: 2px solid #ccc

**Navigation Arrows:**
- Desktop only (appear on hover)
- 40×40px circular buttons
- Position: absolute, centered vertically
- Background: rgba(255, 255, 255, 0.9)

---

### 7. Benefits Badges

Located below gallery on desktop, in purchase column on mobile.

**Container:**
- Background: `#F0E9DE` (cream)
- Border-radius: 12px
- Padding: 16px

**Benefit Item:**
- Icon: 24×24px
- Gap: var(--spacing-3)
- Font-size: var(--text-sm)

---

## Accessibility

### Focus States

- Focus-visible: `2px solid --color-pink-dark`
- Outline offset: 2px
- Mouse focus (`:focus:not(:focus-visible)`): no outline

### Touch Targets

- Minimum: 44×44px
- Applied to: buttons, carousel arrows, toggle, cards

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  --transition-fast: 0s;
  --transition-normal: 0s;
  /* All animations disabled */
}
```

### Tabular Numbers

Price and numeric displays use:
```css
font-variant-numeric: tabular-nums;
```

---

## Interaction Patterns

### Flavor Selection

- **Mutual exclusivity:** One flavor selected at a time (radio behavior)
- Clicking a flavor card selects it and deselects others
- Gallery updates to show selected flavor's product images

### Size Selection

- **Mutual exclusivity:** One size selected at a time
- Default: Middle option (18-pack) pre-selected
- Prices update based on subscription state

### Subscribe Toggle

- **Default:** Subscription enabled
- Toggle switches between subscription and one-time pricing
- Visual feedback: gradient background, white text when active
- Benefit cards unlock/lock based on state

### Direct Checkout

No cart page - CTA goes directly to Shopify checkout with:
- Selected variant ID(s)
- Quantity
- Selling plan (if subscription)

---

## Responsive Breakpoints

| Breakpoint | Layout |
|------------|--------|
| ≥1000px | 2-column grid (gallery + purchase) |
| <1000px | Single column, sticky CTA appears |
| <768px | Mobile-optimized spacing, touch targets |

---

## Files

| File | Purpose |
|------|---------|
| `sections/shop-purchase-flow.liquid` | Main section with all CSS and HTML |
| `templates/page.shop.json` | JSON template that includes this section |

---

## Version History

| Date | Change |
|------|--------|
| Feb 2026 | Pink gradient design system implemented |
| Feb 2026 | Design spec documented (this file) |
