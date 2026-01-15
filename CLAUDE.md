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

## Design

- Max container width: 1200px with light grey side borders
- Background: #F4F4F0
- Primary font: Hanken Grotesk (Google Fonts)
- Hero h1: 84pt desktop, 36pt mobile
