# Multi-Tenant Architecture Plan

## Overview

Convert the single-tenant referral app to support multiple Shopify merchants, each with their own isolated data, credentials, and integrations.

## Why This Matters

Currently the app uses ENV variables for a single merchant's Shopify/Awtomic/Klaviyo credentials. To support multiple merchants:
- Each merchant needs isolated data (referrals, rewards, configs)
- Each merchant brings their own API credentials
- Webhooks must route to the correct merchant

---

## Phase 1: Foundation - Shop Model & Credentials

### New Tables

```ruby
# db/migrate/xxx_create_shops.rb
create_table :shops do |t|
  t.string :name, null: false
  t.string :shopify_domain, null: false  # e.g., "mystore.myshopify.com"
  t.string :status, default: "active"    # active, suspended, uninstalled
  t.timestamps
end
add_index :shops, :shopify_domain, unique: true

# db/migrate/xxx_create_shop_credentials.rb
create_table :shop_credentials do |t|
  t.references :shop, null: false, foreign_key: true
  t.string :shopify_access_token          # encrypted
  t.string :shopify_webhook_secret
  t.string :awtomic_api_key               # encrypted
  t.string :awtomic_webhook_secret
  t.string :klaviyo_api_key               # encrypted
  t.timestamps
end
```

### New Models

**`app/models/shop.rb`**
```ruby
class Shop < ApplicationRecord
  has_one :shop_credential, dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :referral_rewards, dependent: :destroy
  has_many :shared_discounts, dependent: :destroy
  has_many :discount_configs, dependent: :destroy
  has_many :referral_events, dependent: :destroy

  validates :shopify_domain, presence: true, uniqueness: true

  def shopify_credentials
    { url: shopify_domain, token: shop_credential&.shopify_access_token }
  end

  def awtomic_credentials
    { api_key: shop_credential&.awtomic_api_key }
  end

  def klaviyo_credentials
    { api_key: shop_credential&.klaviyo_api_key }
  end
end
```

**`app/models/shop_credential.rb`**
```ruby
class ShopCredential < ApplicationRecord
  belongs_to :shop
  encrypts :shopify_access_token, :awtomic_api_key, :klaviyo_api_key
end
```

---

## Phase 2: Add shop_id to Existing Models

### Migration

```ruby
# db/migrate/xxx_add_shop_id_to_models.rb
def change
  # Add shop_id to all business tables
  add_reference :referrals, :shop, foreign_key: true
  add_reference :referral_rewards, :shop, foreign_key: true
  add_reference :shared_discounts, :shop, foreign_key: true
  add_reference :discount_generations, :shop, foreign_key: true
  add_reference :discount_configs, :shop, foreign_key: true
  add_reference :referral_events, :shop, foreign_key: true

  # Update uniqueness constraints (shop-scoped)
  remove_index :referrals, :referral_code
  add_index :referrals, [:shop_id, :referral_code], unique: true

  remove_index :referral_rewards, :code
  add_index :referral_rewards, [:shop_id, :code], unique: true

  remove_index :discount_configs, :config_key
  add_index :discount_configs, [:shop_id, :config_key], unique: true
end
```

### Model Updates

Each model gets:
```ruby
belongs_to :shop
default_scope { where(shop_id: Current.shop&.id) if Current.shop }
```

Or use explicit scoping (safer):
```ruby
scope :for_shop, ->(shop) { where(shop: shop) }
```

---

## Phase 3: Current Shop Context

### Request-Based Context

**`app/models/current.rb`**
```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :shop
end
```

**`app/controllers/application_controller.rb`**
```ruby
before_action :set_current_shop

def set_current_shop
  # For API requests: extract from header or param
  # For admin: extract from session
  # For webhooks: lookup from payload data
end
```

---

## Phase 4: Service Updates

### ShopifyDiscountService

Change from:
```ruby
def initialize
  @shop_url = ENV["SHOPIFY_SHOP_URL"]
  @access_token = ENV["SHOPIFY_ACCESS_TOKEN"]
end
```

To:
```ruby
def initialize(shop)
  @shop = shop
  @shop_url = shop.shopify_domain
  @access_token = shop.shop_credential.shopify_access_token
end
```

