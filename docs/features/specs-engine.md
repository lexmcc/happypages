# Specs Engine

## Goal

AI-powered specification tool that interviews stakeholders across multiple channels (web, Slack, Teams), produces client briefs and team specs, and tracks delivery through a built-in kanban board — initially for happypages' design/dev service clients, eventually a standalone SaaS product.

## Approach

Build on the existing interview engine (chunks 1-3) which handles the core AI loop: structured interviews with 4-phase progression, dual output (client brief + team spec), session versioning, image analysis, and multi-user handoffs. Extend outward in layers: client portal → channel integrations → project management → admin tooling → SaaS infrastructure.

The orchestrator and tool definitions are already channel-agnostic — they accept text input and return structured tool calls. Channel adapters (web, Slack, Teams) translate platform-specific events into orchestrator calls and render tool outputs back to the platform's native format.

## Chunks

### Shipped

#### 1. Core Interview Engine ✅
AnthropicClient (Net::HTTP wrapper with Sonnet/Opus/Haiku routing), PromptBuilder (8-section system prompt with caching, 4 phases: explore → narrow → converge → generate), Orchestrator (atomic transactions with pessimistic locking, parallel tool_use handling, Haiku compression every 8 turns). 4 tools: `ask_question`, `ask_freeform`, `generate_client_brief`, `generate_team_spec`. Web chat UI with Stimulus controller. Feature-gated behind "specs" ShopFeature. Rate-limited at 1 req/3s per project.

#### 2. Dual Output + Versioning ✅
Tabbed completed session view (Chat / Client Brief / Team Spec). Client Brief renders structured JSONB with sections. Team Spec renders chunks with acceptance criteria, dependency tags, UI badges, tech notes, design token swatches, and open questions. Markdown export for both. Session versioning — `POST new_version` creates a new session seeded with compressed context from previous outputs. Version dropdown when multiple exist. `analyze_image` tool extracts colors, typography, layout, spacing, effects from uploaded screenshots.

#### 3. Handoff + Multi-User ✅
`request_handoff` tool — AI suggests session handoffs with reason, summary, suggested questions, and suggested role. Admin can hand off internally (to another shop user, switches `session.user_id`) or create external invite (token-based, 7-day expiry). Guest access at `/specs/join/:token` with minimal layout, name entry, and full chat interface. Message attribution shows sender names when multiple participants. PromptBuilder adapts to active user context and includes handoff history. Guest routes rate-limited at 1 req/3s per invite token.

#### 4. Client Web Portal + Auth ✅
`Organisation` model for non-Shopify clients. `Specs::Client` with BCrypt auth (shared `Authenticatable` concern with User). Invite-based registration via `SpecsClientMailer` (7-day token expiry). Client portal at `/specs/*` — login, dashboard with project list, project creation and chat (`v1_client` tools — no handoff), client brief view and export (team spec hidden). Separate session keys (`specs_client_id`, `specs_last_seen`), 24h timeout. Superadmin org/client management at `/superadmin/organisations`. Rate-limited: 5/min login, 1 req/3s message.

#### 5. Kanban Board ✅
`Specs::Card` model with Backlog → In Progress → Review → Done statuses. Auto-populated from `generate_team_spec` output (one card per chunk, idempotent). Admin gets drag-and-drop via SortableJS + manual card creation. Clients get read-only board view. Board tab on completed sessions with team_spec or cards. JSON API for board CRUD.

#### 6. Channel Adapter Layer ✅
`Specs::Adapters::Base` wraps orchestrator calls. `Specs::Adapters::Web` handles web-specific formatting (strip team_spec for clients). `Specs::Adapters.for(session, **opts)` registry factory returns adapter by `session.channel_type`. `Specs::MessageHandling` concern DRYs error handling across admin/client/guest controllers. `Session.channel_type` (web/slack/teams) + `channel_metadata` (JSONB).

#### 7. Slack Integration ✅
`slack-ruby-client` gem. Organisation stores `slack_team_id`, `slack_bot_token` (encrypted), `slack_app_id`. `Specs::Client` has optional `slack_user_id` (unique per org). Controllers namespaced as `SlackIntegration::` (avoids `::Slack` gem collision). HMAC signature verification. Three webhook endpoints: events (threaded messages → `SlackEventJob`), actions (button clicks → `SlackActionJob`), commands (`/spec new` → `SlackCommandJob`). All orchestrator calls in SolidQueue background jobs. `SlackRenderer` for Block Kit. OAuth flow with CSRF state. Event deduplication via Rails.cache. JSONB partial index for session-by-thread lookup.

---

### To Build

#### 8. Microsoft Teams Integration
**What:** Teams bot that clients install to run spec interviews in Teams channels.

