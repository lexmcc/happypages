# White-Labeled Referral URLs

## Decision Summary

| Aspect | Decision |
|--------|----------|
| **Launch approach** | Path-based routing (`happypages.co/fielddoctor/refer`) |
| **Slug generation** | Merchant-chosen in admin UI |
| **Timing** | Bundle with production launch |
| **Future upgrade** | Subdomain/custom domain as premium features later |

---

## Problem Statement

Customers currently see URLs like:
```
https://referral-app-proto-production.up.railway.app/refer?firstName=John&email=john@example.com
```

This looks unprofessional and clearly third-party. Merchants want branded URLs that feel like their own site.

**Critical Bug:** The current `/refer` page relies on `session[:shop_id]` for shop identification, which breaks when customers visit directly (no session). Multi-tenant referral pages don't work correctly today.

---

## Options Considered

### Option 1: Path-Based Routing (SELECTED)
**URL:** `happypages.co/fielddoctor/refer`

| Pros | Cons |
|------|------|
| Simplest to implement | Platform domain still visible |
| Single domain, single SSL | Less "white-label" feeling |
| Fixes multi-tenant bug | - |
| No DNS changes per merchant | - |

### Option 2: Subdomain Routing (Future)
**URL:** `fielddoctor.happypages.co/refer`

**Trade-offs:**
- Wildcard DNS + SSL configuration
- Subdomains = separate "sites" in Google Analytics
- Session cookies scoped to subdomain (need domain-wide config)
- Local development harder (`/etc/hosts` or `lvh.me`)
- Corporate firewalls sometimes block new subdomains

### Option 3: Custom Domain (Enterprise Future)
**URL:** `fielddoctor.com/refer`

Ultimate white-labeling but requires merchant DNS configuration and per-domain SSL. Premium tier feature.

---

## Implementation Plan

### Database Changes

```ruby
# Migration: add_slug_to_shops
add_column :shops, :slug, :string
add_index :shops, :slug, unique: true
```

### Slug Management

- **Initial value:** Auto-generate from shop name as default (e.g., "Field Doctor" -> "fielddoctor")
- **Merchant control:** Editable in admin UI (settings section)
- **Validation:** Letters, numbers, hyphens only; 3-50 chars; unique across all shops
- **Conflicts:** First-come-first-served; show "slug taken" error if duplicate
- **Existing shops:** Migration generates initial slugs from shop names

### Route Changes

```ruby
# config/routes.rb
# Shop-specific referral page (new)
get ":shop_slug/refer", to: "referrals#show", as: :shop_referral

# Keep legacy route during transition
get "refer", to: "referrals#show"
```

### Controller Changes

```ruby
# referrals_controller.rb
before_action :set_shop_from_slug

def set_shop_from_slug
  if params[:shop_slug]
    Current.shop = Shop.active.find_by!(slug: params[:shop_slug])
  elsif session[:shop_id]
    Current.shop = Shop.find(session[:shop_id])
  else
    render_shop_not_found
  end
end
```

### Extension Changes

```javascript
// Checkout.jsx - fetch URL from config instead of hardcoding
const config = await fetchConfig();
const referralUrl = `${config.referral_base_url}/${shopSlug}/refer`;
```

### Config API Changes

```ruby
# api/configs_controller.rb
def show
  render json: {
    referral_url: "https://app.happypages.co/#{Current.shop.slug}/refer",
    # ... existing config
  }
end
```

### Files to Modify

| File | Changes |
|------|---------|
| `db/migrate/xxx_add_slug_to_shops.rb` | NEW - add slug column |
| `app/models/shop.rb` | Add slug validation, auto-generation callback |
| `config/routes.rb` | Add `/:shop_slug/refer` route |
| `app/controllers/referrals_controller.rb` | Lookup shop from slug |
| `app/controllers/api/configs_controller.rb` | Return `referral_url` field |
| `app/views/admin/config/edit.html.erb` | Add slug editing field |
| `app/controllers/admin/configs_controller.rb` | Allow slug updates |
| `it-works-app/extensions/.../Checkout.jsx` | Use dynamic URL from config |

---

## Verification

- [ ] New shop gets auto-generated slug from shop name
- [ ] `/fielddoctor/refer?firstName=John&email=john@example.com` works
- [ ] Extension generates correct shop-specific URL
- [ ] Invalid slug returns 404 with friendly error
- [ ] Existing shops get slugs via migration (data backfill)
- [ ] Shareable discount link still works correctly
- [ ] Merchant can edit slug in admin UI
- [ ] Duplicate slug shows validation error

---

## Dependency

This feature should be implemented as part of **Production Launch** (see `production-launch.md`), specifically during Phase 3 (Code Transition) since the hardcoded `REFERRAL_APP_URL` is already being replaced.

---

## Future Phases (Not for Launch)

### Phase 2: Subdomain Routing
When ready for better branding:
- Configure wildcard DNS (`*.{domain}`)
- Add subdomain extraction middleware
- Allow toggle in admin: path vs subdomain

### Phase 3: Custom Domain
Enterprise tier feature:
- Add `custom_domain` column to shops
- Domain verification flow (CNAME check)
- SSL via Cloudflare or Let's Encrypt
- Premium pricing tier
