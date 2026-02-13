# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run locally (serves on http://localhost:3000)
node server.js

# Or use npm
npm start
```

No build step, no dependencies to install.

## Architecture

Simple static landing page with zero-dependency Node.js server:

- `server.js` - Vanilla Node.js HTTP server with clean URL routing
- `public/index.html` - Main landing page
- `public/styles.css` - All styles (responsive breakpoints at 1024px, 768px)
- `public/happier/index.html` - Design exploration variant (inline styles)
- `public/assets/` - Static assets (logo images, PNG icons)

Clean URL routing: `/happier` serves `/happier/index.html`

## Deployment

Two Railway services from the same GitHub repo:

### happypages (Static Site)
- **URL:** https://happypages.co
- **Root:** `/` (repo root)
- **Config:** `railway.toml` at repo root
- Uses `server.js` to serve static files from `/public`

### happypages-app (Rails Backend)
- **URL:** https://app.happypages.co
- **Root:** `happypages-app/`
- **Config:** `happypages-app/railway.toml`
- Rails 8.1 + PostgreSQL for Shopify referrals app

### Multi-Service Gotchas
- Each service needs its own `railway.toml` with `watchPatterns` to trigger correct deploys
- Services may inherit/reference variables from project level - add dummy values if build fails on missing secrets
- Root directory setting in Railway determines which `railway.toml` is used

**Railway project:** https://railway.com/project/66f72304-7d9e-4860-9b50-aef51f26c5d2

## Rules

- Never run `git push` unless the user explicitly confirms (e.g., "push", "yes", "push to prod")
- No references to Claude or Anthropic in commit messages (no "Generated with Claude Code" or "Co-Authored-By") - NEVER DELETE THIS RULE

## Design

- Max container width: 1200px with light grey side borders (#e0e0e0)
- Background: #F4F4F0
- Primary font: Hanken Grotesk (Google Fonts)
- Hero h1: 62pt desktop, 36pt mobile
- Accent color: Coral #ff584d (hover: #e64d43)
- Letter spacing: -3% body, -7% headings
- All text lowercase with fullstops on headings

### Neumorphic Card Styling

```css
background: #f9f9f9;
border: 1px solid rgba(0,0,0,0.05);
box-shadow:
  inset 1px 1px 0 rgba(255,255,255,1),
  inset -1px -1px 0 rgba(0,0,0,0.05),
  0 4px 8px rgba(0,0,0,0.05);