### AwtomicService & KlaviyoService

Already accept credentials as params - ensure all call sites pass shop credentials.

---

## Phase 5: Webhook Routing

### Challenge
Webhooks don't include shop_id - must derive from payload.

### Shopify Webhooks (`/webhooks/orders`)
```ruby
def determine_shop
  # Option A: X-Shopify-Shop-Domain header
  domain = request.headers["X-Shopify-Shop-Domain"]
  Shop.find_by!(shopify_domain: domain)
end
```

### Awtomic Webhooks (`/webhooks/awtomic`)
```ruby
def determine_shop
  # Lookup chain: subscription_id -> referral_reward -> shop
  subscription_id = payload.dig("payload", "subscriptionContractId")
  reward = ReferralReward.unscoped.find_by(awtomic_subscription_id: subscription_id)
  reward&.shop || raise("Unknown shop for subscription #{subscription_id}")
end
```

---

## Phase 6: API & Checkout Extension

### Shop Identification Strategy

The checkout extension needs to identify which shop it's calling from:

**Option A: Domain-based (Recommended)**
```javascript
// Extension sends shop domain
fetch(`${API_URL}/api/referrals`, {
  headers: { "X-Shop-Domain": Shopify.shop }
})
```

**Option B: Shop ID in extension settings**
```toml
# shopify.extension.toml
[settings]
shop_id = "abc123"
```

---

## Phase 7: Admin UI Isolation

### Session-Based Shop Context
```ruby
class Admin::BaseController < ApplicationController
  before_action :set_shop_from_session

  def set_shop_from_session
    @shop = Shop.find(session[:shop_id])
    Current.shop = @shop
  end
end
```

### Multi-Shop Admin (Future)
If admins manage multiple shops, add shop switcher UI.

---

## Files to Modify

| File | Changes |
|------|---------|
| `app/models/` | Add `shop.rb`, `shop_credential.rb`, add `belongs_to :shop` to all models |
| `app/services/shopify_discount_service.rb` | Accept `shop` in constructor |
| `app/controllers/webhooks_controller.rb` | Add shop routing from Shopify header |
| `app/controllers/awtomic_webhooks_controller.rb` | Add shop routing from subscription lookup |
| `app/controllers/api/*` | Extract shop from request header |
| `app/controllers/admin/*` | Scope all queries to current shop |
| `app/jobs/*` | Pass shop_id through job arguments |
| `db/schema.rb` | New tables and foreign keys |

---

## Migration Strategy for Existing Data

1. Create default Shop for current merchant
2. Backfill `shop_id` on all existing records
3. Make `shop_id` NOT NULL
4. Update uniqueness constraints

```ruby
# db/migrate/xxx_backfill_shop_id.rb
def up
  shop = Shop.create!(name: "Default", shopify_domain: ENV["SHOPIFY_SHOP_URL"])

  # Backfill all tables
  Referral.update_all(shop_id: shop.id)
  ReferralReward.update_all(shop_id: shop.id)
  # ... etc

  # Now make NOT NULL
  change_column_null :referrals, :shop_id, false
  # ... etc
end
```

---

## Subscription Provider Abstraction (Future)

For merchants using different subscription tools (Awtomic vs Skio vs Recharge):

```ruby
# app/models/shop.rb
def subscription_service
  case subscription_provider
  when "awtomic" then AwtomicService.new(awtomic_credentials)
  when "skio" then SkioService.new(skio_credentials)
  when "recharge" then RechargeService.new(recharge_credentials)
  end
end
```

---

## Verification

1. Create two test shops with different credentials
2. Verify referrals are isolated between shops
3. Test webhooks route to correct shop
4. Verify admin UI only shows shop's data
5. Test checkout extension works per-shop

---

## Implementation Order

1. Create Shop and ShopCredential models/tables
2. Add shop_id to existing models (nullable first)
3. Backfill existing data to default shop
4. Make shop_id NOT NULL, update constraints
5. Update ShopifyDiscountService to accept shop
6. Update webhook controllers with shop routing
7. Update API controllers with shop extraction
8. Update admin controllers with shop scoping
9. Update jobs to pass shop context
10. Test end-to-end with multiple shops
