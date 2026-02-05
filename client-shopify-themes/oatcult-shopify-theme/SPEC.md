# Oat Cult Shopify Theme Spec

## Overview

Shopify theme for Oat Cult based on the Impact theme (v6.0.1) by Maestrooo. Online Store 2.0 theme with JSON templates and Liquid.

**Store:** oatcult.myshopify.com

---

## Completed Features

- [x] Base Impact theme setup (v6.0.1)
- [x] Custom shop purchase flow (`sections/shop-purchase-flow.liquid`)
  - Flavor-first selection with IKEA/endowment effect
  - Adaptive size options (9/18/27 packs)
  - Subscription-first design with 20% savings
  - Multi-flavor box builder (Mixed Box or pick 1-3)
  - Direct-to-checkout (no cart)
  - Unified flavor card architecture (bundle/individual via blocks)
- [x] Alpine.js reactive components
- [x] Okendo reviews integration
- [x] Beae page builder integration
- [x] Custom fonts (Rudolph, Apercu)
- [x] Shopify native Selling Plans API for subscriptions

---

## Planned Features

- [ ] Product page CRO redesign (see [PRODUCT-PAGE-CRO-PLAN.md](./PRODUCT-PAGE-CRO-PLAN.md))
  - Phase 1: Core structure (size cards, flavor selection, subscribe toggle)
  - Phase 2: Full flavor selection with mutual exclusivity
  - Phase 3: Upsells, trust badges, mobile sticky CTA
  - Phase 4: A/B testing and analytics
- [ ] Subscription app migration (see [SUBSCRIPTION-MIGRATION-PLAN.md](./SUBSCRIPTION-MIGRATION-PLAN.md))

---

## Current SKU Structure

| SKU | 9-pack | 18-pack | 27-pack |
|-----|--------|---------|---------|
| Mixed Box | ✓ | ✓ | ✓ |
| Cacao | ✓ | ✓ | ✓ |
| Cinnamon | ✓ | ✓ | ✓ |
| Strawberry Goji | ✓ | ✓ | ✓ |

**Pricing:**
- Full price: £2.00/pack
- Subscription: 20% off (£1.60/pack)
- Free shipping threshold: £40+

---

## Key Files

| File | Purpose |
|------|---------|
| `sections/shop-purchase-flow.liquid` | Main CRO purchase flow |
| `SHOP-PURCHASE-FLOW-SPEC.md` | Design spec for purchase flow (authoritative) |
| `snippets/product-card.liquid` | Product card with selling plan check |
| `snippets/line-item.liquid` | Cart line item with subscription display |
| `snippets/meal-box.liquid` | Meal box component |
| `snippets/horizontal-product.liquid` | Horizontal product layout |

---

## Version History

| Date | Change |
|------|--------|
| Feb 5, 2026 | Fix thumbnail scroll-into-view on click |
| Feb 5, 2026 | Fix gallery reset on flavor selection |
| Feb 5, 2026 | Unified flavor card architecture - blocks for bundles and flavors |
| Feb 2026 | Subscription migration analysis completed |
| Feb 2026 | CRO audit and product page redesign spec |
| — | Initial theme setup from Impact v6.0.1 |
