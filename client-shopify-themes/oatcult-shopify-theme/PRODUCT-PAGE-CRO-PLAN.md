# Oat Cult Product Page Redesign

## Executive Summary

Complete redesign of the product purchase flow to maximize conversion rate and AOV through:
- **Direct-to-checkout** (no cart page)
- **Clear tier-based box size selection**
- **Subscription-first design** with prominent savings
- **Simplified flavor selection** (Mixed Box OR individual picks)
- **Strategic free shipping upsell** at £40 threshold

**Expected Impact:**
| Metric | Current | Target | Driver |
|--------|---------|--------|--------|
| Conversion Rate | Baseline | +25-40% | Reduced confusion, direct checkout |
| Subscription Rate | Baseline | +40-60% | Subscription-first, clear savings |
| AOV | Baseline | +15-20% | Free shipping upsell, multi-flavor |

---

## Product & SKU Structure

### Available SKUs
Each flavor comes in **pre-packed boxes** - not customizable:

| SKU | 9-pack | 18-pack | 27-pack |
|-----|--------|---------|---------|
| Mixed Box | ✓ | ✓ | ✓ |
| Cacao | ✓ | ✓ | ✓ |
| Cinnamon | ✓ | ✓ | ✓ |
| Strawberry Goji | ✓ | ✓ | ✓ |

### Pricing
| Size | Full Price | Subscription (20% off) | Per Pack |
|------|-----------|------------------------|----------|
| 9-pack | £18.00 | £14.40 | £1.60 |
| 18-pack | £36.00 | £28.80 | £1.60 |
| 27-pack | £54.00 | £43.20 | £1.60 |

### Free Shipping Threshold: £40+
| Selection | Sub Price | Free Shipping |
|-----------|-----------|---------------|
| 1× 9-pack | £14.40 | ❌ Need £25.60 more |
| 1× 18-pack | £28.80 | ❌ Need £11.20 more |
| 1× 27-pack | £43.20 | ✅ Qualifies |
| 2× 18-pack | £57.60 | ✅ Qualifies |
| 3× 18-pack | £86.40 | ✅ Qualifies |

---

## User Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   STEP 1    │───▶│   STEP 2    │───▶│   STEP 3    │         │
│  │  Box Size   │    │   Flavor    │    │  Sub/Buy    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│        │                  │                  │                  │
│        ▼                  ▼                  ▼                  │
│   9 / 18 / 27        Mixed Box OR       Subscribe 20%          │
│   (18 default)       Pick 1-3 own       or One-time            │
│                      (Mixed default)    (Sub default)          │
│                                                                 │
│                              │                                  │
│                              ▼                                  │
│                    ┌─────────────────┐                         │
│                    │ DIRECT CHECKOUT │                         │
│                    │   (no cart)     │                         │
│                    └─────────────────┘                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Flavor Selection Rules
- **Mutually exclusive:** Mixed Box OR individual flavors (not both)
- **Mixed Box** = pre-selected default (best for undecided customers)
- **Pick your own** = select 1-3 individual flavors
- Clicking Mixed Box → unchecks all individuals
- Clicking any individual → unchecks Mixed Box

---

## Desktop Layout Specification

