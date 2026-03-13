# Oatcult PDP Redesign: Research & Recommendations

## Brief

**Client:** oatcult.com (Shopify)
**Page:** /pages/shop — subscription oat milk box
**Goal:** Increase subscription sign-ups
**SKUs:** 1-3 core products
**Brand:** Bold / rebellious (Oatly territory, not wellness fluff)
**Audience:** Health-conscious millennials + convenience seekers
**Pain points:** Generic design, weak storytelling, poor mobile, not converting — product picker is the one bright spot

---

## Research Scope

**15+ D2C subscription brands analysed** across UX conversion flows and visual design systems. Brands weighted by relevance to oatcult's model (subscription-first, small SKU count, bold personality, site-is-the-business).

### Core benchmark brands (D2C-first, subscription-driven)
- **AG1** — single hero product, subscription-first, narrative-driven page flow
- **Grind** — coffee subscription, premium restraint, small SKU range
- **Huel** — subscription meals, multi-product but subscription-anchored
- **Magic Spoon** — cereal subscription, build-your-own bundles, bold brand
- **Surreal Cereal** — best-in-class subscription toggle UX, irreverent copy
- **Who Gives A Crap** — subscription toilet paper, irreverent brand, packaging-as-hero
- **Mid-Day Squares** — snack brand, exceptional typography and visual energy
- **Ceremony Coffee** — premium coffee subscription, editorial design quality
- **Oats Overnight** — direct competitor, "build a box" model, co-creation angle

### Aesthetic references only (retail-first, site is a brand play)
- **Liquid Death** — dark-background commitment, illustration-driven personality
- **Oatly** — copy-as-design, hand-drawn type (brand reference for tone)

---

## Part 1: UX Conversion Patterns

### How top D2C brands present subscription

| Pattern | Who does it | How it works |
|---------|------------|-------------|
| **Subscription as default, one-time as alternative** | AG1, Huel | Subscribe toggle is pre-selected. One-time requires deliberate opt-out. Subscription framed as "the normal way to buy" |
| **Save X% messaging on toggle** | Grind (25%), Huel (10%), Magic Spoon (25%) | Percentage savings displayed directly on the subscribe/one-time toggle. Immediate, quantifiable incentive |
| **Bundled perks beyond discount** | Grind (free tin + free shipping + flexibility), AG1 (welcome kit + 5 free travel packs) | Subscription value goes beyond price — free stuff, priority access, exclusive perks. Makes one-time feel like you're leaving value on the table |
| **Build-your-own bundle** | Magic Spoon, Huel | For brands with 3+ flavours, letting customers mix their own box increases engagement and perceived control. Reduces "what if I don't like it" hesitation |
| **Flexibility-first language** | AG1 ("update or cancel anytime"), Grind ("complete flexibility"), Huel ("pause, swap or cancel") | The #1 subscription objection is commitment fear. Every top brand addresses this within pixels of the subscribe CTA |
| **"Why Subscribe?" modal** | Surreal | Clickable link opens popup listing 3-4 subscription benefits with icons. Non-intrusive but available for hesitant buyers. Brilliant for mobile where space is limited |
| **Subscription-as-membership** | AG1 ("Try AG1 Now"), Oats Overnight ("Join the club") | Frame subscription as joining something, not a billing arrangement. For oatcult: "Join the cult" is sitting right there |
| **Welcome gift with first order** | AG1 (shaker + travel packs), Grind (free tin) | Physical gift increases perceived value beyond the discount. Makes unboxing shareable |

**Recommendation for oatcult:** Subscription should be the default-selected option on the product picker. The toggle should show savings immediately ("Save X%") AND bundle at least one perk beyond price (free shipping is the easiest). "Skip, pause, or cancel anytime" must appear directly below the CTA — not buried in FAQ. CTA copy should lean into the brand: "Join the cult" not "Subscribe."

### Subscription pricing context

oatcult's 20% subscription discount is competitive in the market:

| Brand | Subscription Discount |
|-------|-----------------------|
| AG1 | 20% |
| Magic Spoon | 25% |
| Grind | Up to 25% |
| Surreal | 20% |
| Olipop | 15% |
| Huel | 10% |
| **oatcult** | **20%** |

The issue isn't pricing — it's presentation. The discount is there but isn't being sold.

