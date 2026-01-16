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

## Planned Features

- [ ] Services/features grid
- [ ] Testimonials section
- [ ] FAQ section
- [ ] Footer with links
- [ ] Contact form integration
- [ ] Mobile menu

## Version History

| Date | Changes |
|------|---------|
| 2026-01-16 | PNG icons for performance, CSS containment, orbit animation, floating icons |
| 2026-01-16 | Added works section with card deck shuffle carousel (bidirectional animation) |
| 2026-01-15 | Added step cards with scroll animation, client logos, copy updates |
| 2026-01-15 | Added how-it-works section, animated bars, card stack, typography updates |
| 2026-01-15 | Initial landing page with hero, neumorphic card, Railway deployment |
