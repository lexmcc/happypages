# Third-Party Integration Onboarding Wizard

## Goal

After Shopify OAuth completes, guide new merchants through a step-by-step wizard to configure third-party integrations (Klaviyo, Awtomic). This replaces the current ENV-var fallback approach with proper per-shop credentials.

---

## User Flow

```
OAuth Complete → Onboarding Wizard → Admin Dashboard
                      │
                      ├─ Step 1: Klaviyo Setup (optional)
                      ├─ Step 2: Awtomic Setup (optional)
                      └─ Step 3: Summary & Finish
```

**Key UX Principles:**
- All steps are **skippable** (merchant may not use all integrations)
- **Validate API keys** before saving (test API call)
- Show **clear instructions** on where to find each key
- **Progress indicator** shows completion status
- Can return to wizard later from admin settings

---

## Step 1: Klaviyo Integration

### UI Elements
- Heading: "Connect Klaviyo"
- Description: "Track referral events and send automated emails"
- Input: Private API Key (password field with show/hide toggle)
- Help link: "Where do I find this?" → instructions or link to Klaviyo docs
- "Test Connection" button → validates key before proceeding
- "Skip for now" link

### Validation
```ruby
# Test Klaviyo key by fetching account info
GET https://a.klaviyo.com/api/accounts/
Headers: Authorization: Klaviyo-API-Key {key}, revision: 2024-10-15
Success: 200 OK
Failure: 401 Unauthorized
```

### Instructions for User
> 1. Log in to Klaviyo
> 2. Go to Settings → API Keys
> 3. Create a new Private API Key with these scopes:
>    - Events: Write
>    - Profiles: Write
> 4. Copy the key and paste it here

---

## Step 2: Awtomic Integration

### UI Elements
- Heading: "Connect Awtomic"
- Description: "Auto-apply referral rewards to subscriptions"
- Input: API Key (password field with show/hide toggle)
- Help link: "Where do I find this?"
- "Test Connection" button
- Checkbox: "Register webhooks automatically" (checked by default)
- "Skip for now" link

### Validation
```ruby
# Test Awtomic key by listing webhooks (lightweight call)
GET https://api.awtomic.com/webhooks
Headers: X-API-Key: {key}
Success: 200 OK
Failure: 401 Unauthorized
```

### Webhook Auto-Registration
If checkbox is enabled, after saving:
```ruby
AwtomicService.new(api_key).register_webhook(
  "#{ENV['WEBHOOK_BASE_URL']}/webhooks/awtomic",
  ["baSuccess", "baFailure", "scUpdated"]
)
```

### Instructions for User
> 1. Log in to Awtomic dashboard
> 2. Go to Settings → API
> 3. Copy your API key
> 4. Paste it here

---

## Step 3: Summary & Finish

### UI Elements
- Heading: "You're all set!"
- Integration status cards:
  - Shopify: ✅ Connected (always)
  - Klaviyo: ✅ Connected / ⏭️ Skipped
  - Awtomic: ✅ Connected / ⏭️ Skipped
- "Go to Dashboard" button → `/admin/config/edit`
- "Configure integrations later" link (if any skipped)

---

## Database Changes

**No schema changes needed** - `ShopCredential` already has all required fields:
- `klaviyo_api_key` (encrypted)
- `awtomic_api_key` (encrypted)
- `awtomic_webhook_secret` (encrypted)

**Optional migration** - Track onboarding completion:
```ruby
# db/migrate/YYYYMMDD_add_onboarding_completed_at_to_shops.rb
class AddOnboardingCompletedAtToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :onboarding_completed_at, :datetime
  end
end
```

---

## Files to Create

### Controller
```ruby
# app/controllers/admin/onboarding_controller.rb
class Admin::OnboardingController < Admin::BaseController
  def show
    @step = params[:step]&.to_i || 1
    @shop = Current.shop
  end

  def update
    @step = params[:step].to_i

    case @step
    when 1 then handle_klaviyo_step
    when 2 then handle_awtomic_step
    when 3 then complete_onboarding
    end
  end

  def skip
    @step = params[:step].to_i
    session[:skipped_steps] ||= []
    session[:skipped_steps] << @step
    redirect_to admin_onboarding_path(step: @step + 1)
  end

  def validate_klaviyo
    # AJAX endpoint to test Klaviyo key
    result = KlaviyoService.validate_api_key(params[:api_key])
    render json: { valid: result[:success], error: result[:error] }
  end

  def validate_awtomic
    # AJAX endpoint to test Awtomic key
    result = AwtomicService.validate_api_key(params[:api_key])
    render json: { valid: result[:success], error: result[:error] }
  end

  private

  def handle_klaviyo_step
    if params[:klaviyo_api_key].present?
      Current.shop.shop_credential.update!(
        klaviyo_api_key: params[:klaviyo_api_key]
      )
    end
    redirect_to admin_onboarding_path(step: 2)
  end

  def handle_awtomic_step
    if params[:awtomic_api_key].present?
      Current.shop.shop_credential.update!(
        awtomic_api_key: params[:awtomic_api_key]
      )

      if params[:register_webhooks] == "1"
        RegisterAwtomicWebhooksJob.perform_later(Current.shop.id)
      end
    end
    redirect_to admin_onboarding_path(step: 3)
  end

  def complete_onboarding
    Current.shop.update!(onboarding_completed_at: Time.current)
    redirect_to edit_admin_config_path, notice: "Setup complete!"
  end
end
```

