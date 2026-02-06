# SPEC.md

HappyPages - Landing page for a design & dev subscription service for D2C founders.

## Overview

Simple, responsive landing page promoting ongoing conversion and growth optimisation services. Hosted on Railway with GitHub auto-deploy.

**Live URL:** https://happypages-production.up.railway.app

## Completed Features

### Hero Section
- [x] Two-column layout (left: content, right: card)
- [x] Logo with header buttons (book a call, see pricing)
- [x] Main headline: "a growth design & dev subscription for d2c founders."
- [x] Subheading: "pause or cancel anytime."
- [x] Responsive breakpoints (1024px, 768px)

### Join Card
- [x] Neumorphic card styling
- [x] Card stack effect (front + back card)
- [x] Animated coral bars in header
- [x] "start today" pill button
- [x] "join happypages." heading
- [x] "see pricing" CTA button
- [x] Book a call section with icon

### How It Works Section
- [x] Section label "how it works."
- [x] Centered h2 heading with italic span
- [x] Matching container styling (borders, max-width)
- [x] 3 animated step cards (Subscribe, Request, Receive)
- [x] Card stack effect (front + colored back card)
- [x] Cards animate from bunched to spread on scroll (Intersection Observer)
- [x] Cards re-bunch when scrolled halfway out of viewport
- [x] Card colors: Coral (#ff584d), Blue (#154ffb), Cyan (#00C6F7)
- [x] Abstract gradient patterns in card image areas
- [x] Client logos row (Gousto, Butternut Box, Field Doctor)
- [x] Client subtitle text

### Member Benefits Section
- [x] Section label "membership benefits."
- [x] Centered h2 heading: "it's 'oh, this is how to do it' better."
- [x] Subheading with value proposition
- [x] Horizontal carousel with 5 benefit cards
- [x] Card stack effect (front + neumorphic back card)
- [x] Unique animated patterns per card:
  - Design board: sliding mini-cards (coral)
  - Fixed monthly rate: blobs above static bar (blue)
  - Fast delivery: diagonal streaks (cyan)
  - Top-notch quality: rotating star (coral)
  - Flexible and scalable: scaling squares (blue)
- [x] Carousel navigation arrows with scroll feedback
- [x] Border-radius matching hero join card (20px 4px 4px 4px)

### Typography
- [x] Hanken Grotesk font (including italic)
- [x] Letter spacing: -3% body, -7% headings
- [x] All text lowercase with fullstops on headings

### Works Section
- [x] Two-column layout (flex: 2 left, flex: 1 right)
- [x] Card deck carousel with 3 stacked cards (480x580px)
- [x] Cards styled like how-it-works: full color background, white text
- [x] Shuffle animation: card exits left (-600px), returns to new position
- [x] Bidirectional: right arrow sends front→back, left arrow sends back→front
- [x] Z-index switching at animation midpoint for proper layering
- [x] Carousel nav buttons (left-aligned)
- [x] Text card on right with neumorphic styling
- [x] Service pills (web design, logos, ui/ux design, etc.)
- [x] Orbiting icons animation at bottom of text card

### How It Works Section - Floating Icons
- [x] Background floating icons animation (40 icons)
- [x] Icons follow curved SVG path across section
- [x] Staggered animation delays for continuous flow
- [x] Paused when section not visible (Intersection Observer)

### Pricing Section
- [x] Two-column layout (flex: 1 left, flex: 2 right)
- [x] Left card: neumorphic with animated bars header
- [x] Right card: dark theme with pricing toggle (basic/pro)
- [x] Typing animation on price and feature changes
- [x] Feature list with highlighting for pro additions

### Technical
- [x] Zero-dependency Node.js server
- [x] Railway deployment with GitHub auto-deploy
- [x] Respects prefers-reduced-motion
- [x] PNG icons for animated elements (better performance than SVG filters)
- [x] CSS containment for layout performance
- [x] Standardized z-index scale (5, 10, 20, 30, 50)
- [x] Clean URL routing (e.g., /happier serves /happier/index.html)
- [x] MP4 MIME type support (video/mp4)

### Design Exploration Page (/happier)
- [x] Variant of main page for design experiments
- [x] Works text card with animated coral grid (5 rows × 15 columns)
- [x] Grid animation: boxes pulse opacity right-to-left with row offsets
- [x] 4 wave patterns with varied speeds (4.5s, 5.625s, 6.75s)
- [x] Random row timing offsets for organic feel
- [x] Card styling matches hero join card (card-heading, card-tagline)
- [x] Mobile responsive: 11 columns, smaller boxes (16px), proper width constraints
- [x] Removed floating icons and orbit animation (cleaner look)
- [x] Pricing CTA: button 50% width left, icon+text on right
- [x] Pricing button styled like hero CTA (coral, neumorphic, centered text)
- [x] Step cards: videos on desktop, GIFs on mobile (iOS compatible)
- [x] Desktop: sequential video playback (subscribe → request → receive)
- [x] Videos clipped to final 3s, 5s pause before looping
- [x] Poster images as video fallback

### FAQ Section
- [x] FAQ accordion with 13 questions
- [x] Expandable/collapsible answers
- [x] CTA card with book a call button

### Footer
- [x] Book a call section with Cal.com integration
- [x] Location text ("headquartered in london, uk.")
- [x] Terms of service and privacy policy links
- [x] Referrals login link (app.happypages.co/login)

### Shopify Referrals App
- [x] Rails 8.1 backend deployed to Railway (app.happypages.co)
- [x] Shopify checkout UI extension (Preact + Polaris)
- [x] OAuth flow for self-service app installation
- [x] PostgreSQL database with multi-tenant architecture
- [x] Environment variables and secrets configured
- [x] White-labeled URLs: shop-specific referral URLs (e.g., /shop-slug/refer)
- [x] Auto-generated slugs from shop name with uniqueness handling

### PII Compliance & Data Protection
- [x] Privacy policy page at /privacy
- [x] Security incident response plan (SECURITY.md)
- [x] Active Record Encryption on PII fields (email, first_name)
- [x] Audit logging system (AuditLog model with JSONB details)
- [x] Compliance webhooks: customers/data_request, customers/redact, shop/redact
- [x] HMAC signature verification on all webhooks
- [x] Webhook fallback safety: no Shop.active.first fallback on destructive actions
- [x] SSL enforced in production (force_ssl, assume_ssl)
- [x] Host authorization configured for app.happypages.co
- [x] Data protection questionnaire submitted in Partner Dashboard
- [x] Protected customer data access requested (email, first_name)
- [x] Public distribution app with unlisted visibility (client_id: 98f21e1016de2f503ac53f40072eb71b)
- [ ] Privacy policy URL added to app listing
- [ ] Flip support_unencrypted_data to false after confirming encryption
- [ ] Full app submission for Shopify review

## Planned Features

- [ ] Services/features grid
- [ ] Testimonials section
- [ ] Contact form integration
- [ ] Mobile menu

## Version History

| Date | Changes |
|------|---------|
| 2026-02-06 | PII compliance: encryption, audit logs, compliance webhooks, privacy policy |
| 2026-02-06 | Recreated app with public distribution (unlisted) for multi-merchant installs |
| 2026-02-06 | Fixed critical webhook fallback bug (Shop.active.first on destructive actions) |
| 2026-02-06 | SSL, host authorization, and mailer config enabled in production |
| 2026-01-29 | White-labeled URLs: shop-specific referral pages with auto-generated slugs |
| 2026-01-29 | Railway deployment: Rails backend + Shopify extension deployed to app.happypages.co |
| 2026-01-29 | Shopify OAuth: Self-service app installation with redirect URL configuration |
| 2026-01-29 | Footer: Added referrals login link to main site |
| 2026-01-29 | Railway: Fixed watch patterns for multi-service deployment (static site + Rails app) |
| 2026-01-16 | /happier: Step card videos (desktop) + GIFs (mobile/iOS), sequential playback |
| 2026-01-16 | /happier: Pricing CTA redesign, grid animation, works card styling |
| 2026-01-16 | PNG icons for performance, CSS containment, orbit animation, floating icons |
| 2026-01-16 | Added works section with card deck shuffle carousel (bidirectional animation) |
| 2026-01-15 | Added step cards with scroll animation, client logos, copy updates |
| 2026-01-15 | Added how-it-works section, animated bars, card stack, typography updates |
| 2026-01-15 | Initial landing page with hero, neumorphic card, Railway deployment |
