# Project Learnings

Detailed learnings, gotchas, and session discoveries. Claude reads this when working on related areas.

## Gotchas & Bug Fixes

### Gallery Reset on Selection (Feb 5, 2026)

**Issue:** Gallery would reset to index 0 when clicking flavor selector cards.

**Root Cause:** Both `selectOption()` and `toggleFlavor()` in `shop-purchase-flow.liquid` contained `this.currentImageIndex = 0;` which reset the gallery on every selection.

**Fix:** Remove the `currentImageIndex = 0` lines from both methods. Gallery state should be independent of flavor selection state.

**Lesson:** When adding state reset logic to selection handlers, consider which state actually needs to reset. UI navigation state (like gallery position) usually shouldn't reset when selection state changes.

### Thumbnail Scroll-into-View Missing (Feb 5, 2026)

**Issue:** Clicking a gallery thumbnail that was partially off-screen didn't scroll it into view.

**Root Cause:** `selectImage(index)` only set `currentImageIndex = index` with no scroll logic. Meanwhile, `scrollToImage(index)` had proper scroll logic but was only called from `selectFlavor()`.

**Fix:** Change `selectImage()` to delegate to `scrollToImage()` instead of duplicating the index assignment.

**Lesson:** When multiple methods need the same behavior, delegate to a single source of truth rather than duplicating logic. Look for existing methods that already do what you need.

### Sticky Gallery CSS Cascade Issue (Feb 5, 2026)

**Issue:** Sticky gallery not working on desktop despite `position: sticky` in media query.

**Root Cause:** CSS cascade order bug. The base `.shop-gallery` styles (with `position: relative`) appeared AFTER the media query in the source:

```css
/* Media query (lines 145-152) */
@media screen and (min-width: 1000px) {
  .shop-gallery {
    position: sticky;  /* Should apply on desktop */
  }
}

/* Base styles (lines 163-166) - comes AFTER, so wins! */
.shop-gallery {
  position: relative;  /* Overrides sticky */
}
```

When two CSS rules have the same specificity, the one appearing later wins. The base `position: relative` overrode `position: sticky`.

**Fix:**
1. Remove `position: relative` from base `.shop-gallery` styles (not needed - sticky is positioned by definition)
2. Change `top: var(--header-height, 100px)` to `top: calc(var(--sticky-area-height) + 20px)` to match theme patterns

**Lesson:** When media queries don't seem to apply, check if base styles appear AFTER the media query and override it. Either increase specificity, reorder the CSS, or remove the conflicting base property.

### Mobile Horizontal Overflow from scrollIntoView (Feb 5, 2026)

**Issue:** On mobile, the entire page could be pushed/dragged left/right. Clicking a half-visible flavor pill caused the screen to jump horizontally.

**Root Cause:** Three places in `shop-purchase-flow.liquid` used `scrollIntoView()`:
- Flavor tab click (line ~2974)
- Gallery thumbnail click (line ~3000)
- Flavor card click (line ~3067)

`scrollIntoView()` walks up the DOM and scrolls ALL scrollable ancestors, including `<html>`. When an element is half off-screen in a horizontal carousel, it scrolls the page itself horizontally.

**Fix:** Replace `scrollIntoView()` with container-specific `scrollTo()`:
```javascript
// Before
element.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });

// After
const container = element.closest('.container-class');
if (container) {
  const scrollLeft = element.offsetLeft - (container.offsetWidth / 2) + (element.offsetWidth / 2);
  container.scrollTo({ left: Math.max(0, scrollLeft), behavior: 'smooth' });
}
```

**Lesson:** Never use `scrollIntoView()` for horizontal carousels on mobile. It causes page-level horizontal scroll. Use `container.scrollTo()` to scroll only the intended container.

## Patterns & Best Practices

### Method Delegation for Shared Behavior
When multiple entry points need the same behavior (e.g., `selectImage()` and `selectFlavor()` both need to scroll thumbnails), have them delegate to a shared method (`scrollToImage()`) rather than duplicating logic.

## API & Library Quirks

### scrollIntoView() Scrolls All Ancestors
`element.scrollIntoView()` scrolls every scrollable ancestor up to `<html>`, not just the immediate container. For horizontal carousels, use `container.scrollTo()` instead to avoid page-level horizontal scroll on mobile.

## Config & Environment

<!-- Build, deploy, environment discoveries -->

---
*Updated: Feb 5, 2026*