### Overall Grid
```
┌────────────────────────────────────────────────────────────────────────┐
│                           HEADER / NAV                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   ┌──────────────────────┐     ┌──────────────────────────────────┐   │
│   │                      │     │                                  │   │
│   │    MEDIA COLUMN      │     │      PURCHASE COLUMN             │   │
│   │    (Product images)  │     │      (All purchase controls)     │   │
│   │                      │     │                                  │   │
│   │    Width: 50%        │     │      Width: 50%                  │   │
│   │    Max: 600px        │     │      Max: 540px                  │   │
│   │                      │     │                                  │   │
│   └──────────────────────┘     └──────────────────────────────────┘   │
│                                                                        │
│   Gap: 48px (--spacing-12)                                             │
│   Container max-width: 1200px                                          │
│   Padding: 0 24px                                                      │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Purchase Column Structure
```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  OVERNIGHT GUT OATS                        ← Product title   │
│  Delicious overnight oats. Just add milk.  ← Subtitle        │
│                                                              │
│  ⭐⭐⭐⭐⭐ 5.0 from 200+ reviews              ← Social proof   │
│                                                              │
│  ─────────────────────────────────────────  ← Divider        │
│                                                              │
│  CHOOSE YOUR BOX SIZE                      ← Section header  │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    ← Size cards      │
│  │ STARTER  │ │ POPULAR  │ │BEST VALUE│                      │
│  │ 9 packs  │ │ 18 packs │ │ 27 packs │                      │
│  │ £18.00   │ │ £36.00   │ │ £54.00   │                      │
│  └──────────┘ └──────────┘ └──────────┘                      │
│                                                              │
│  ─────────────────────────────────────────                   │
│                                                              │
│  PICK YOUR FLAVORS                         ← Section header  │
│                                                              │
│  ┌────────────────────────────────────┐    ← Mixed Box card  │
│  │ ● Mixed Box - £36.00               │                      │
│  │   All 3 flavors in one box         │                      │
│  └────────────────────────────────────┘                      │
│                                                              │
│  ┌────────────────────────────────────┐    ← Pick own card   │
│  │ ○ Pick your own (1-3 flavors)      │                      │
│  │   ┌────────────────────────────┐   │                      │
│  │   │ ☐ Cacao       £36.00       │   │                      │
│  │   │ ☐ Cinnamon    £36.00       │   │                      │
│  │   │ ☐ Strawberry  £36.00       │   │                      │
│  │   └────────────────────────────┘   │                      │
│  └────────────────────────────────────┘                      │
│                                                              │
│  ─────────────────────────────────────────                   │
│                                                              │
│  ┌────────────────────────────────────┐    ← Subscribe card  │
│  │ ● SUBSCRIBE & SAVE 20%    £28.80   │                      │
│  │   ✓ Delivered monthly              │                      │
│  │   ✓ Skip or cancel anytime         │                      │
│  │   ✓ Free shipping on orders £40+   │                      │
│  │                                    │                      │
│  │   💚 You save £7.20                │                      │
│  │   💡 Add another flavor for FREE   │  ← Upsell nudge     │
│  │      shipping                      │                      │
│  └────────────────────────────────────┘                      │
│                                                              │
│  ┌────────────────────────────────────┐    ← One-time card   │
│  │ ○ One-time purchase       £36.00   │                      │
│  └────────────────────────────────────┘                      │
│                                                              │
│  ┌────────────────────────────────────┐    ← CTA button      │
│  │                                    │                      │
│  │     SUBSCRIBE NOW · £28.80         │                      │
│  │     1× Mixed Box (18 packs)        │  ← Order summary     │
│  │                                    │                      │
│  └────────────────────────────────────┘                      │
│                                                              │
│  🚚 Free £40+ · ↩️ 30-day · 🔒 Secure   ← Trust badges       │
│                                                              │
│  "Finally healthy oats that taste      ← Testimonial         │
│   amazing!" — Sarah T. ✓ Subscriber                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. Box Size Cards

**Layout:** 3 cards in a row, equal width, 12px gap

```
┌─────────────────┐
│     STARTER     │  ← Label (uppercase, 11px, letter-spacing: 0.05em)
│                 │
│     9 packs     │  ← Pack count (16px, semi-bold)
│     ~1 week     │  ← Duration hint (12px, muted)
│                 │
│     £18.00      │  ← Price (20px, bold)
│   £2.00/pack    │  ← Per-pack price (11px, muted)
└─────────────────┘
```

**States:**
| State | Background | Border | Text |
|-------|------------|--------|------|
| Default | `#FFFFFF` | `1px solid #E5E5E5` | `#333333` |
| Hover | `#FAFAFA` | `1px solid #CCCCCC` | `#333333` |
| Selected | `#FFF8F0` | `2px solid #8B4513` | `#8B4513` (brand brown) |
| Disabled | `#F5F5F5` | `1px solid #E5E5E5` | `#999999` |

**Badges:**
- **POPULAR** (18-pack): Gold star icon + "POPULAR" label
- **BEST VALUE** (27-pack): Truck icon + "FREE SHIPPING" label (green)

**CSS:**
```css
.size-card {
  padding: 16px;
  border-radius: 12px;
  text-align: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.size-card--selected {
  background: #FFF8F0;
  border: 2px solid var(--brand-brown);
  box-shadow: 0 2px 8px rgba(139, 69, 19, 0.15);
}

.size-card__badge {
  position: absolute;
  top: -8px;
  left: 50%;
  transform: translateX(-50%);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}

.size-card__badge--popular {
  background: #FFD700;
  color: #333;
}

.size-card__badge--free-ship {
  background: #22C55E;
  color: white;
}
```

---

### 2. Flavor Selection

**Structure:** Radio group with nested checkboxes

