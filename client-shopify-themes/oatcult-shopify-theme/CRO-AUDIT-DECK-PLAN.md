# CRO Audit Interactive Slide Deck

## Deliverable
Single standalone HTML page for presenting the CRO audit to Oat Cult.

---

## Requirements

### Core
- Single self-contained HTML file (inline CSS/JS, no external dependencies)
- Mobile-first, responsive design
- Match Oat Cult brand (brown/earth tones)

### Mobile Experience
- **TikTok-style vertical swipe** navigation
- Full-screen slides (100vh)
- Smooth scroll-snap behavior
- Progress indicator

### Desktop Experience
- Arrow key navigation (up/down)
- Click to advance
- Optional: side navigation dots

---

## Slide Content

Based on `CRO-AUDIT-CLIENT.md`:

| # | Slide | Key Message |
|---|-------|-------------|
| 1 | Title | Oat Cult Product Page CRO Audit |
| 2 | Bottom Line | "Your page is leaving money on the table" |
| 3 | Current Issues | 5 friction points (table) |
| 4 | Rec 1: Box Size | Clear tier cards with pricing |
| 5 | Rec 2: Flavors | Mixed Box vs Pick Your Own |
| 6 | Rec 3: Subscription | Lead with 20% savings |
| 7 | Rec 4: Free Shipping | Strategic upsell nudges |
| 8 | Rec 5: Social Proof | Reviews + trust badges |
| 9 | Rec 6: Direct Checkout | Skip the cart |
| 10 | Results | +25-40% conversion, +40-60% subs |
| 11 | Timeline | 4-phase plan |
| 12 | Next Steps | CTA to proceed |

---

## Technical Implementation

### CSS (Mobile Scroll-Snap)
```css
html, body {
  margin: 0;
  height: 100%;
  overflow-x: hidden;
}

.deck {
  height: 100vh;
  overflow-y: scroll;
  scroll-snap-type: y mandatory;
  -webkit-overflow-scrolling: touch;
}

.slide {
  height: 100vh;
  scroll-snap-align: start;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 24px;
  box-sizing: border-box;
}
```

### JavaScript (Keyboard Nav)
```javascript
document.addEventListener('keydown', (e) => {
  const deck = document.querySelector('.deck');
  const slideHeight = window.innerHeight;

  if (e.key === 'ArrowDown' || e.key === ' ') {
    deck.scrollBy({ top: slideHeight, behavior: 'smooth' });
  } else if (e.key === 'ArrowUp') {
    deck.scrollBy({ top: -slideHeight, behavior: 'smooth' });
  }
});
```

### Progress Indicator
```css
.progress {
  position: fixed;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 100;
}

.progress-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(139, 69, 19, 0.3);
  transition: all 0.2s;
}

.progress-dot.active {
  background: #8B4513;
  transform: scale(1.25);
}
```

---

## Brand Colors (Oat Cult)

```css
:root {
  --brand-brown: #8B4513;
  --brand-brown-light: #D2691E;
  --brand-cream: #FFF8F0;
  --brand-dark: #3D2314;
  --text-primary: #333333;
  --text-muted: #666666;
}
```

---

## Output File

```
/oatcult-shopify-theme/cro-audit-deck.html
```

Can be hosted anywhere (GitHub Pages, Netlify, or sent directly).

---

## Verification

- [ ] Opens correctly as standalone file
- [ ] Swipe navigation works on mobile (iOS Safari, Chrome)
- [ ] Keyboard navigation works on desktop
- [ ] Progress indicator updates correctly
- [ ] All 12 slides render with correct content
- [ ] Brand colors applied consistently
- [ ] Text readable on all screen sizes
