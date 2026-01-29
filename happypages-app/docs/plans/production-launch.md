# Production Launch: New Company & Deployment Setup

## Overview

Set up a proper business and production deployment for the Shopify referral app, migrating from the prototype to a fresh codebase with proper naming.

**Key Decisions:**
- New Shopify Partner account (not reusing existing)
- New Railway project (fresh start)
- Copy code to new Git repo (clean history)
- No data migration needed
- UK Ltd company formation
- Domain already secured

**Placeholders used:** `{company-name}`, `{app-name}`, `{domain}`, `{AppName}` (PascalCase), `{app_name}` (snake_case)

---

## Phase 1: Business Setup (Manual Steps) - UK

### 1.1 Ltd Company Formation
- [x] Register with Companies House (gov.uk/register-a-company - £12 online, same day)
- [x] Choose company name (check availability on Companies House)
- [x] Provide registered office address (can be your address or use a service)
- [x] Appoint director(s) and provide details
- [x] Define share structure (typically 1 share at £1 for single founder)
- [x] Receive Certificate of Incorporation and Company Registration Number

**Documents created automatically:**
- Memorandum of Association
- Articles of Association (use Model Articles unless custom needed)

### 1.2 Post-Incorporation
- [x] Register for Corporation Tax with HMRC (within 3 months of starting business)
- [x] Consider VAT registration if expecting >£90k revenue (optional below threshold)
- [x] Set up PAYE if paying yourself salary (can defer if using dividends only initially)
- [x] Get Unique Taxpayer Reference (UTR) - sent by HMRC after CT registration

### 1.3 Business Bank Account
- [x] Open business account (Starling Business, Tide, Monzo Business, or traditional bank)
- [x] Documents needed: Certificate of Incorporation, ID, proof of address
- [x] Most online banks approve in 1-2 days

### 1.4 Business Email
- [x] Set up Google Workspace or similar on `{domain}`
- [x] Create `support@{domain}` and `hello@{domain}`

---

## Phase 2: Account Creation (Manual Steps)

### 2.1 New Shopify Partner Account
- [ ] Sign up at https://partners.shopify.com/signup with business email
- [ ] Complete partner profile with business details
- [ ] Enable 2FA
- [ ] Set up payout details

### 2.2 New Railway Project
- [ ] Sign up/login at https://railway.app
- [ ] Create project: `{app-name}-production`

---

## Phase 3: Code Transition

### 3.1 Create New Repository

**Copy these directories:**
```
referral-app/     -> {app-name}-backend/
it-works-app/     -> {app-name}-extension/
railway.toml      -> {app-name}-backend/railway.toml
```

**Exclude (do not copy):**
```
.git/
**/node_modules/
it-works-app/.shopify/          # Old app credentials
**/dist/
referral-app/log/
referral-app/tmp/
referral-app/storage/
referral-app/config/*.key       # Generate new
**/.env*
.DS_Store
```

### 3.2 String Replacements Required

| Find | Replace | Files |
|------|---------|-------|
| `ReferralApp` | `{AppName}` | `config/application.rb`, `manifest.json.erb` |
| `referral_app` | `{app_name}` | `database.yml`, `Dockerfile`, `deploy.yml` |
| `referral-app` | `{app-name}` | `railway.toml`, docs |
| `it-works-app` | `{extension-name}` | All extension files + folder name |
| `referral-app-proto-production.up.railway.app` | `app.happypages.co` | See below |

**Hardcoded URL locations:**
- `it-works-app/shopify.app.toml:20` - OAuth redirect
- `it-works-app/extensions/it-works-app/src/Checkout.jsx:5` - `REFERRAL_APP_URL`
- `referral-app/app/controllers/admin_controller.rb:14` - webhook fallback
- `referral-app/lib/tasks/shopify.rake:5` - webhook fallback

**Delete entirely:**
- `it-works-app/.shopify/` directory
- `uid` line in `shopify.extension.toml` (Shopify generates new)
- Old `client_id` in `shopify.app.toml` (replace with new)

### 3.3 Generate New Keys

```bash
# New encryption keys (CRITICAL - store securely)
cd {app-name}-backend
bin/rails db:encryption:init

# New Rails master key
rm config/master.key config/credentials.yml.enc
EDITOR="code --wait" bin/rails credentials:edit
```

### 3.4 White-Labeled URLs (Slug Migration)

See [white-labeled-urls.md](./white-labeled-urls.md) for full plan.

**Database migration:**
```ruby
# db/migrate/xxx_add_slug_to_shops.rb
add_column :shops, :slug, :string
add_index :shops, :slug, unique: true
```

**Key changes:**
- Add `slug` column to shops table with unique index
- Add slug validation in Shop model (letters, numbers, hyphens; 3-50 chars)
- Add auto-generation callback from shop name
- Add `/:shop_slug/refer` route
- Update referrals_controller to lookup shop from slug
- Update api/configs_controller to return `referral_url` field
- Update Checkout.jsx to use dynamic URL from config
- Add slug editing field in admin UI