### Service Validation Methods
```ruby
# Add to app/services/klaviyo_service.rb
def self.validate_api_key(api_key)
  return { success: false, error: "API key required" } if api_key.blank?

  uri = URI("https://a.klaviyo.com/api/accounts/")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Klaviyo-API-Key #{api_key}"
  request["revision"] = "2024-10-15"

  response = http.request(request)

  if response.is_a?(Net::HTTPSuccess)
    { success: true }
  else
    { success: false, error: "Invalid API key" }
  end
rescue => e
  { success: false, error: e.message }
end

# Add to app/services/awtomic_service.rb
def self.validate_api_key(api_key)
  return { success: false, error: "API key required" } if api_key.blank?

  uri = URI("https://api.awtomic.com/webhooks")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request["X-API-Key"] = api_key

  response = http.request(request)

  if response.is_a?(Net::HTTPSuccess)
    { success: true }
  else
    { success: false, error: "Invalid API key" }
  end
rescue => e
  { success: false, error: e.message }
end
```

### Views
```
app/views/admin/onboarding/
├── show.html.erb          # Main wizard container
├── _step_1_klaviyo.html.erb
├── _step_2_awtomic.html.erb
├── _step_3_summary.html.erb
└── _progress_bar.html.erb
```

### Routes
```ruby
# config/routes.rb
namespace :admin do
  resource :onboarding, only: [:show, :update] do
    post :skip
    post :validate_klaviyo
    post :validate_awtomic
  end
end
```

---

## OAuth Callback Change

Update `ShopifyAuthController#callback` to redirect new shops to onboarding:

```ruby
# After creating new shop
if @returning
  redirect_to return_to, notice: "Welcome back!"
else
  redirect_to admin_onboarding_path, notice: "Let's set up your integrations"
end
```

---

## Admin Settings Integration

Add "Integrations" section to existing admin config page for editing credentials later:

```erb
<!-- In app/views/admin/configs/edit.html.erb -->
<section class="integrations">
  <h2>Integrations</h2>

  <div class="integration-card">
    <h3>Klaviyo</h3>
    <% if @shop.shop_credential.klaviyo_api_key.present? %>
      <span class="status connected">Connected</span>
      <button>Update Key</button>
    <% else %>
      <span class="status disconnected">Not configured</span>
      <button>Connect</button>
    <% end %>
  </div>

  <!-- Similar for Awtomic -->
</section>
```

---

## Future Considerations

1. **More integrations** - Easy to add Step 4, 5, etc. for new services
2. **Re-run onboarding** - Admin can trigger wizard again from settings
3. **OAuth for integrations** - Some services (like Klaviyo) support OAuth; could upgrade later
4. **Webhook secret generation** - Auto-generate unique webhook secrets per shop

---

## Verification

### Manual Testing
1. Create new test shop via OAuth
2. Verify redirected to onboarding wizard (not dashboard)
3. Enter invalid Klaviyo key → verify error message
4. Enter valid Klaviyo key → verify "Connected" status
5. Skip Awtomic step
6. Verify summary shows Klaviyo connected, Awtomic skipped
7. Complete wizard → verify on dashboard
8. Verify credentials saved in ShopCredential (Rails console)

### Returning Shop
1. Log out and re-OAuth with existing shop
2. Verify goes to dashboard (not onboarding)
3. Verify existing credentials preserved

---

## Implementation Order

1. Add `onboarding_completed_at` migration
2. Create `Admin::OnboardingController` with basic routing
3. Create step views (can be minimal initially)
4. Add validation endpoints to services
5. Update OAuth callback redirect logic
6. Add Integrations section to admin config
7. Style wizard to match existing admin UI