**Includes:**
- Teams bot (multi-tenant, via Azure Bot Service)
- Command to start: `@speccy new [project name]`
- Interview in channel or 1:1 chat
- Structured questions as Adaptive Cards (buttons + text input)
- Image upload support
- Completion summary posted in channel with link to web portal
- Same channel adapter interface as Slack

**Acceptance Criteria:**
- [ ] Given a client Teams tenant, when they install the bot, then it connects to their shop
- [ ] Given a user in Teams, when they mention `@speccy new My Project`, then a new session starts
- [ ] Given an active interview, when the AI calls `ask_question`, then Teams renders an Adaptive Card with option buttons
- [ ] Given a completed session, then the bot posts a summary with web portal link
- [ ] Given an image in a Teams message, then it's passed to the orchestrator

**Dependencies:** Chunk 6 (channel adapter layer)

**Technical Notes:**
- Azure Bot Framework SDK (or direct REST API to keep dependencies light)
- Teams uses Adaptive Cards (JSON-based) for rich messages — different from Slack Block Kit but same concept
- Bot registration in Azure Portal, manifest for Teams app store
- Can be built in parallel with Slack since both use the same adapter interface

#### 9. Linear Integration
**What:** Push reviewed spec chunks to Linear as issues, with bi-directional status sync.

**Includes:**
- Linear OAuth connection per shop (admin connects via integrations page)
- "Push to Linear" action on the kanban board — admin selects which cards to push
- Each pushed card becomes a Linear issue with: title, description, acceptance criteria as checklist, labels from chunk metadata
- Cards link back to their Linear issue (URL stored on card)
- Status sync: when a Linear issue moves to Done, the kanban card updates (webhook or polling)
- Linear project/team selector when pushing (admin chooses which Linear team)

**Acceptance Criteria:**
- [ ] Given an admin on the integrations page, when they click "Connect Linear", then OAuth flow connects their Linear workspace
- [ ] Given cards on the kanban board, when admin selects cards and clicks "Push to Linear", then Linear issues are created
- [ ] Given a pushed card, when the Linear issue status changes, then the kanban card status updates
- [ ] Given a pushed card, when viewing the card, then there's a link to the Linear issue
- [ ] Given a disconnected Linear integration, when admin views the board, then "Push to Linear" is hidden

**Dependencies:** Chunk 5 (kanban board)

**Technical Notes:**
- Linear API is GraphQL — `linear` gem or raw HTTP
- Store Linear OAuth token in `ShopIntegration` (provider: "linear")
- Webhook: Linear sends webhooks for issue updates — endpoint at `POST /integrations/linear/webhooks`
- Map kanban columns to Linear workflow states on setup

#### 10. Admin Dashboard + Notifications
**What:** Superadmin-level overview of all specs activity across all clients, plus in-app notification system.

**Includes:**
- Superadmin specs overview: all projects across all shops, filterable by status/shop
- Per-shop specs tab on superadmin shop management page
- In-app notification system: bell icon with unread count in admin nav
- Notification triggers: new spec completed, new client registered, card moved to Review, session approaching turn limit
- Notification preferences: admin can mute specific types
- Activity feed: chronological log of specs activity across all clients

**Acceptance Criteria:**
- [ ] Given a superadmin, when they visit the specs overview, then they see all projects across all shops with status
- [ ] Given a completed spec session, when it finishes, then the admin gets an in-app notification
- [ ] Given unread notifications, when admin views the nav, then the bell shows an unread count
- [ ] Given a notification, when admin clicks it, then they're taken to the relevant project/session
- [ ] Given notification preferences, when admin mutes a type, then they stop receiving those notifications

**Dependencies:** Chunks 4-5 (client portal + kanban)

**Technical Notes:**
- `Notification` model: `recipient_type`, `recipient_id`, `notifiable_type`, `notifiable_id`, `action`, `read_at`, `data` (JSONB)
- Stimulus controller for bell icon with polling or ActionCable for real-time count
- Notifications are polymorphic — can be attached to any model (session, card, project)
- Superadmin views extend existing superadmin namespace

[UI: Run `/frontend-spec` for detailed visual spec]

#### 11. Session Limits + Usage Gating
**What:** Enforce monthly spec session limits based on service tier, with soft buffer.

**Includes:**
- Monthly completed session counter per shop
- Tier configuration: Tier 1 = 5 sessions/month (3 deliverables + 2 buffer), Tier 2 = 8 sessions/month (6 deliverables + 2 buffer)
- Tier stored on shop or shop feature config
- "You've reached your spec limit for this month" message when limit hit — prevents starting new sessions
- Admin (superadmin) can override/adjust limits per shop
- Usage dashboard: admin sees how many sessions used this month vs limit
- Counter resets on billing cycle (1st of month, or configurable per shop)