### Page structure: the narrative scroll

The highest-converting single-product subscription pages (AG1 is the gold standard) follow a specific section order that builds a persuasion arc:

```
1. HERO — Hook + primary CTA
   Bold headline, product image, subscribe CTA, key benefit (one line)

2. SOCIAL PROOF BAR — Credibility in seconds
   Review count + star rating, "as seen in" logos, or key stat

3. HOW IT WORKS — Ritual framing (critical for overnight oats)
   3 steps: "Choose your oats → Add milk, leave overnight → Wake up to breakfast"
   Positions subscription as natural: "fresh oats delivered, ready when you are"

4. WHAT YOU GET — Product education
   What's in the box, ingredients/nutrition, benefit badges (1B live cultures, gluten-free)

5. WHY THIS EXISTS — Brand story / problem framing
   Why overnight oats? Why oatcult specifically? The rebellious angle lives here

6. PROOF IT WORKS — Testimonials + results
   Customer quotes with specific outcomes, photo/video reviews (+21-29% lift)

7. OBJECTION HANDLING — Remove friction
   Cancel anytime, money-back guarantee, FAQ in brand voice
   e.g. "Can I leave the cult?" → "Yes. Cancel or pause anytime. But why would you?"

8. FINAL CTA — Close the loop
   Repeat the offer with per-serving price reframing ("just £X per serving")
```

**What oatcult likely has now:** A product grid/picker without this narrative wrapper. The picker works (client confirmed) but it's floating in a vacuum — no story, no proof, no objection handling around it.

**Recommendation:** Wrap the existing product picker in this narrative structure. The picker itself becomes section 1 (hero) or section 3 (what you get). Everything else is new content that sells the subscription.

### Trust signals & social proof placement

| Signal | Where to place | Why |
|--------|---------------|-----|
| **Review count + stars** | Hero section, directly below product name | AG1 puts "50,000+ 5-star reviews" in the first viewport. Immediate credibility |
| **"Cancel anytime"** | Directly below subscribe CTA | Grind, AG1, Huel all do this. Must be within the CTA's visual group, not a separate section |
| **Money-back guarantee** | Below CTA AND in objection-handling section | AG1: "30-day money-back guarantee." Huel: "30-day taste guarantee." Reduces perceived risk to zero |
| **Customer testimonials** | Own section between product details and final CTA | Use specific quotes about outcomes, not generic "great product" reviews |
| **Trust badges** | Footer area or below fold | Less critical for food subscription than for health/supplements |

### Mobile-specific UX patterns

| Pattern | Who does it | Impact |
|---------|------------|--------|
| **Sticky bottom CTA bar** | AG1, Hims, Huel | CTA is always one thumb-tap away. Appears after scrolling past the hero CTA. This is table stakes for mobile subscription pages |
| **Accordion FAQ** | AG1, Huel, Magic Spoon | Collapses objection-handling content without creating wall of text on mobile |
| **Full-width product images** | All top brands | No padding, no cropping on mobile hero images. Product fills the viewport |
| **Simplified toggle** | AG1, Grind | Subscribe/one-time toggle must be minimum 48px touch targets with clear active state |
| **Price prominence** | Huel ("From £1.09/meal") | Per-unit pricing on mobile where screen real estate is limited |

**Recommendation:** Sticky bottom CTA bar is the single highest-impact mobile change. When a user scrolls past the hero, the subscribe CTA follows them. Every top D2C brand does this.

### Subscription objection handling

The top 5 objections for food subscription boxes and how the best brands handle them:

