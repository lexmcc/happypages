# Staging Pipeline

## Goal

Safe deployment testing before production — a staging environment on Railway with its own database and a dev Shopify app, so changes can be verified end-to-end (OAuth, webhooks, admin UI, analytics) before merging to main. Also support running a custom Shopify app (for one specific store) alongside the public app on the same production backend.

## Approach

Separate Railway services watching a `staging` branch, own PostgreSQL instance, dev Shopify app in Partner Dashboard pointed at staging URLs. Code is identical between environments — only Railway env vars differ. Both static site and Rails app are staged. Multi-app support via per-shop credentials on `ShopIntegration` (custom app stores get their own `client_id`/`client_secret`, public app stores use the global env var).

## Decisions

- **Domain**: Railway-generated URLs (no custom subdomain, no DNS setup)
- **Storage**: Separate Railway Bucket for staging (full isolation from prod media)
- **Seed guard**: `APP_HOST` check — seeds only run if hostname contains "staging", no-ops in prod
- **CI**: GitHub Actions runs RSpec on push to `staging` branch, deploy only proceeds if green

## Chunks

### Chunk 1: Railway staging services

Create the staging infrastructure on Railway.

- [ ] Create new Railway services: `happypages-staging` (static site) and `happypages-app-staging` (Rails app)
- [ ] Create staging PostgreSQL instance
- [ ] Create staging Railway Bucket (Tigris) — separate from prod
- [ ] Configure both services to watch `staging` branch (not `main`)
- [ ] Set `watchPatterns` in each service to match production (`railway.toml` at root for static, `happypages-app/railway.toml` for Rails)
- [ ] Copy env vars from prod, override:
  - `DATABASE_URL` → staging Postgres
  - `SHOPIFY_CLIENT_ID` → dev app (Chunk 2)
  - `SHOPIFY_CLIENT_SECRET` → dev app (Chunk 2)
  - `SUPER_ADMIN_PASSWORD_DIGEST` → can reuse prod or set a simpler one for testing
  - `AWS_BUCKET`, `AWS_ENDPOINT`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` → staging bucket
- [ ] Verify `db:prepare` runs clean on empty staging DB
- [ ] Verify static site serves at Railway-generated URL
- [ ] Verify Rails app boots and superadmin login works

### Chunk 2: Dev Shopify app

Create a separate Shopify app for staging so webhooks and OAuth don't interfere with production.

- [ ] Create new app in Partner Dashboard (public distribution, unlisted)
- [ ] Set app URL to staging Rails app Railway URL
- [ ] Set OAuth redirect URLs to staging Railway URL (`https://<staging-url>/auth/shopify/callback`)
- [ ] Create TOML config: `shopify.app.happypages-staging.toml` with new client ID
- [ ] Add webhook subscriptions pointing at staging URL
- [ ] Set staging env vars: `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET` from new app
- [ ] Install dev app on test store (`happypages-test-store.myshopify.com`)
- [ ] Verify full OAuth flow: install → admin dashboard → referral page
- [ ] Verify webhooks: create test order → webhook fires → referral matched
- [ ] Deploy extensions to dev app: `shopify app deploy --config=shopify.app.happypages-staging.toml`

### Chunk 3: Multi-app credential support

Allow multiple Shopify apps (public + custom) to coexist on one production backend. Custom apps bypass Shopify's protected customer data approval, so a store that needs immediate data access can use a custom app while the public app goes through review.

**Why this is needed:** Shopify signs webhooks and JWTs with the app's `client_secret`. With two apps, there are two secrets. The backend currently uses a single global `SHOPIFY_CLIENT_SECRET` env var — so webhooks from the custom app would fail HMAC verification, and embedded JWT verification would fail.

**Schema change:**

- [ ] Add `app_client_id` (string, nullable) and `app_client_secret` (string, nullable, encrypted) columns to `shop_integrations`
- [ ] These are only populated for shops installed via non-default apps (custom apps). Public app shops leave them null and fall back to the global env var.

**Webhook HMAC verification** (`webhooks_controller.rb:76-103`):

Currently:
```ruby
secret = Current.shop.shopify? ? ENV["SHOPIFY_CLIENT_SECRET"] : Current.shop.webhook_secret
```

Change to:
```ruby
secret = if Current.shop.shopify?
  integration = Current.shop.integration_for("shopify")
  integration&.app_client_secret.presence || ENV["SHOPIFY_CLIENT_SECRET"]
else
  Current.shop.webhook_secret
end
```

- [ ] Update `verify_webhook_signature` to read secret from ShopIntegration first, fall back to global env var
- [ ] This is safe: the shop is already identified from `X-Shopify-Shop-Domain` header before HMAC verification runs

**OAuth flow** (`shopify_auth_controller.rb`):

Currently:
```ruby
client_id = ENV.fetch("SHOPIFY_CLIENT_ID")  # line 186
client_secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")  # line 205
```