```
┌─────────────────────────────────────────────────────┐
│ ● 🎨 MIXED BOX                          £36.00     │
│                                                     │
│   All 3 flavors in one box — can't decide?         │
│   This is the one for you.                         │
│                                          ⭐ Popular │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ ○ PICK YOUR OWN                                     │
│   Select 1-3 individual flavors                     │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ ☐ 🟫 Cacao                        £36.00    │   │
│   │    Rich chocolate oats             🔥 #1     │   │
│   ├─────────────────────────────────────────────┤   │
│   │ ☐ 🟤 Cinnamon                     £36.00    │   │
│   │    Warming cinnamon spice                   │   │
│   ├─────────────────────────────────────────────┤   │
│   │ ☐ 🍓 Strawberry Goji              £36.00    │   │
│   │    Fruity & refreshing                      │   │
│   └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**Behavior:**
1. Mixed Box selected by default (radio button filled)
2. Individual flavor checkboxes are DISABLED when Mixed Box selected
3. Clicking "Pick your own" or any individual flavor:
   - Unchecks Mixed Box
   - Enables individual checkboxes
   - Auto-checks the clicked flavor (if clicking individual)
4. Must have at least 1 flavor selected (validation)
5. Max 3 individual flavors

**CSS:**
```css
.flavor-option {
  padding: 16px 20px;
  border-radius: 12px;
  border: 1px solid #E5E5E5;
  margin-bottom: 12px;
  transition: all 0.15s ease;
}

.flavor-option--selected {
  border-color: var(--brand-brown);
  background: #FFF8F0;
}

.flavor-option__nested {
  margin-top: 12px;
  padding: 12px;
  background: #FAFAFA;
  border-radius: 8px;
  opacity: 0.5;
  pointer-events: none;
}

.flavor-option--pick-own.flavor-option--selected .flavor-option__nested {
  opacity: 1;
  pointer-events: auto;
}

.flavor-checkbox {
  display: flex;
  align-items: center;
  padding: 12px;
  border-bottom: 1px solid #EEEEEE;
  cursor: pointer;
}

.flavor-checkbox:last-child {
  border-bottom: none;
}

.flavor-checkbox--checked {
  background: #FFF8F0;
}

.flavor-checkbox__badge {
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 4px;
  background: #FF6B35;
  color: white;
}
```

---

### 3. Subscribe/One-time Toggle

**Structure:**
```
┌─────────────────────────────────────────────────────┐
│ ● SUBSCRIBE & SAVE 20%                     £28.80  │
│   ──────────────────────────────────────────────   │
│   ✓ Delivered monthly to your door                 │
│   ✓ Skip or cancel anytime (2 clicks)              │
│   ✓ Free shipping on orders £40+                   │
│                                                     │
│   💚 You save £7.20 vs one-time                    │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ 💡 Add another flavor for FREE shipping     │   │
│   └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ ○ One-time purchase                        £36.00  │
└─────────────────────────────────────────────────────┘
```

**States:**
- Subscribe card: Selected by default, expanded with benefits
- One-time card: Collapsed, shows only price

**Upsell Logic:**
```javascript
const subTotal = selectedFlavors.length * boxPrice * 0.8;
const freeShipThreshold = 40;

if (subTotal < freeShipThreshold) {
  const gap = freeShipThreshold - subTotal;

  if (gap <= boxPrice * 0.8) {
    // Can reach threshold by adding 1 more flavor
    showNudge("Add another flavor for FREE shipping");
  } else {
    // Need to upgrade box size
    showNudge("Upgrade to 27-pack for FREE shipping");
  }
}
```

---

### 4. CTA Button

**Structure:**
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│            SUBSCRIBE NOW · £28.80                   │
│            1× Mixed Box (18 packs)                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Dynamic Content:**
- Primary text: "SUBSCRIBE NOW" or "BUY NOW" based on selection
- Price: Updates based on selection + discount
- Summary: "1× Mixed Box (18 packs)" or "2× 18-pack (Cacao, Cinnamon)"

**States:**
| State | Background | Text | Cursor |
|-------|------------|------|--------|
| Default | `var(--brand-brown)` | White | pointer |
| Hover | `var(--brand-brown-dark)` | White | pointer |
| Active | `var(--brand-brown-darker)` | White | pointer |
| Disabled | `#CCCCCC` | `#666666` | not-allowed |
| Loading | `var(--brand-brown)` | Spinner | wait |

**CSS:**
```css
.cta-button {
  width: 100%;
  padding: 20px 24px;
  border-radius: 12px;
  background: var(--brand-brown);
  color: white;
  font-size: 16px;
  font-weight: 600;
  text-align: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.cta-button:hover {
  background: var(--brand-brown-dark);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(139, 69, 19, 0.25);
}

.cta-button__summary {
  font-size: 13px;
  font-weight: 400;
  opacity: 0.9;
  margin-top: 4px;
}
```

