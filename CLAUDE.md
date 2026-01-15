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

- `server.js` - Vanilla Node.js HTTP server serving files from `public/`
- `public/index.html` - Single-page HTML
- `public/styles.css` - All styles (responsive breakpoint at 768px)
- `public/assets/` - Static assets (logo images)

## Deployment

- Hosted on Railway at https://happypages-production.up.railway.app
- GitHub repo connected for auto-deploy on push to `main`
- Railway project: https://railway.com/project/66f72304-7d9e-4860-9b50-aef51f26c5d2

## Rules

- Never run `git push` unless the user explicitly confirms (e.g., "push", "yes", "push to prod")

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
- `.how-it-works-section` - Second section with centered heading
