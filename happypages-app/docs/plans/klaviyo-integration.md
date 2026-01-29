# Klaviyo Integration: Sync Referral Events & Trigger Flows

## Summary
Integrate with Klaviyo to track referral events and sync customer profiles, enabling automated email flows when referral codes are created, used, or rewards are earned.

## Events to Track

| Event | Trigger | Recipient | Use Case |
|-------|---------|-----------|----------|
| Referral Code Created | New referral created | Referrer | Welcome email with share instructions |
| Referral Code Used | Someone uses a code | Referrer | "Someone used your code!" notification |
| Reward Earned | Referrer earns reward | Referrer | "Here's your reward code" email |

## Profile Properties to Sync

- `referral_code` - User's unique code
- `referral_usage_count` - Times their code was used
- `referral_reward_codes` - Comma-separated earned rewards
- `has_referral_code` - Boolean for segmentation

---

## Implementation Plan

### 1. Create KlaviyoService

**File:** `app/services/klaviyo_service.rb`

```ruby
class KlaviyoService
  BASE_URL = 'https://a.klaviyo.com/api'
  API_REVISION = '2024-02-15'

  def initialize(api_key = ENV['KLAVIYO_API_KEY'])
  def track_event(email:, event_name:, properties: {})
  def upsert_profile(email:, properties: {})

  # Convenience methods
  def track_referral_code_created(referral)
  def track_referral_code_used(referral, buyer_email: nil)
  def track_reward_earned(referral, reward_code:)
  def sync_referral_profile(referral)
end
```

Follows existing `AwtomicService` pattern: Net::HTTP, result hashes, graceful error handling.

### 2. Modify WebhooksController

**File:** `app/controllers/webhooks_controller.rb`

Add calls at these points:

1. **After `create_buyer_referral` saves** (line ~68):
   ```ruby
   track_klaviyo_referral_created(referral)
   ```

2. **After `increment!(:usage_count)` in orders loop** (line ~21):
   ```ruby
   track_klaviyo_code_used(referral, order_data)
   ```

3. **After reward creation in `create_referrer_reward`** (line ~184):
   ```ruby
   track_klaviyo_reward_earned(referral, result[:reward_code])
   ```

Add private helper methods that wrap calls with error handling.

### 3. Modify Api::ReferralsController

**File:** `app/controllers/api/referrals_controller.rb`

After referral.save in `create` action:
```ruby
track_klaviyo_referral_created(referral)
```

### 4. Environment Variables

Add to Railway:
```
KLAVIYO_API_KEY=pk_xxxxxxxxxxxxxxxxxxxx
```

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `app/services/klaviyo_service.rb` | Create |
| `app/controllers/webhooks_controller.rb` | Modify (3 integration points) |
| `app/controllers/api/referrals_controller.rb` | Modify (1 integration point) |

No migrations needed - all Klaviyo data synced to their platform.

---

## Error Handling

All Klaviyo calls wrapped to never break the referral flow:

```ruby
def track_klaviyo_something(referral)
  return unless ENV['KLAVIYO_API_KEY'].present?
  KlaviyoService.new.do_something(referral)
rescue => e
  Rails.logger.error "Klaviyo tracking failed: #{e.message}"
end
```

---

## Verification

1. Set `KLAVIYO_API_KEY` in environment
2. Create a new referral via checkout or API
3. Check Klaviyo dashboard for "Referral Code Created" event
4. Simulate order webhook with referral code
5. Verify "Referral Code Used" and "Reward Earned" events appear
6. Check profile has `referral_code` and `has_referral_code` properties