---

### 5. Trust Badges

**Layout:** Horizontal row, centered, icon + text

```
🚚 Free shipping £40+  ·  ↩️ 30-day guarantee  ·  🔒 Secure checkout
```

**CSS:**
```css
.trust-badges {
  display: flex;
  justify-content: center;
  gap: 16px;
  padding: 16px 0;
  font-size: 12px;
  color: #666666;
}

.trust-badge {
  display: flex;
  align-items: center;
  gap: 4px;
}

.trust-badge__icon {
  font-size: 14px;
}
```

---

### 6. Testimonial

**Structure:**
```
"Finally healthy oats that taste amazing!"
— Sarah T. ✓ Verified subscriber
```

**CSS:**
```css
.testimonial {
  padding: 16px;
  text-align: center;
}

.testimonial__quote {
  font-size: 14px;
  font-style: italic;
  color: #333333;
  margin-bottom: 8px;
}

.testimonial__author {
  font-size: 12px;
  color: #666666;
}

.testimonial__verified {
  color: #22C55E;
}
```

---

## Mobile Layout (< 768px)

### Key Changes
1. Single column layout
2. Product image carousel at top
3. Size cards: horizontal scroll or 3-up compact
4. Flavor options: full width, stacked
5. Sticky CTA at bottom of viewport

```
┌─────────────────────────────────┐
│       [PRODUCT CAROUSEL]        │
│         ● ○ ○ ○                 │
├─────────────────────────────────┤
│ OVERNIGHT GUT OATS              │
│ ⭐⭐⭐⭐⭐ 5.0 · 200+ reviews     │
├─────────────────────────────────┤
│ BOX SIZE                        │
│ ┌───────┐┌───────┐┌───────┐    │
│ │   9   ││  18   ││  27   │    │
│ │ £18   ││ £36 ⭐││ £54 🚚│    │
│ └───────┘└───────┘└───────┘    │
├─────────────────────────────────┤
│ FLAVORS                         │
│ ┌─────────────────────────────┐ │
│ │ ● Mixed Box      £36    ⭐  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ○ Pick your own:            │ │
│ │   ☐ Cacao        £36    🔥  │ │
│ │   ☐ Cinnamon     £36        │ │
│ │   ☐ Strawberry   £36        │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ ● Subscribe 20%    £28.80   │ │
│ │   ✓ Monthly · ✓ Cancel any  │ │
│ │   💡 +1 flavor = FREE ship  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ○ One-time         £36.00   │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [STICKY CTA BAR]                │
│ ┌─────────────────────────────┐ │
│ │  SUBSCRIBE NOW · £28.80     │ │
│ │  1× Mixed Box (18 packs)    │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Sticky CTA Bar
```css
.sticky-cta {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 12px 16px;
  padding-bottom: calc(12px + env(safe-area-inset-bottom));
  background: white;
  border-top: 1px solid #E5E5E5;
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.08);
  z-index: 100;
}
```

---

## Interaction States & Animations

### Transitions
```css
:root {
  --transition-fast: 0.1s ease;
  --transition-normal: 0.15s ease;
  --transition-slow: 0.25s ease;
}
```

### Size Card Selection
```css
.size-card {
  transition:
    border-color var(--transition-normal),
    background-color var(--transition-normal),
    box-shadow var(--transition-normal),
    transform var(--transition-fast);
}

.size-card:active {
  transform: scale(0.98);
}
```

### Flavor Selection Toggle
```javascript
// When clicking individual flavor while Mixed Box is selected:
// 1. Fade out Mixed Box selection
// 2. Enable and fade in individual checkboxes
// 3. Check the clicked flavor

const transition = {
  duration: 150,
  easing: 'ease-out'
};
```

### Price Updates
```css
.price {
  transition: opacity var(--transition-fast);
}

.price--updating {
  opacity: 0.5;
}
```

---

## Accessibility

### Keyboard Navigation
- Tab order: Size cards → Flavor options → Subscribe/One-time → CTA
- Arrow keys navigate within radio groups
- Space/Enter to select
- Focus indicators: 2px outline with 2px offset

### ARIA
```html
<div role="radiogroup" aria-label="Box size">
  <div role="radio" aria-checked="false" tabindex="0">9 packs</div>
  <div role="radio" aria-checked="true" tabindex="-1">18 packs</div>
  <div role="radio" aria-checked="false" tabindex="-1">27 packs</div>
</div>

