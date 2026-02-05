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

## Patterns & Best Practices

### Method Delegation for Shared Behavior
When multiple entry points need the same behavior (e.g., `selectImage()` and `selectFlavor()` both need to scroll thumbnails), have them delegate to a shared method (`scrollToImage()`) rather than duplicating logic.

## API & Library Quirks

<!-- Undocumented behaviors, edge cases -->

## Config & Environment

<!-- Build, deploy, environment discoveries -->

---
*Updated: Feb 5, 2026*