Change to support an `app` query param:
- [ ] `GET /auth/shopify?shop=store.myshopify.com&app=custom` → uses custom app credentials
- [ ] Store the app identity in `session[:oauth_app]` alongside existing `session[:oauth_state]`
- [ ] In callback, read app credentials from a config lookup (env vars like `SHOPIFY_CUSTOM_CLIENT_ID` / `SHOPIFY_CUSTOM_CLIENT_SECRET`, or a YAML config)
- [ ] On new shop creation, write `app_client_id` and `app_client_secret` to the ShopIntegration record
- [ ] On returning shop, don't change app credentials (shop stays on whatever app installed it)

**Embedded JWT verification** (`shopify_session_token_verifiable.rb:9-10`):

Currently:
```ruby
client_secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
client_id = ENV.fetch("SHOPIFY_CLIENT_ID")
```

Change to peek at `aud` claim first:
- [ ] Decode JWT payload without verification to read `aud` (the client_id)
- [ ] If `aud` matches global `SHOPIFY_CLIENT_ID`, use global secret
- [ ] If `aud` matches a ShopIntegration's `app_client_id`, use that integration's `app_client_secret`
- [ ] Then verify the signature with the resolved secret
- [ ] This is a standard pattern — peek at unverified claims to route to the correct verification key

**Custom app env vars:**
- [ ] `SHOPIFY_CUSTOM_CLIENT_ID` — the custom app's client ID
- [ ] `SHOPIFY_CUSTOM_CLIENT_SECRET` — the custom app's client secret
- [ ] These are only needed during OAuth initiation (to know where to redirect). After install, credentials are stored on the ShopIntegration record.

**Tests:**
- [ ] Webhook HMAC verification with custom app secret (shop has `app_client_secret` set)
- [ ] Webhook HMAC verification with public app secret (shop has null `app_client_secret`, falls back to env var)
- [ ] OAuth flow with `app=custom` param
- [ ] JWT verification with custom app's client_id in `aud` claim

### Chunk 4: Seed script + CI

Auto-populate staging with realistic test data and add CI gate.

**Seed script:**
- [ ] Create `db/seeds.rb` with:
  - 3 sample shops with ShopFeatures (referrals + analytics active, others locked)
  - ShopIntegrations per shop (one Shopify, one Custom)
  - Users with roles (owner, admin, member) per shop
  - 50+ referrals across shops with codes and varying statuses
  - Analytics events spanning 30 days (pageviews, goals, payments)
  - Discount configs and campaigns
  - A few MediaAssets (placeholder images)
- [ ] Guard with `return unless ENV["APP_HOST"]&.include?("staging")` at top of seeds.rb
- [ ] Secondary guard: `return if Shop.exists?` for idempotency
- [ ] Wire into `db:prepare` flow (runs automatically on empty DB)
- [ ] Verify: admin dashboard shows data, analytics charts render, superadmin shop list populated

**CI:**
- [ ] Add GitHub Actions workflow for `staging` branch: checkout → setup Ruby → bundle install → db:prepare → rspec
- [ ] Workflow triggers on push to `staging` branch
- [ ] Reuse existing CI config (`.github/workflows/ci.yml`) if possible — extend branch trigger list

### Chunk 5: Git workflow + docs

Establish the branch workflow and document everything.

- [ ] Create `staging` branch from `main`
- [ ] Document deploy flow:
  ```
  feature branch → PR → merge to staging → CI runs → Railway auto-deploys staging
                                                       ↓
                                                 test on staging
                                                       ↓
                                                 merge staging → main → Railway auto-deploys prod
  ```
- [ ] Add staging URLs to `CLAUDE.md` under Deployment section
- [ ] Add staging env var reference (which vars differ, where they're set)
- [ ] Note: TOML files coexist — `shopify app deploy --config=...` selects which app to deploy extensions to

## First Step

Chunk 1 (Railway services) — once staging infrastructure exists, everything else plugs in. Chunk 3 (multi-app) can be built in parallel since it's a code change, not infrastructure.

## Technical Notes

- Both staging and prod run `RAILS_ENV=production` — no Rails "staging" environment needed
- Railway env vars are per-service, never travel with code — prod values are untouched by staging deploys
- The Rails app reads `SHOPIFY_CLIENT_ID` from env vars at runtime, not from TOML — both TOML configs coexist harmlessly in the repo
- `shopify app deploy` targets a specific TOML via `--config` flag — extensions deploy to the correct app
- Staging DB gets `db:prepare` on first boot (creates tables + runs seeds)
- Existing `start.sh` handles empty DBs already — no changes needed
- Railway-generated URLs are stable per service — they don't change between deploys
- Custom apps get automatic access to protected customer data — no Shopify approval needed (unlike public apps)
- Multi-app credential resolution: ShopIntegration `app_client_secret` → global `SHOPIFY_CLIENT_SECRET` env var. Null `app_client_secret` means "use the default public app"
- The 3 touch points for multi-app: `webhooks_controller.rb:80`, `shopify_auth_controller.rb:186+205`, `shopify_session_token_verifiable.rb:9-10`