---

## Phase 4: Shopify App Setup

### 4.1 Create App in Partner Dashboard
- [ ] Partners > Apps > Create app manually
- [ ] Name: `{app-name}`
- [ ] App URL: `https://app.happypages.co`
- [ ] Redirect URL: `https://app.happypages.co/auth/shopify/callback`
- [ ] Scopes: `read_customers`, `write_discounts`, `read_orders`
- [ ] Note Client ID and Client Secret

### 4.2 Update shopify.app.toml
```toml
client_id = "{NEW_CLIENT_ID}"
name = "{app-name}"
application_url = "https://app.happypages.co"
embedded = true

[webhooks]
api_version = "2025-10"

[access_scopes]
scopes = "read_customers,write_discounts,read_orders"

[auth]
redirect_urls = ["https://app.happypages.co/auth/shopify/callback"]
```

### 4.3 Deploy Extension
```bash
cd {app-name}-extension
npm install
shopify app deploy --force
```

---

## Phase 5: Railway Deployment

### 5.1 Project Setup
```bash
railway login
cd {app-name}-backend
railway link  # Select your project
railway add   # Add PostgreSQL
```

### 5.2 Environment Variables

| Variable | Source |
|----------|--------|
| `RAILS_MASTER_KEY` | `config/master.key` contents |
| `DATABASE_URL` | Auto-linked from PostgreSQL |
| `RAILS_ENV` | `production` |
| `SHOPIFY_CLIENT_ID` | Partner Dashboard |
| `SHOPIFY_CLIENT_SECRET` | Partner Dashboard |
| `SHOPIFY_REDIRECT_URI` | `https://app.happypages.co/auth/shopify/callback` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | From `db:encryption:init` |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | From `db:encryption:init` |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | From `db:encryption:init` |
| `ADMIN_SECRET` | Generate secure random |

### 5.3 Deploy
```bash
railway up
```
Or connect GitHub for auto-deploy.

---

## Phase 6: DNS & Happy Pages Integration

### 6.1 DNS Setup
| Type | Name | Value |
|------|------|-------|
| CNAME | `app` | `{service}.up.railway.app` |

### 6.2 Railway Custom Domain
1. Railway Dashboard > Service > Settings > Domains
2. Add `app.happypages.co`
3. Railway provides CNAME target
4. SSL auto-provisioned

### 6.3 Rails Config
- [ ] Add `app.happypages.co` to allowed hosts in `config/environments/production.rb`

### 6.4 Happy Pages Website Updates

**File:** `happypages/public/index.html`

**Header** (alongside existing "book a call" and "see pricing" buttons):
```html
<a href="https://app.happypages.co/login" class="btn btn--light">
  login
</a>
```

**Footer** (in `book-call-footer-links`):
```html
<a href="https://app.happypages.co" class="book-call-footer-link">dashboard</a>
```

---

## Phase 7: Testing Checklist

- [ ] `curl https://app.happypages.co/up` returns 200
- [ ] OAuth flow: `/auth/shopify?shop=devstore.myshopify.com` works
- [ ] Install app on dev store
- [ ] Extension appears on Thank You page
- [ ] Share button links to correct domain
- [ ] Test order triggers webhook
- [ ] Admin UI loads and saves config
- [ ] Login button on `happypages.co` links to app
- [ ] Dashboard link in footer works

---

## Phase 8: Post-Launch (PII Compliance)

After stable deployment, implement from `pii-compliance.md`:
- Privacy policy at `/privacy`
- SECURITY.md incident response
- Audit logging table
- PII encryption (`encrypts` on models)
- 3 compliance webhooks
- Partner Dashboard Level 2 submission

---

## Critical Files Reference

**Backend:**
- `config/application.rb` - Module name
- `config/database.yml` - DB names
- `Dockerfile` - Service name
- `railway.toml` - Watch paths

**Extension:**
- `shopify.app.toml` - App config, OAuth, client_id
- `extensions/{name}/shopify.extension.toml` - Extension handle
- `extensions/{name}/src/Checkout.jsx:5` - `REFERRAL_APP_URL` constant

---

## Sequence Summary

1. **Business Setup** - Form Ltd, open bank account, set up email ✓
2. **Accounts** - Create new Shopify Partner account, Railway project
3. **Code** - Copy to new repo, rename everything, generate new keys
4. **Shopify** - Create app in Partner Dashboard, update configs, deploy extension
5. **Railway** - Set env vars, deploy
6. **DNS & Happy Pages** - Configure `app.happypages.co`, add login/dashboard links
7. **Test** - Verify everything works end-to-end
8. **Compliance** - Implement PII compliance after stable