```

### Card Stack

Uses two HTML elements (not ::before pseudo-element):
- `.card-back` - offset left/down, bottom-left 20px radius
- `.neumorphic-card` - front card, top-left 20px radius

### Animated Bars

The join card header has animated coral bars:
- 40 bars with staggered animation delays
- Even bars are static (full height), odd bars animate
- Animation: 4s ease-in-out, scaleY + translateY
- Respects `prefers-reduced-motion`

## Page Sections

- `.hero` - Main hero section with card
- `.how-it-works-section` - Step cards and client logos
- `.member-benefits-section` - Carousel of benefit cards
- `.works-section` - Card deck carousel showcasing work types
- `.pricing-section` - Pricing cards with toggle

### Step Cards

3 neumorphic cards with scroll animation:
- Colors: Coral (#ff584d), Blue (#154ffb), Cyan (#00C6F7)
- Card stack effect with colored back cards matching front
- Bunched initial state with rotation, spread on scroll
- Intersection Observer triggers at 50% visibility (spread) and re-bunches below 50%
- 300ms animation duration

### Member Benefits

Horizontal carousel with 5 benefit cards:
- Card stack effect (front neumorphic + grey back card)
- Border-radius: 20px 4px 4px 4px (front), 4px 4px 4px 20px (back)
- Each card has unique animated pattern in brand colors
- Carousel navigation with JavaScript (cardWidth + backCardOffset for scroll calc)

### Works Section

Two-column layout (flex: 2 left, flex: 1 right) with card deck carousel:

**Card Deck (left):**
- 3 stacked cards (480x580px) offset to left with rotation
- Cards follow how-it-works styling: full color background, white text
- Colors: Coral (#ff584d), Blue (#154ffb), Cyan (#00C6F7)
- Position transforms: front (0, 0deg), middle (-40px, -4deg), back (-80px, -8deg)

**Shuffle Animation:**
- Cards animate -600px left, pause, then return to new position
- Right arrow (next): front card → exits left → returns to back (z-index high → low)
- Left arrow (prev): back card → exits left → returns to front (z-index low → high)
- 0.8s duration, z-index switches at 320ms (40%)
- Uses `.shuffling-out`/`.returning` and `.shuffling-in`/`.arriving` classes
- `overflow: visible` on section/container allows animation outside bounds

**Text Card (right):**
- Simple neumorphic card with text content
- Card stack effect matching other sections
- Service pills row at top
- Orbiting icons animation at bottom (12 icons on circular path)

### Floating Icons (How It Works)

Background animation with 40 icons following a curved SVG path:
- Uses CSS `offset-path` for motion along path
- `offset-rotate: 0deg` keeps icons upright
- Staggered `animation-delay` for continuous flow
- Intersection Observer pauses animation when off-screen

### Performance

- PNG icons used for animations (pre-rasterized, no filter computation)
- CSS containment on animated containers (`contain: layout style`)
- `will-change` applied only during active animations
- Z-index scale: 5 (back), 10, 20, 30 (front), 50 (animating)
- Transition durations: 200ms for interaction feedback

### Client Logos

- Use `filter: grayscale(100%)` for consistent styling
- Use `filter: invert(1)` to flip white logos to black (e.g., Gousto)
- Normalize with consistent height + max-width

## Design Exploration Page (/happier)

Variant of main page for testing design changes. Uses inline styles (no external CSS).

### Grid Animation

Works-text-card features an animated coral grid (5 rows × 15 columns):
- Box size: 20px desktop, 16px mobile
- Animation: opacity pulses right-to-left with staggered delays per box
- 4 wave patterns with different opacity profiles (wave-a, wave-b, wave-c, wave-d)
- Varied speeds per row (4.5s, 5.625s, 6.75s) for organic feel
- Random row timing offsets
- Mobile: 11 columns (hides boxes 12-15 via `nth-child(n+12)`)

### Step Card Media

Step cards use different media for desktop vs mobile:
- **Desktop (>768px)**: Videos with sequential playback (subscribe → request → receive)
- **Mobile (≤768px)**: Animated GIFs (iOS blocks video autoplay)
- Videos: H.264 Baseline profile, 3s clips, poster images as fallback
- GIFs: 312px width, 12fps, optimized palette
- CSS media queries toggle `display: none/block` on `.step-card__video` / `.step-card__gif`

### Differences from Main Page

- Removed floating icons and orbit animations (cleaner look)
- Works-text-card styled like hero join card (card-heading, card-tagline)
- White icon variants instead of black
- Step cards use videos/GIFs instead of CSS patterns

## Rails Backend (happypages-app/)

See `happypages-app/SPEC.md` for the living app spec (current state + what's next).
See `happypages-app/HISTORY.md` for detailed session notes.
See `happypages-app/LEARNINGS.md` for gotchas, bug fixes, and environment tips.
See `CHANGELOG.md` for dated record of shipped features (both products).

### Key Patterns
- **Multi-tenant**: `Current.shop` thread-isolated context, shop lookup via `X-Shop-Domain` header
- **White-labeled URLs**: `/:shop_slug/refer` routes with auto-generated slugs from shop name
- **API controllers**: inherit `Api::BaseController` (ActionController::API + ShopIdentifiable) — no CSRF, no session
- **Storefront URLs**: `shop.customer_facing_url` returns `storefront_url` or `https://#{domain}` — use for all customer-facing links
- **Tabs controller**: `tabs_controller.js` is shared between admin settings and superadmin views — index-based (`data-index`), slate colors
- **Rate limiting**: `rack-attack` gem, config in `config/initializers/rack_attack.rb`
- **Super admin**: `/superadmin` namespace, env-var BCrypt auth (`SUPER_ADMIN_EMAIL` + `SUPER_ADMIN_PASSWORD_DIGEST`), 2-hour session timeout, dark slate theme. Controllers inherit `Superadmin::BaseController`.
- **Startup script**: `start.sh` runs `db:prepare` (handles empty + existing DBs) then backfills missing slugs

### Shopify App Identity
- **Client ID**: `98f21e1016de2f503ac53f40072eb71b` (public distribution, unlisted)
- **Distribution**: Public (unlisted) — installable via link on any store
- **TOML config**: `shopify.app.happypages-friendly-referrals.toml` is the linked config file

### Media & Storage
- **Active Storage** with Railway Bucket (Tigris, S3-compatible) — config in `config/storage.yml`, production uses `:tigris` service
- **MediaAsset model** — `has_one_attached :file`, variant methods: `thumbnail_variant` (300x200), `referral_banner_variant` (1200x400), `extension_banner_variant` (600x400), all WebP
- **Railway bucket env vars**: `AWS_BUCKET`, `AWS_ENDPOINT`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` — check with `railway variables` if changed
- **Local dev** requires `brew install vips` for variant generation

### Gotchas
- **Shopify signs webhooks with `SHOPIFY_CLIENT_SECRET`** — not a per-shop secret or `SHOPIFY_WEBHOOK_SECRET`. Never `return true` when a signing secret is blank.
- **Never use `Shop.active.first` as webhook fallback** — test webhooks with fake domains will match real shops and destroy data
- **Shopify distribution is permanent** — can't change Custom → Public after creation
- **Protected customer data must be approved** before deploying webhooks containing customer data (`orders/create`, compliance topics)
- **Network access approval** required for theme extensions making external calls
- **Railway SSH**: use `railway ssh --service happypages-app`, Rails app lives at `/rails` in container
- Railway UI "no tables" can be stale - verify with `rails runner "puts ActiveRecord::Base.connection.tables.count"`
- `before_validation :generate_slug, on: :create` won't backfill existing records - remove `on: :create` or add explicit backfill
- Shopify OAuth redirect URLs: check the **linked** TOML file (`shopify.app.*.toml`), not just `shopify.app.toml`
- Re-installing the app via OAuth is the cleanest way to recreate shop records
