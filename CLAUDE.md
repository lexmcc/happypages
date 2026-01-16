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

- Hosted on Railway at https://happypages-production.up.railway.app
- GitHub repo connected for auto-deploy on push to `main`
- Railway project: https://railway.com/project/66f72304-7d9e-4860-9b50-aef51f26c5d2

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
