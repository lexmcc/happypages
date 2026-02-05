# Project Learnings

Detailed learnings, gotchas, and session discoveries. Claude reads this when working on related areas.

## Gotchas & Bug Fixes

### Gallery Reset on Selection (Feb 5, 2026)

**Issue:** Gallery would reset to index 0 when clicking flavor selector cards.

**Root Cause:** Both `selectOption()` and `toggleFlavor()` in `shop-purchase-flow.liquid` contained `this.currentImageIndex = 0;` which reset the gallery on every selection.

**Fix:** Remove the `currentImageIndex = 0` lines from both methods. Gallery state should be independent of flavor selection state.

**Lesson:** When adding state reset logic to selection handlers, consider which state actually needs to reset. UI navigation state (like gallery position) usually shouldn't reset when selection state changes.

## Patterns & Best Practices

<!-- Effective approaches for this codebase -->

## API & Library Quirks

<!-- Undocumented behaviors, edge cases -->

## Config & Environment

<!-- Build, deploy, environment discoveries -->

---
*Updated: Feb 5, 2026*
