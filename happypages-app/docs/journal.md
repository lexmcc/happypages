# Journal — HappyPages App

## 2026-03-12 17:00 | HappyPages App | session | [wrap]
Fixed unread indicators not persisting across refresh on ops dashboard. Root cause: server.js hadn't been restarted after adding the `/api/mark-read` route — route registration only runs at startup, so the POST was 404ing and `.read-comms.json` was never created. Restarted the Node server process; verified endpoint returns correctly.

## 2026-03-11 | HappyPages App | call | Ben — Referrals Debug
Fixed discount code webhook bug (API version mismatch from custom app migration). Live-tested referrals with Ben. Found two bugs: self-referral prevention not working (user can use their own code), and reward discounts not grouping properly. Ben's launch priorities: discount codes working, self-referral blocked, metafields confirmed, per-customer referral page link. Agreed Klaviyo event is next on roadmap for reward notifications. Atomic integration to launch OFF, turn on later. Also discussed PostHog — Ben sold on it, agreed to integrate. Quiz simplification project incoming from Sam (elderly UX, progressive disclosure, 4% completion improvement = ~$300k/yr LTV). Commitments: fix self-referral bug, check metafield setup, fix discount grouping, send Ben list of Shopify API touchpoints.

## 2026-03-06 17:30 | HappyPages App | session | [wrap]
Deployed super admin ops dashboard to staging. Initial approach (Rails server-side proxy to local Node server) failed — Railway can't reach localhost. Pivoted to client-side fetch: browser fetches directly from 127.0.0.1:3333 and injects HTML. Removed OPS_TOKEN auth (superadmin layer is sufficient for a localhost-only server). Fixed macOS IPv6 resolution issue (localhost→::1 vs Node binding 127.0.0.1). Updated CORS on Node server to `*`. Doc checkpoint: updated CHANGELOG, HISTORY, LEARNINGS (2 new), SPEC (promoted completed checkboxes to prose, added ops dashboard to superadmin section), MEMORY.