1. **"I don't want to be locked in"** → "Skip, pause, or cancel anytime" (AG1, Grind, Huel) — place within CTA group. EVERY top brand places cancellation language within 1 line of the subscribe CTA
2. **"What if I don't like it?"** → Money-back / taste guarantee (Huel's "30-day taste guarantee" is best-in-class). For oatcult: "Love your first box or it's on us"
3. **"Is it worth the price?"** → Per-serving pricing reframes the commitment ("just £2 per serving" vs "£18 per box"). AG1 does this brilliantly — £2.60/serving makes £59/month feel tiny
4. **"I don't know what I'm getting"** → Ingredient transparency, "what's in the box" section with photography + benefit badges (1B live cultures, gluten-free, no added sugar)
5. **"I already have a routine"** → Convenience framing ("delivered to your door, ready in the fridge") + "How It Works" ritual section that makes overnight oats feel effortless
6. **"I'll get too much / not enough"** → Delivery frequency selector (every 2, 4, or 6 weeks) + ability to skip shipments. Surreal and Grind both offer 3+ frequency options

---

## Part 2: Visual Design Direction

### Typography: the #1 quick win

**The problem:** Inter is a solid workhorse font, but it's what every tech startup and generic Shopify store uses. It doesn't say "rebellious oat milk brand." The headlines need character.

**The fix:** Introduce a chunky geometric display typeface for headlines while keeping Inter for body text.

| Role | Current | Recommended | Rationale |
|------|---------|------------|-----------|
| **Display / hero headlines** | Inter | Clash Display, Space Grotesk, or Satoshi (all free) | Chunky geometric sans-serifs signal bold confidence. Mid-Day Squares uses ABCROMExtended-Heavy at 5.5em+ to stunning effect. Surreal uses RocGrotesk. This is the single biggest design upgrade |
| **Section headings** | Inter | Inter Bold, uppercase, wide letter-spacing (2-3em) | Creates contrast with the tight, heavy display headlines |
| **Body text** | Inter | Inter Regular 16-18px | It works. Don't change it |
| **Technical / pricing** | Inter | JetBrains Mono or Roboto Mono | Monospace for nutritional data, pricing, subscription details. Adds visual rhythm (Mid-Day Squares does this brilliantly) |
| **Letter-spacing** | -3% | Headlines: -4% to -5%. Body: -1% to -2% | Tighter headline spacing creates density and urgency |

### Color palette: refine, don't replace

**Current:** #171717 (dark) + #dc2626 (red) + Inter
**Problem:** When red is used everywhere, nothing stands out. The dark theme without dramatic photography just feels dark, not bold.

**Recommended palette:**

| Role | Color | Usage |
|------|-------|-------|
| **Primary dark** | #171717 (keep) | Hero sections, header, key brand moments |
| **CTA red** | #dc2626 (keep) | PRIMARY CTAs ONLY. Subscribe button, key action moments. Scarcity of red makes it powerful |
| **Warm cream** | #FBF7F0 or #FFF9E2 | Alternating content sections. Breaks up relentless darkness, adds warmth |
| **Text on dark** | #F5F5F5 (not pure white) | Reduces eye strain, feels more premium than #FFFFFF |
| **Info accent** | Muted teal (#2dd4bf) or electric blue (#3b82f6) | Badges, nutrition info, trust signals, secondary UI elements |

**Key principle:** Dark sections alternating with warm cream sections creates rhythm. AG1 does this — dark hero, light education section, dark testimonials, light FAQ. Prevents the page from feeling like a black hole.

### Photography direction

**What works for bold food subscription brands on dark backgrounds:**

1. **Hero product shot** — dramatic side-lighting on dark background (not flat studio lighting on white)
2. **Ingredient flat-lays** — oats, seeds, berries scattered on dark surface. Golden oats on near-black = striking
3. **Process / pour shots** — milk being poured, oats being prepared. Motion blur adds energy
4. **Packaging as hero** — style the box itself as a design object (Who Gives A Crap's entire visual identity)
5. **Lifestyle context** — product on a counter, in a fridge, morning routine. Grounds the subscription in real life

**Avoid:** White studio backgrounds (generic), stock photography (kills authenticity), "person smiling while eating" (every brand does this)

### Micro-interactions: 3 priorities

1. **Subscription toggle** — when user switches to subscribe, price animates/counts down and a "you save X" badge slides in. Makes choosing subscription feel rewarding, not transactional
2. **Add-to-cart** — brief animation in brand red. Not a generic checkmark. Something with personality
3. **Scroll-triggered reveals** — content sections fade/slide in on scroll. Guides the narrative, keeps attention. Mid-Day Squares uses 0.4-0.6s ease transitions

### Mobile design specifics

- Sticky CTA bar at bottom (not top) — thumb-zone optimised
- Typography scales aggressively: 4rem desktop headlines → 2.5rem mobile (not percentage reduction)
- Full-width product images, zero padding on hero
- Subscription toggle: minimum 48px touch targets
- Reduce motion on mobile (respect `prefers-reduced-motion`)
- Dark sections may need slightly lighter background on mobile (#1a1a1a → #222222) for readability

---

## Part 3: Recommended Approach

### Option A: Narrative Wrapper (Recommended)

**What:** Keep the existing product picker (it works) and wrap it in a full narrative page structure. Redesign everything around the picker — hero, story, proof, objection handling, final CTA.

**Effort:** Medium (new content sections + design refresh, existing picker stays)
**Impact:** High (addresses all pain points: storytelling, trust, mobile, conversion)

**Page structure:**
1. Hero — bold headline + product image + subscribe CTA + "cancel anytime"
2. Social proof bar — review stars + count + key stat
3. Product picker (existing) — enhanced with subscription-default toggle + savings display
4. "What's in the box" — ingredient/nutrition transparency section
5. Brand story — why oatcult exists, the rebellious angle, problem framing
6. Testimonials — customer quotes with specific outcomes
7. Objection handling — FAQ accordion (cancel anytime, taste guarantee, flexibility)
8. Final CTA — repeat offer with incentive

### Option B: Full PDP Rebuild

**What:** Redesign the entire page from scratch including the product picker. New information architecture, new design system, new interaction patterns.

**Effort:** High (full design + development cycle)
**Impact:** Highest (but the picker already works, so incremental gain over Option A is debatable)

**When to choose this:** If the current Shopify theme (Impact) is too constraining to implement the narrative wrapper properly, or if the product picker needs fundamental changes to support subscription-first defaults.

### Option C: Progressive Enhancement

**What:** Ship improvements incrementally — typography first, then photography, then narrative sections, then mobile optimisation.

**Effort:** Low per increment (can ship weekly)
**Impact:** Compounds over time, allows A/B testing each change

**When to choose this:** If resources are limited or you want to validate each change with data before committing to the full redesign.

---

## Part 4: Highest-Impact Changes (ranked)

| Rank | Change | Effort | Impact | Rationale |
|------|--------|--------|--------|-----------|
| **1** | Add sticky mobile CTA bar | Low | High | Every top D2C brand does this. Users lose the CTA when they scroll. Table stakes |
| **2** | Make subscription the default toggle | Low | High | Pre-select subscribe, show savings inline. One-time becomes the opt-out, not the default |
| **3** | Add "cancel anytime" + guarantee near CTA | Low | High | #1 subscription objection killer. AG1, Grind, Huel all do this. Placement matters — within the CTA group, not in FAQ |
| **4** | Typography upgrade (display font for headlines) | Low-Med | High | Biggest visual impact for smallest effort. Transforms generic → distinctive in one change |
| **5** | Add social proof section (reviews/testimonials) | Medium | High | If Okendo is already integrated (it is), surface review count + stars in hero. Add 3-4 customer testimonial cards |
| **6** | Add narrative sections (brand story + "what's in the box") | Medium | High | Fills the storytelling gap. This is where the rebellious brand voice earns its keep |
| **7** | Photography upgrade (dark-background product shots) | Medium | High | Current generic imagery is the #2 reason the page feels generic. Dramatic photography on dark backgrounds = instant premium |
| **8** | Color hierarchy refinement (red for CTAs only + cream sections) | Low | Medium | Adds rhythm to the page and makes CTAs pop by contrast |
| **9** | Mobile type scaling + full-width images | Low | Medium | Quick CSS changes with outsized mobile impact |
| **10** | Micro-interactions (subscription toggle animation, scroll reveals) | Medium | Medium | Polish that makes the experience feel ownable. Ship after the fundamentals are solid |

---

## Part 5: Brand Benchmarks Summary

### What to steal from each brand

| Brand | What to take | What to leave |
|-------|-------------|--------------|
| **AG1** | Narrative page flow (hook → educate → prove → convert), credibility stacking, "cancel anytime" placement, sticky mobile CTA | Over-reliance on celebrity endorsement, clinical trial framing (wrong for oat milk) |
| **Grind** | Premium restraint, subscription perks beyond discount (free stuff + free shipping + flexibility), variant-stacking for small SKU range | Minimalist aesthetic might be too quiet for oatcult's bold personality |
| **Huel** | Per-serving pricing, "30-day taste guarantee," quiz mechanism for product selection, "No Bullshit" objection handling section | Corporate feel, too many products for oatcult's simpler range |
| **Magic Spoon** | Build-your-own bundle UX, 80k+ reviews displayed prominently, subscription savings on toggle | Playful/colourful aesthetic is wrong energy for oatcult |
| **Mid-Day Squares** | Multi-typeface hierarchy, color energy, animation timing (0.4-0.6s), generous vertical spacing | No subscription model to learn from |
| **Who Gives A Crap** | Packaging-as-hero photography, irreverent brand voice in UX copy, making every box shareable/content-worthy | Primarily one-time purchase flow |
| **Surreal** | Best-in-class subscription toggle (dual radio + frequency selector + "cancel anytime" + "Why Subscribe?" modal), irreverent FAQ copy | Expanding into retail — use for UX patterns, not conversion benchmarks |
| **Liquid Death** | Commitment to dark backgrounds, illustration > stock photography, scarcity of accent color | Retail-first site, not optimised for conversion |
| **Oats Overnight** | Direct competitor reference, "build a box" bundle UX, subscriber co-creation (flavour development access) | Generic visual design — this is what oatcult should be the anti-version of |

### What oatcult should feel like

**The intersection of:**
- AG1's persuasion architecture (narrative flow, credibility stacking)
- Mid-Day Squares' visual energy (typography, color, animation)
- Grind's premium restraint (whitespace, product-led design)
- Oatcult's own rebellious voice (dark, punchy, no fluff)

**Not:**
- Oatly copy (that's their territory — oatcult needs its own voice)
- Generic wellness aesthetic (sage green, thin sans-serif, calm)
- Template Shopify store (Impact theme defaults)

---

## Standout UX Ideas Worth Exploring

These are patterns that go beyond the basics and could differentiate oatcult:

1. **"Join the cult" membership framing** — subscription isn't a billing arrangement, it's cult membership. Insider benefits, early access to new flavours, community. Oats Overnight does subscriber co-creation (flavour development input) which maps perfectly to oatcult's brand
2. **Per-serving price anchoring** — "just £X per serving" in the final CTA reframes the entire price perception. AG1 does this to make £59/month feel like nothing
3. **Brand-voice FAQ** — instead of corporate Q&A, use the cult persona. "Can I leave the cult?" / "What's actually in this?" / "Is this just porridge?" — Surreal does irreverent FAQ copy brilliantly
4. **"Why Subscribe?" modal** (Surreal pattern) — a small "why subscribe?" link near the toggle opens a focused modal with 3-4 benefits. Non-intrusive, but catches the hesitant buyer. Excellent on mobile where space is tight
5. **Welcome kit / gift with first subscription** — AG1 bundles a shaker + travel packs, Grind includes a free tin. A branded item with the first box makes unboxing shareable and increases perceived value beyond the discount

---

## Conversion Lift Benchmarks

From industry research (Baymard Institute, Digital Applied 2026):

| Change | Expected Lift |
|--------|--------------|
| Star ratings near product title | +8-15% conversion |
| Review count near CTA | +5-10% conversion |
| Photo/video reviews | +21-29% conversion |
| Sticky mobile CTA bar | +7.9% completed orders |
| Vertically collapsed sections (accordion) vs horizontal tabs | 8% miss content vs 27% |

---

## Open Questions

1. **Which subscription app is oatcult using?** (Impacts what's possible with toggle/pricing display)
2. **Does oatcult have customer reviews already?** (Okendo is installed — 29 reviews at 5.0 stars found on product page. Enough to display but not enough for "thousands of reviews" social proof)
3. **Photography budget?** (Dark-background product photography is a significant investment but arguably the highest-impact brand change)
4. **Is the product picker a custom Shopify section or app?** (Determines how much we can modify vs wrap around it)
5. **Are there plans to add more SKUs?** (Affects whether we need build-your-own bundle UX)
6. **Any press coverage?** (If yes, "as seen in" logos are a quick trust signal win)
7. **Welcome gift feasibility?** (Cost/logistics of including a branded item with first subscription box)

---

*Research conducted across 15+ D2C subscription brands. UI design benchmarking covered typography, color, photography, micro-interactions, and mobile design. UX conversion analysis covered subscription presentation, page structure, trust signals, objection handling, and mobile patterns.*