<div role="radiogroup" aria-label="Flavor selection">
  <div role="radio" aria-checked="true">Mixed Box</div>
  <div role="radio" aria-checked="false">
    Pick your own
    <div role="group" aria-label="Individual flavors" aria-disabled="true">
      <div role="checkbox" aria-checked="false">Cacao</div>
      <div role="checkbox" aria-checked="false">Cinnamon</div>
      <div role="checkbox" aria-checked="false">Strawberry</div>
    </div>
  </div>
</div>
```

### Screen Reader Announcements
```javascript
// Announce price changes
announceToScreenReader(`Total updated to ${formatPrice(newTotal)}`);

// Announce selection changes
announceToScreenReader(`${flavorName} ${isChecked ? 'added' : 'removed'}`);
```

---

## Error States

### No Flavor Selected
If user unchecks all flavors:
- Show inline error: "Please select at least one flavor"
- Disable CTA button
- Highlight flavor section with red border

### Max Flavors Reached
When 3 individual flavors selected:
- Disable remaining checkboxes
- Show helper text: "Maximum 3 flavors selected"
- Unchecked flavors: gray out with "Max reached" tooltip

---

## Direct Checkout Implementation

### Checkout URL Structure
```javascript
// Shopify direct checkout URL
const buildCheckoutUrl = (selections) => {
  const lineItems = selections.map(({ variantId, quantity }) =>
    `line_items[][variant_id]=${variantId}&line_items[][quantity]=${quantity}`
  ).join('&');

  return `/checkout?${lineItems}`;
};

// Example: 18-pack Mixed Box (subscription)
// /checkout?line_items[][variant_id]=12345678&line_items[][quantity]=1&selling_plan=87654321

// Example: 18-pack Cacao + 18-pack Cinnamon (subscription)
// /checkout?line_items[][variant_id]=11111111&line_items[][quantity]=1&line_items[][variant_id]=22222222&line_items[][quantity]=1&selling_plan=87654321
```

### Subscription Integration
- Use selling_plan parameter for subscription checkout
- Requires ReCharge or similar subscription app
- Selling plan ID maps to the 20% monthly subscription

---

## Files to Modify

### Primary
- `sections/main-product.liquid` - Main product template
- `snippets/product-form.liquid` - Form handling (if exists)

### Supporting
- `assets/product-page.css` - New styles (or inline in section)
- `assets/product-page.js` - Interaction logic
- `snippets/product-size-card.liquid` - Size card component
- `snippets/product-flavor-selector.liquid` - Flavor selector component

### Data
- Product metafields or variant structure for:
  - Per-pack price calculation
  - Duration hints (~1 week, ~2 weeks, ~4 weeks)
  - Popularity badges
  - Stock status (for urgency signals)

---

## Implementation Phases

### Phase 1: Core Structure
- [ ] Box size selection cards
- [ ] Basic flavor selection (Mixed Box only)
- [ ] Subscribe/One-time toggle
- [ ] CTA with direct checkout

### Phase 2: Full Flavor Selection
- [ ] "Pick your own" with individual flavor checkboxes
- [ ] Mutual exclusivity logic
- [ ] 3-flavor cap
- [ ] Dynamic price updates

### Phase 3: Upsells & Polish
- [ ] Free shipping nudge
- [ ] Trust badges
- [ ] Testimonial
- [ ] Mobile sticky CTA
- [ ] Animations & transitions

### Phase 4: Optimization
- [ ] A/B test setup
- [ ] Analytics events
- [ ] Performance optimization

---

## Verification Checklist

### Functional
- [ ] Size selection updates price correctly
- [ ] Flavor selection: Mixed Box ↔ individual mutual exclusivity works
- [ ] Max 3 individual flavors enforced
- [ ] Subscribe applies 20% discount
- [ ] Free shipping nudge appears when < £40
- [ ] CTA text changes: "Subscribe Now" vs "Buy Now"
- [ ] Direct checkout URL builds correctly
- [ ] Multiple SKUs in checkout work

### Visual
- [ ] Desktop layout matches spec
- [ ] Mobile layout matches spec
- [ ] Sticky CTA on mobile
- [ ] All states render correctly (hover, selected, disabled)
- [ ] Animations smooth, not jarring

### Accessibility
- [ ] Full keyboard navigation
- [ ] Screen reader announces changes
- [ ] Focus indicators visible
- [ ] Color contrast passes WCAG AA

### Edge Cases
- [ ] Empty state: at least 1 flavor required
- [ ] Max state: 3 individual flavors, 4th disabled
- [ ] Rapid clicking doesn't break state
- [ ] Back button preserves selections