**Acceptance Criteria:**
- [ ] Given a Tier 1 client with 5 completed sessions this month, when they try to start a new session, then they see a "limit reached" message
- [ ] Given a Tier 2 client with 3 completed sessions, when they check usage, then they see "3 of 8 used this month"
- [ ] Given a superadmin, when they view a shop, then they can see and adjust the session limit
- [ ] Given the 1st of the month, when the counter resets, then clients can start new sessions
- [ ] Given an active session that completes, when it finishes, then the monthly counter increments

**Dependencies:** Chunk 4 (client portal — for client-facing limit display)

**Technical Notes:**
- Could use `ShopFeature` metadata JSONB to store tier config (`{ "tier": 1, "monthly_limit": 5 }`)
- Counter: `Specs::Session.where(organisation_id: X).completed.where("created_at >= ?", cycle_start).count`
- Billing cycle: per-org anniversary date (stored on org record), not calendar month
- Or a dedicated `Specs::UsageRecord` model for audit trail
- Soft enforcement: check on session creation, not on every message

#### 12. Context Accumulation
**What:** Automatically build up project knowledge across sessions so the AI gets smarter about each client over time.

**Includes:**
- On session completion, extract key decisions, constraints, tech stack, and audience from the brief + spec outputs
- Write extracted context to `project.accumulated_context` JSONB (already exists, currently unused)
- Admin can view and edit accumulated context on the project page
- PromptBuilder already reads `accumulated_context` — this chunk populates it
- Extraction uses Haiku (cheap, fast) to parse the completed outputs

**Acceptance Criteria:**
- [ ] Given a completed session with outputs, when it finishes, then `accumulated_context` is populated with extracted decisions/constraints
- [ ] Given an existing `accumulated_context`, when a new session completes, then new context is merged (not overwritten)
- [ ] Given a project page, when admin views it, then they see the accumulated context and can edit it
- [ ] Given accumulated context on a project, when a new session starts, then the AI references that context in its questions

**Dependencies:** None (uses existing infrastructure)

**Technical Notes:**
- Extraction prompt: take client_brief + team_spec JSON, ask Haiku to extract structured fields matching the `accumulated_context` schema
- Run extraction as a background job after session completion
- Merge strategy: append new decisions to existing array, update tech_stack/audience if changed, keep open_threads

---

## Future (Post-Launch)

These are acknowledged but not chunked — they'll get their own spec sessions when the time comes:

- **SaaS billing** — Stripe integration, plan management, self-service signup (no invite needed), usage-based billing
- **White-label portal** — Custom domains per client (specs.clientname.com)
- **API access** — REST/GraphQL API for programmatic spec creation and retrieval
- **Template library** — Pre-built interview templates for common project types (landing page, e-commerce, mobile app)
- **AI model selection** — Let admins choose Claude vs GPT vs Gemini per session
- **Trello integration** — Like Linear, but for clients who prefer Trello

## Next Step

**Chunk 8: Microsoft Teams Integration** — follows the same channel adapter pattern as Slack (chunk 7). Teams bot via Azure Bot Framework, Adaptive Cards for structured questions, background jobs for orchestrator calls.

## Resolved Decisions

- **Client model:** Separate `Specs::Client` model, not a role on `User`. Auth logic shared via `Authenticatable` concern. Clients aren't shop team members — some won't have a Shopify store at all.
- **Top-level entity:** New `Organisation` model. Orgs own projects, integrations, and clients. Shops optionally belong to an org. Slack/Teams workspace = one org.
- **Project ownership:** All new specs auto-assign to the happypages owner. Team assignment deferred until there's a team.
- **Kanban depth:** Flat cards only, no sub-tasks. Each card has a checklist (from acceptance criteria) for granular tracking.
- **Billing cycle:** Per-org anniversary date, not calendar month.

## Open Questions (Resolved)

- ~~Should `Organisation` be the entity that `Specs::Project` belongs to (replacing `shop_id`), or should projects be linkable to either an org or a shop?~~ **Resolved:** Projects belong to shop XOR organisation (DB CHECK constraint enforces). Both paths work.
- ~~How does the org model interact with the existing `ShopFeature` gating?~~ **Resolved:** Feature gating stays on shop for Shopify clients. Org-scoped projects bypass shop feature checks (no shop context).

## Technical Notes

- The orchestrator is already channel-agnostic — it accepts text + optional image and returns structured tool calls. Channel adapters only need to handle input/output translation.
- Prompt caching (`cache_control: {type: "ephemeral"}`) on the static system prompt sections means Slack/Teams sessions won't cost more per-message than web sessions.
- The `accumulated_context` JSONB schema is already defined in PromptBuilder: `tech_stack`, `audience`, `constraints`, `decisions`, `open_threads`.
- Slack Block Kit and Teams Adaptive Cards are both JSON-based — a shared "rich message" intermediate format could reduce duplication.
- Linear's GraphQL API supports webhooks for issue state changes — cleaner than polling for status sync.
- Session limits should be checked at creation time, not message time — an active session should always be allowed to complete.
