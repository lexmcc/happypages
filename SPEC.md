# Landing Page Spec

Static marketing site for HappyPages — a design & dev subscription for D2C founders.

**Live:** https://happypages.co

## Current State

Single-page responsive site served by a zero-dependency Node.js server on Railway. Two variants: main page (`/`) and design exploration (`/happier`).

### Main Page

- **Hero** — two-column layout with headline, subheading, and neumorphic join card (animated coral bars header, card stack effect)
- **How It Works** — 3 step cards (Subscribe, Request, Receive) with scroll-triggered spread animation, client logos row, floating icons on SVG path
- **Member Benefits** — horizontal carousel of 5 benefit cards with unique animated patterns per card
- **Works Section** — card deck carousel (3 stacked cards, shuffle animation) + text card with service pills and orbiting icons
- **Pricing** — toggle between basic/pro with typing animation on price/feature changes
- **FAQ** — 13-question accordion with CTA card
- **Footer** — Cal.com booking integration, terms/privacy links, referrals login link

### Design Exploration (/happier)

Variant with step card videos (desktop) / GIFs (mobile/iOS), animated coral grid on works card, cleaner look without floating icons.

### Overview Page (/overview)

Self-contained interactive page for client meeting prep. System architecture diagram with clickable nodes showing real code examples, user journey flow, feature map with roadmap section, Hydrogen integration guide, and testing plans for one-off and subscription flows. Print-to-PDF layout.

### Technical

Zero-dependency Node.js server, clean URL routing, responsive breakpoints at 1024px/768px. PNG icons for animation performance, CSS containment, prefers-reduced-motion support.

## What's Next

- [ ] Services/features grid section
- [ ] Testimonials section
- [ ] Contact form integration
- [ ] Mobile hamburger menu
