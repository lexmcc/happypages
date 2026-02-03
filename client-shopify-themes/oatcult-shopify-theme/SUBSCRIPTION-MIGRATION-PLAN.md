# Subscription App Migration Plan

## Current State

**Oat Cult uses Shopify's native Selling Plans API** — not a third-party subscription app like ReCharge, Loop, or Skio.

### How It Works Now

The theme reads subscription data directly from Shopify's Selling Plans API:

```liquid
{%- if variant.selling_plan_allocations.size > 0 -%}
  {{ variant.selling_plan_allocations.first.selling_plan.id }}
  {{ variant.selling_plan_allocations.first.price_adjustments.first.value }}
{%- endif -%}
```

This native approach:
- Pulls selling plan IDs and discount percentages from variants
- Passes `selling_plan` parameter to cart/checkout
- Displays subscription info in cart line items

---

## Files with Subscription Code

| File | Usage |
|------|-------|
| `sections/shop-purchase-flow.liquid` | Main purchase flow — reads `selling_plan_allocations`, passes `selling_plan` to cart |
| `snippets/product-card.liquid` | Checks `product.selling_plan_groups.size` for quick-add behavior |
| `snippets/line-item.liquid` | Displays `line_item.selling_plan_allocation.selling_plan.name` |
| `snippets/meal-box.liquid` | May reference subscriptions |
| `snippets/horizontal-product.liquid` | May reference subscriptions |

---

## Migration Options

### Option A: Loop Subscriptions

**Pros:**
- Modern UI, good customer portal
- Strong Shopify integration
- Growing market share

**Cons:**
- Theme changes required (different API)
- Migration effort for existing subscribers

### Option B: ReCharge

**Pros:**
- Market leader, battle-tested
- Extensive features
- Strong app ecosystem

**Cons:**
- More complex setup
- Higher pricing at scale

### Option C: Skio

**Pros:**
- Modern, DTC-focused
- Good analytics
- Passwordless customer portal

**Cons:**
- Newer, smaller ecosystem

### Option D: Stay Native

**Pros:**
- No migration needed
- No app fees
- Simpler architecture

**Cons:**
- Limited customer portal
- No advanced subscription features (skip, swap, etc.)

---

## Migration Scope (if moving to third-party app)

### Theme Changes Required

1. **`sections/shop-purchase-flow.liquid`** (~2-4 hours)
   - Replace `selling_plan_allocations` with app-specific widget/API
   - Update JavaScript to use app's checkout flow
   - Test all size/flavor combinations

2. **`snippets/product-card.liquid`** (~30 min)
   - Update selling plan detection logic

3. **`snippets/line-item.liquid`** (~30 min)
   - Update subscription name display

4. **Testing** (~2-4 hours)
   - Full purchase flow testing
   - Subscription checkout verification
   - Cart display testing

### Estimated Theme Work: 1-2 days

---

## Breaking Changes

When migrating from native Selling Plans to a third-party app:

1. **Selling Plan IDs change** — old IDs won't work
2. **API structure differs** — each app has its own Liquid objects
3. **Checkout flow changes** — apps may use their own checkout
4. **Customer portal** — subscribers need to be migrated

---

## Recommendations

### Before Committing to Migration

1. **Evaluate need** — Does Oat Cult need advanced features (skip, swap, gifting)?
2. **Customer count** — How many active subscribers need migrating?
3. **Feature comparison** — Which app features matter most?
4. **Cost analysis** — App fees vs. native (free)

### If Proceeding with Migration

1. **Choose app** and get trial access
2. **Set up in development theme** first
3. **Test full purchase flow** before going live
4. **Coordinate subscriber migration** with app support
5. **Plan for parallel running period**

---

## Decision Status

**Current recommendation:** Stay on native Selling Plans unless specific features are needed (customer portal, skip/swap, gifting, analytics).

**Next step:** Client to confirm whether advanced subscription features are a priority.
