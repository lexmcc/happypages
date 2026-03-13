# Superadmin Impersonation & Services Workspace: UX Research Report

## 1. Reference Analysis

### Stripe: Support-Side Merchant Views

Stripe's internal support tooling (nicknamed "Stripe Mission Control") gives support agents a read-heavy view of any merchant's dashboard. Key patterns:

- **Context entry**: Support agents search by merchant ID, email, or payment ID. A single search box is the primary entry point -- no browsing a list.
- **Read-mostly session**: Agents see the merchant's data (charges, subscriptions, disputes, Radar rules) but cannot modify billing or authentication settings. Actions are limited to what a Support Specialist role allows: view data, refund charges, but not edit settings or modify rules.
- **Role-based scoping**: Stripe defines distinct roles (Administrator, Developer, Analyst, Support Specialist, View only, Support Center). The Support Specialist role is explicitly designed for "looking at a merchant's data to help them" without giving mutation access.
- **Visual differentiation**: Internal tools use a distinct chrome/color scheme so agents never confuse their internal view with a merchant-facing one.
- **Audit trail**: All support actions are logged with agent identity, timestamp, merchant context, and action type.

**Takeaway for Happypages**: Search-first entry into shop context (not just clicking from a list). Read-heavy default with explicit opt-in for mutations. Visual differentiation between "I'm browsing as Happypages team" and "I'm seeing what the merchant sees."

### Shopify Partners: Collaborator Access

Shopify's approach is *not* impersonation -- it's a separate collaborator account with scoped permissions:

- **Request flow**: Partner sends a collaborator request through Partner Dashboard. Merchant has a 4-digit collaborator code as an extra verification layer.
- **Scoped access**: Collaborators access only the sections the merchant grants. They cannot access bank account details, Shopify Payments settings, or the full Administrator role.
- **Doesn't count against staff limit**: Collaborator accounts are separate from the merchant's staff quota.
- **Expiration**: Access expires after 90 days of inactivity -- automatic cleanup.
- **Two-factor required**: All collaborators must have 2FA enabled.
- **Visible identity**: The collaborator appears in the store's staff list with their own identity visible, not as a ghost.

**Takeaway for Happypages**: Shopify's model is better for *third-party* access than *first-party* support. But the scoped permissions concept and the visible-identity principle are valuable. When impersonating, the shop owner should be able to see that it happened (audit log), even if they weren't online at the time.

### Linear: Lightweight Issue Tracking

Linear's success comes from three design decisions that matter for Happypages:

- **Keyboard-first, speed-obsessed**: Nearly every action works without a mouse. `C` creates an issue, `S` sets status, `P` sets priority. Updates sync in milliseconds. The entire app feels instant.
- **Opinionated workflow**: Three building blocks: Issues, Projects, Cycles. No customizable fields, no complex workflows. Status is a simple pipeline: Backlog -> Todo -> In Progress -> Done -> Cancelled. Priority is Urgent/High/Medium/Low/None.
- **Minimal friction to create**: Creating an issue takes 2 seconds. Title + optional description. Everything else (assignee, priority, label, project) can be added later or in-line. The creation modal has a keyboard-navigable command palette.
- **Triage inbox**: New issues land in a triage queue. Team leads review and assign. This separates "report a problem" from "decide what to work on."
- **Views, not boards**: Linear defaults to list view, not Kanban boards. Filters and grouping are powerful but not in your face. Board view exists but isn't the default.

**Takeaway for Happypages**: Keep the issue model dead simple. Title + description + status + priority. No custom fields. The shop owner should be able to create an issue in under 5 seconds. The Happypages team should see issues across all shops in a unified triage view.

### Intercom / Crisp: Embedded Messaging

Both platforms pioneer the concept of messaging embedded within the product itself:

- **Persistent launcher**: A small chat icon in the bottom-right corner. Always visible. One click to open.
- **Threaded conversations**: Messages are conversational, not tickets. No ticket numbers visible to the customer. Internally, each conversation is tracked, but the customer sees "messages" not "cases."
- **Rich context**: When a support agent views a conversation, they see the customer's metadata (plan, last active, previous conversations) in a side panel. The conversation is contextualized without asking the customer to repeat themselves.
- **Proactive messages**: Support can push messages to users based on behavior (e.g., "Noticed you haven't set up your referral page yet -- need help?").
- **Status without status**: Conversations are "open" or "closed" from the agent side, but the customer just sees a message thread. No "your ticket is pending" language.

**Takeaway for Happypages**: Messages between the Happypages team and shop owner should feel like chat, not tickets. The Happypages team sees metadata and context; the shop owner sees a clean conversation. But for *services work* (tasks with deadlines and deliverables), pure chat isn't enough -- you need structured issues alongside unstructured messaging.

### HubSpot: Managed Services + Self-Serve

HubSpot's customer portal model combines self-service with agent collaboration:

- **Customer portal**: Authenticated portal where clients can see their open tickets, track status, and access a knowledge base. One place for everything.
- **Shared visibility**: Both the client and the support team see the same ticket status. No information asymmetry.
- **Self-service first**: 67% reduction in support calls when clients can check status and find answers themselves.
- **Branded experience**: Portal applies the company's brand (colors, logo, fonts) automatically. It doesn't feel like a third-party tool bolted on.

**Takeaway for Happypages**: The services workspace should be branded as part of Happypages, not feel like a separate tool. Both the shop owner and Happypages team should see the same status/progress.

### Railway: Team/Project Switching

Railway's workspace model is relevant for the superadmin "context switch" between shops:

- **Workspace switcher**: Dropdown in the top-left. Switch between personal, team workspaces in one click.
- **Project-level context**: Within a workspace, each project has its own services, databases, and settings. Click a project card to enter that context.
- **Breadcrumb navigation**: `Workspace > Project > Service` breadcrumb keeps you oriented.
- **Transfer between workspaces**: Projects can be moved between workspaces. Analogous to how a superadmin might need to "move" a shop's configuration.

**Takeaway for Happypages**: Use a workspace/context switcher pattern for superadmin navigating between shops. Breadcrumb-style orientation so the admin always knows "which shop am I looking at."

### Zendesk / Help Scout: Embedded Support

- **Help Scout's no-ticket-number philosophy**: Customers never see ticket numbers. Conversations look like normal email exchanges. Internally, everything is tracked and organized, but the external-facing layer is clean.
- **Embedded knowledge base**: Before creating a ticket, users can search a KB. Reduces noise.
- **Conversation-centric**: Both platforms treat support as ongoing conversations rather than one-off tickets.

**Takeaway for Happypages**: Avoid exposing internal tracking complexity to shop owners. They should see "your requests" not "ticket #4829."

---

## 2. Impersonation UX Proposal

### How Superadmin Enters Impersonation

Three entry points, all converging on the same session mechanism:

1. **From shop list (primary)**: On the superadmin shop list (`/superadmin`), each shop row gets an "Enter shop" button. One click starts impersonation.

2. **From shop detail**: On the superadmin shop detail page (`/superadmin/shops/:id`), an "Enter as shop owner" button in the header. Useful when you've been reviewing a shop's data and want to switch to their view.

3. **Quick-switch command**: A keyboard shortcut (`Cmd+K` or `/`) opens a command palette with shop search. Type a shop name, hit enter, impersonation starts. This is for speed -- the Stripe "search by ID" pattern.

### Session Mechanics

```
Session state during impersonation:
  session[:super_admin]           = true        (preserved)
  session[:super_admin_email]     = "alex@..."  (preserved)
  session[:impersonating_shop_id] = 42          (new)
  session[:impersonating_since]   = Time.current (new)
```

The `Admin::BaseController` needs a new concern, `Impersonatable`, that:
- Checks for `session[:impersonating_shop_id]`
- If present, sets `Current.shop` from that shop ID instead of from `current_user.shop`
- Makes `impersonating?` and `impersonating_shop` helpers available to views
- Skips the `require_login` check when impersonating (superadmin auth is sufficient)
- Sets `current_user` to nil (or a synthetic read-only user) during impersonation

### Banner Design

```
+--------------------------------------------------------------------------+
|  [HP logo]  Viewing "Oatcult" as shop owner                             |
|             [Switch shop v]    [Open superadmin]    [Exit impersonation] |
+--------------------------------------------------------------------------+
|  [normal admin sidebar]          [normal admin content]                  |
```

The impersonation banner:
- **Position**: Fixed top bar, above the admin layout. 40px tall. Uses the superadmin slate color scheme (dark bg, white text) to visually distinguish from the shop admin's cream/coral palette.
- **Content**: Shop name prominently displayed. "Viewing as shop owner" text.
- **Actions**:
  - **Switch shop**: Dropdown or command palette to jump directly to another shop without returning to superadmin.
  - **Open superadmin**: Opens `/superadmin` in a new tab (preserves impersonation in current tab).
  - **Exit impersonation**: Returns to `/superadmin/shops/:id` for the currently viewed shop. Single click.
- **Sticky**: The banner stays visible during scroll. It should never be hidden or dismissible.
- **Mobile**: Collapses to a single row: `[icon] Oatcult [exit button]`. "Switch shop" moves to a hamburger or is omitted on mobile.

### Permissions During Impersonation

**Full access (same as shop owner):**
- View dashboard, analytics, campaigns, media, referral page, thank-you card, integrations, settings
- Edit referral page, thank-you card, campaign configurations
- Upload media
- View customer imports

**Restricted (superadmin-only confirmation required):**
- Activate/deactivate campaigns (shows "Are you sure? You're impersonating." dialog)
- Trigger brand re-scrape or image generation
- Change shop settings (slug, storefront URL)

**Blocked during impersonation:**
- Delete the shop
- Change authentication (passwords, OAuth connections)
- Trigger customer data deletion (compliance actions)
- Anything that would send customer-facing emails

**Audit trail:**
Every action during impersonation is logged with `actor: "super_admin_impersonating"` and includes both the superadmin email and the impersonated shop ID.

### Time Limits

- Impersonation sessions last up to 4 hours (longer than the 2-hour superadmin timeout because services work can be extended)
- 10-minute warning before expiration, with "Extend 4 hours" button
- All impersonation sessions are logged with start time, end time, and actions taken

---

## 3. Superadmin Home Proposal

### What Stays as Dedicated Superadmin Views

| View | Reason |
|------|--------|
| **Shop list** (`/superadmin`) | Cross-shop overview. Entry point for impersonation. Shows all shops with status, referral counts, last active. |
| **Create / invite shop** | Onboarding new merchants is a platform-level action, not a shop-level one. |
| **Global metrics** | Aggregate numbers across all shops (total referrals, total orders attributed, active shops, MRR). Quick health check. |
| **Prompt templates** (`/superadmin/prompt_templates`) | AI prompt management is platform infrastructure, not shop-specific. |
| **Scene assets** (`/superadmin/scene_assets`) | Same -- shared asset library for image generation. |
| **Audit log** (new) | Cross-shop audit trail. Filterable by shop, actor, action type, date range. |
| **Services triage** (new) | Cross-shop issue queue. See all open issues across all shops, grouped by priority. This is the "Linear triage inbox" for the Happypages team. |

### What Gets Replaced by Impersonation

| Current Superadmin View | Replacement |
|-------------------------|-------------|
| **Shop detail** (`/superadmin/shops/:id` -- referrals tab, campaigns tab, analytics tab, credentials tab, brand/AI tab) | Impersonate the shop and use their dashboard/analytics/campaigns views directly. The current shop detail duplicates what the shop owner sees, but worse. |
| **Web analytics** (`/superadmin/web_analytics`) | Impersonate the shop and view their analytics dashboard. The superadmin site-picker dropdown is unnecessary when you can just switch shops via impersonation. |

### Shop List Redesign

The current shop list is a plain table. Proposed upgrade:

```
+---------------------------------------------------------------------+
| Shops                                            [+ Invite shop]    |
| [Search shops...]                                                   |
|                                                                     |
| [All: 12]  [Active: 10]  [Needs attention: 2]  [Suspended: 0]     |
|                                                                     |
| +---------------------------------------------------------------+  |
| | Oatcult                           Active     12 referrals      |  |
| | oatcult.myshopify.com             Since Jan 15    [Enter -->]  |  |
| +---------------------------------------------------------------+  |
| | Brewdog Merch                     Active     8 referrals       |  |
| | brewdog-merch.myshopify.com       Since Feb 2     [Enter -->]  |  |
| +---------------------------------------------------------------+  |
| | Demo Store                        Needs attention              |  |
| | happypages-test-store...          3 open issues   [Enter -->]  |  |
| +---------------------------------------------------------------+  |
```

Key changes:
- **Search** at the top (Stripe pattern)
- **"Needs attention"** filter: shops with open services issues, failed image generations, suspended status, or stale analytics
- **"Enter" button** on each row: starts impersonation
- **Issue count** shown inline (when services workspace exists)
- Clicking the shop name goes to a lightweight superadmin overview (not the old 4-tab detail page). Clicking "Enter" starts impersonation.

---

## 4. Services Workspace Proposal

### Model: Issues + Messages, Not Tickets

The services workspace has two primitives:

1. **Issue**: A discrete piece of work with a title, status, and optional due date. Think "Redesign homepage hero section" or "Fix checkout discount stacking bug." Issues have a status pipeline (Open -> In Progress -> Done) and a priority (Urgent, High, Normal, Low).

2. **Message**: A timestamped text message within an issue thread, or in a general conversation channel. Messages are the communication layer. They can include file attachments and @mentions.

These two primitives create three views:

### Shop Owner View (inside `/admin`)

A new "Services" item in the admin sidebar, between Analytics and the Customize section.

**Services landing page** (`/admin/services`):

```
+---------------------------------------------------------------------+
| Services                                         [+ New request]    |
|                                                                     |
| Open (3)                                                            |
| +---------------------------------------------------------------+  |
| | [!] Homepage redesign                              In Progress |  |
| |     Updated 2h ago                                 Due Mar 15  |  |
| +---------------------------------------------------------------+  |
| | [ ] Add Klaviyo integration                        Open        |  |
| |     Updated 1d ago                                             |  |
| +---------------------------------------------------------------+  |
| | [ ] Fix mobile cart overlay                        Open        |  |
| |     Created 3d ago                                 High        |  |
| +---------------------------------------------------------------+  |
|                                                                     |
| Completed (8)                                          [Show all]  |
| +---------------------------------------------------------------+  |
| | [v] Update brand colors across theme               Done       |  |
| |     Completed Feb 18                                           |  |
| +---------------------------------------------------------------+  |
|                                                                     |
| Messages                                                            |
| +---------------------------------------------------------------+  |
| | Alex (Happypages)  2h ago                                      |  |
| | "Homepage hero mockup is ready for review -- see the           |  |
| |  attached Figma link. Let me know if the layout works."        |  |
| +---------------------------------------------------------------+  |
| | You  3h ago                                                    |  |
| | "Can we make the hero image wider on desktop?"                 |  |
| +---------------------------------------------------------------+  |
| [Type a message...]                                   [Send]       |  |
+---------------------------------------------------------------------+
```

Design principles:
- **Issues at top, messages below**: Issues are the "what," messages are the "how." Shop owners see progress on their work items, then can scroll down to the ongoing conversation.
- **"New request" button**: Opens a minimal form -- just title and optional description. The Happypages team triages priority and assignments.
- **No ticket numbers visible**: Issues show titles, not IDs. Internally they have IDs for routing.
- **Conversation is continuous**: Messages aren't tied to specific issues (though they can reference them). This is the "general channel" for services communication with the shop.
- **Issue detail view**: Clicking an issue opens a detail page with the issue's own message thread (scoped discussion about that specific issue), status history, and any attachments.

### Superadmin View (via Impersonation)

When a superadmin impersonates a shop, the Services tab shows the same view as the shop owner, plus:

- **Assign to team member**: Dropdown to assign issues to Happypages team members (future: when there are multiple team members)
- **Change priority**: Can set priority levels
- **Internal notes**: Messages marked as "internal" are visible only to the Happypages team, not the shop owner. Visually differentiated with a subtle background color and "[internal]" badge.
- **Status changes**: Can move issues through the pipeline (Open -> In Progress -> Done)

### Cross-Shop Triage View (Superadmin Home)

A dedicated view in superadmin (`/superadmin/services`) for managing services work across all shops:

```
+---------------------------------------------------------------------+
| Services Triage                                    [Filters v]      |
|                                                                     |
| Needs triage (2)                                                    |
| +---------------------------------------------------------------+  |
| | Oatcult: "Fix mobile cart overlay"                 New         |  |
| |     Created 3d ago by shop owner                   [Assign]    |  |
| +---------------------------------------------------------------+  |
| | Demo Store: "Add discount timer"                   New         |  |
| |     Created 1d ago by shop owner                   [Assign]    |  |
| +---------------------------------------------------------------+  |
|                                                                     |
| In Progress (4)                                                     |
| +---------------------------------------------------------------+  |
| | Oatcult: "Homepage redesign"                       In Progress |  |
| |     Assigned to Alex          Due Mar 15           [Enter -->] |  |
| +---------------------------------------------------------------+  |
| | Brewdog: "Checkout flow optimization"              In Progress |  |
| |     Assigned to Alex          Due Mar 20           [Enter -->] |  |
| +---------------------------------------------------------------+  |
```

- **Grouped by status**: Triage -> In Progress -> Blocked -> Done (this week)
- **"Enter" button**: Starts impersonation and navigates directly to that issue in the shop's Services tab
- **Filterable**: By shop, assignee, priority, due date
- **Keyboard navigation**: `j/k` to move through issues, `Enter` to open, `a` to assign

### Notification Patterns

**Shop owner receives:**
- Email when an issue status changes (Open -> In Progress, In Progress -> Done)
- In-app badge on the Services nav item when there are new messages
- No email for every message (too noisy). Only status changes and @mentions.

**Happypages team receives:**
- Email digest (daily) of new issues across all shops
- Real-time notification when a shop owner sends a message (via whatever internal channel the team uses -- Slack webhook, email, etc.)
- In-app notification in the superadmin triage view

---

## 5. Integration with Navigation

### Shop Owner Sidebar (Updated)

```
[HP logo] Happypages
--------------------------
  Dashboard
  Campaigns
  Analytics
----- Customize ----------
  Thank-You Card
  Referral Page
  Media
----- Connect ------------
  Integrations
  Settings
----- Services ----------- (NEW SECTION)
  Services (3)            <-- badge shows open issue count
--------------------------
[shop domain]
[Logout]
```

The Services section sits at the bottom of the main nav, above the logout area. It's separated by its own section header because it represents a different mode of interaction (collaboration with the Happypages team) rather than self-serve configuration.

The badge count shows open issues only. Once all issues are Done, the badge disappears.

### Superadmin Sidebar (Updated)

```
[HP logo] Happypages [SUPER]
--------------------------
  Shops
  Services Triage (5)     <-- NEW: cross-shop issue queue
----- AI Imagery ----------
  Scene Assets
  Prompt Templates
----- System ------------- (NEW SECTION)
  Audit Log               <-- NEW: cross-shop audit trail
--------------------------
[admin email]
[Logout]
```

Key changes:
- **Web Analytics removed**: Replaced by impersonation. View any shop's analytics by entering their view.
- **Services Triage added**: Cross-shop issue management.
- **Audit Log added**: Cross-shop audit trail (currently only visible in shop detail, which is being replaced).
- **Shop detail page simplified**: Becomes a lightweight overview (status, key metrics, quick actions) rather than the current 4-tab detail view. The detail view's content is accessible via impersonation.

---

## 6. Text-Based Wireframes

### Impersonation Banner

```
+---------------------------------------------------------------------------+
|  [o] Viewing "Oatcult" as shop owner    [Switch shop v]  [SA]  [x Exit]  |
+---------------------------------------------------------------------------+

Mobile:
+-----------------------------------------------+
|  [o] Oatcult                        [x Exit]  |
+-----------------------------------------------+

Legend:
  [o]  = Happypages icon (8px, rounded)
  [SA] = "Open Superadmin" button (opens /superadmin in new tab)
  [x]  = Exit impersonation

Styling:
  Background: slate-800 (#1e293b)
  Text: white
  Height: 40px
  Position: fixed top, z-index 60 (above sidebar)
  Font: Inter 13px medium
```

### Superadmin Home / Shop List

```
+---------------------------------------------------------------------------+
|  [sidebar]  |  Shops                              [+ Invite shop]         |
|             |                                                             |
|  Shops      |  [Search shops...                                     Q]   |
|  Services(5)|                                                             |
|  ----       |  [All: 12] [Active: 10] [Attention: 2] [Suspended: 0]     |
|  Scene      |                                                             |
|  Prompts    |  +-------------------------------------------------------+ |
|  ----       |  | [logo] Oatcult                                         | |
|  Audit Log  |  | oatcult.myshopify.com   Active   12 refs   [Enter ->] | |
|             |  +-------------------------------------------------------+ |
|             |  | [logo] Brewdog Merch                                   | |
|  alex@hp.co |  | brewdog.myshopify.com   Active    8 refs   [Enter ->] | |
|  [Logout]   |  +-------------------------------------------------------+ |
|             |  | [!] Demo Store                    Needs attention      | |
|             |  | demo.myshopify.com      3 issues open     [Enter ->]  | |
|             |  +-------------------------------------------------------+ |
+---------------------------------------------------------------------------+

"Needs attention" criteria:
  - Has open services issues older than 48h
  - Brand scrape or image generation failed
  - Status is suspended
  - Analytics site has no data for 7+ days
```

### Services Workspace (Shop Owner View)

```
+---------------------------------------------------------------------------+
|  [sidebar]  |  Services                            [+ New request]        |
|             |                                                             |
|  Dashboard  |  Open (3)                                                   |
|  Campaigns  |  +-------------------------------------------------------+ |
|  Analytics  |  | [!] Homepage redesign                      In Progress | |
|  ----       |  |     Updated 2h ago by Alex (HP)            Due Mar 15  | |
|  TY Card    |  +-------------------------------------------------------+ |
|  Ref Page   |  | [ ] Add Klaviyo integration                Open        | |
|  Media      |  |     Updated 1d ago                                     | |
|  ----       |  +-------------------------------------------------------+ |
|  Integ.     |  | [ ] Fix mobile cart overlay                Open        | |
|  Settings   |  |     Created 3d ago                         High        | |
|  ----       |  +-------------------------------------------------------+ |
|  Svc (3)    |                                                             |
|             |  Completed (8)                                 [Show all]  |
|             |  +-------------------------------------------------------+ |
|             |  | [v] Update brand colors                    Done        | |
|             |  |     Completed Feb 18                                   | |
|             |  +-------------------------------------------------------+ |
|             |                                                             |
|             |  --- Messages -------------------------------------------  |
|             |                                                             |
|             |  Alex (Happypages)                           2h ago        |
|             |  Homepage hero mockup ready for review.                    |
|             |  See attached Figma link.                                   |
|             |                                                             |
|             |  You                                         3h ago        |
|             |  Can we make the hero wider on desktop?                     |
|             |                                                             |
|             |  +-------------------------------------------------------+ |
|             |  | Type a message...                          [Send ->]  | |
|             |  +-------------------------------------------------------+ |
+---------------------------------------------------------------------------+
```

### Services Workspace (Superadmin / Impersonated View)

```
+---------------------------------------------------------------------------+
| [o] Viewing "Oatcult" as shop owner    [Switch shop v]  [SA]  [x Exit]   |
+---------------------------------------------------------------------------+
|  [sidebar]  |  Services                            [+ New request]        |
|             |                                                             |
|  Dashboard  |  Open (3)                                                   |
|  Campaigns  |  +-------------------------------------------------------+ |
|  Analytics  |  | [!] Homepage redesign                      In Progress | |
|  ----       |  |     Assigned: Alex    Priority: High       Due Mar 15  | |
|  TY Card    |  |     [Change status v]  [Reassign v]  [Set due date]   | |
|  Ref Page   |  +-------------------------------------------------------+ |
|  Media      |  | [ ] Add Klaviyo integration                Open        | |
|  ----       |  |     Unassigned         Priority: Normal                | |
|  Integ.     |  |     [Change status v]  [Assign v]    [Set priority v] | |
|  Settings   |  +-------------------------------------------------------+ |
|  ----       |                                                             |
|  Svc (3)    |  --- Messages -------------------------------------------  |
|             |                                                             |
|             |  Alex (Happypages)                           2h ago        |
|             |  Homepage hero mockup ready for review.                    |
|             |                                                             |
|             |  [Internal note] Alex                        1h ago        |
|             |  Client seems happy with direction. Ship by EOW.           |
|             |  (only visible to Happypages team)                         |
|             |                                                             |
|             |  +-------------------------------------------------------+ |
|             |  | Type a message...      [Internal] [Attach]  [Send ->] | |
|             |  +-------------------------------------------------------+ |
+---------------------------------------------------------------------------+

Differences from shop owner view:
  - Impersonation banner at top
  - Issue management controls (assign, priority, status, due date)
  - Internal notes with distinct styling (light yellow bg, "[Internal]" badge)
  - "Internal" toggle on message compose
```

### Issue Detail View

```
+---------------------------------------------------------------------------+
| [<- Back to Services]                                                     |
|                                                                           |
| Homepage redesign                                          In Progress    |
| Created Feb 10 by shop owner                              Due Mar 15     |
|                                                                           |
| Description:                                                              |
| We want to refresh the homepage hero section with new                     |
| product photography and a clearer value proposition.                      |
| The current hero feels dated.                                             |
|                                                                           |
| Assigned: Alex (Happypages)    Priority: High                             |
|                                                                           |
| --- Activity -------------------------------------------------------     |
|                                                                           |
| [status] Alex changed status to In Progress              Feb 12          |
|                                                                           |
| Alex (Happypages)                                        Feb 12          |
| Starting on the hero mockups. Will share Figma by EOD.                    |
|                                                                           |
| You                                                      Feb 13          |
| Sounds great! Can we explore a wider layout?                              |
|                                                                           |
| Alex (Happypages)                                        Feb 14          |
| Here's the updated mockup with wider hero:                                |
| [figma-link-thumbnail]                                                    |
|                                                                           |
| [status] Alex set due date to Mar 15                     Feb 14          |
|                                                                           |
| +-------------------------------------------------------+                |
| | Type a message...                          [Send ->]  |                |
| +-------------------------------------------------------+                |
+---------------------------------------------------------------------------+

Activity feed interleaves:
  - Messages (from either party)
  - Status changes
  - Assignment changes
  - File attachments
All in chronological order.
```

### Services Triage (Superadmin)

```
+---------------------------------------------------------------------------+
|  [sidebar]  |  Services Triage                     [Filters v]            |
|             |                                                             |
|  Shops      |  Needs Triage (2)                                           |
|  Svc (5)    |  +-------------------------------------------------------+ |
|  ----       |  | Oatcult                                                | |
|  Scene      |  | "Fix mobile cart overlay"          New    3d ago       | |
|  Prompts    |  |                                    [Assign v] [Enter]  | |
|  ----       |  +-------------------------------------------------------+ |
|  Audit      |  | Demo Store                                             | |
|             |  | "Add discount timer"               New    1d ago       | |
|             |  |                                    [Assign v] [Enter]  | |
|             |  +-------------------------------------------------------+ |
|             |                                                             |
|             |  In Progress (3)                                            |
|             |  +-------------------------------------------------------+ |
|             |  | Oatcult                                                | |
|             |  | "Homepage redesign"   Alex   High  Due Mar 15 [Enter] | |
|             |  +-------------------------------------------------------+ |
|             |  | Brewdog                                                | |
|             |  | "Checkout optimization" Alex Normal Due Mar 20 [Enter]| |
|             |  +-------------------------------------------------------+ |
|             |                                                             |
|             |  Done This Week (2)                          [Show all]    |
|             |  +-------------------------------------------------------+ |
|             |  | Oatcult: "Update brand colors"     Done   Feb 18      | |
|             |  +-------------------------------------------------------+ |
+---------------------------------------------------------------------------+

"Enter" button starts impersonation and navigates to that issue's detail view
within the shop's admin.
```

---

## 7. Recommendation

### The Architecture I Would Pick

**Impersonation as the primary tool, not a secondary one.**

The current superadmin is trying to be two things: a shop management dashboard and a view into individual shop data. It does both poorly. The shop detail page duplicates the shop owner's views but with less context and worse UX. The web analytics page is literally the same dashboard with a shop picker bolted on.

The fix is simple: stop building parallel views. Build impersonation, then delete most of the superadmin-specific views.

**What remains in superadmin:**
1. Shop list with search, status filters, and "Enter" buttons (entry to impersonation)
2. Services triage queue (cross-shop issue management)
3. AI infrastructure (prompt templates, scene assets)
4. Audit log (cross-shop compliance trail)
5. Global metrics card at top of shop list (total shops, total referrals, MRR)

**What gets replaced by impersonation:**
1. Shop detail page (all 4-5 tabs)
2. Web analytics page
3. Any future per-shop views

**Services workspace as a first-class product feature, not an afterthought.**

The services workspace should live inside the shop admin (`/admin/services`), visible to both shop owners and impersonating superadmins. It's not a separate tool or a third-party embed. It's part of the Happypages product.

The data model is minimal:
- `ServiceIssue`: title, description, status (open/in_progress/done/cancelled), priority (urgent/high/normal/low), due_date, shop_id, assignee (text or user_id), created_by_type (shop_owner/happypages_team)
- `ServiceMessage`: body, issue_id (nullable for general messages), shop_id, author_type (shop_owner/happypages_team), internal (boolean, default false), attachment (Active Storage)

The superadmin triage view queries `ServiceIssue` across all shops. No separate data model needed.

**Implementation order:**

1. **Impersonation mechanism** (session-based, concern in Admin::BaseController) + banner
2. **Replace shop detail + web analytics** with impersonation entry points
3. **Services models + shop owner view** (`/admin/services`)
4. **Services management in impersonation** (assign, prioritize, internal notes)
5. **Services triage in superadmin** (`/superadmin/services`)
6. **Notifications** (email on status change, in-app badge)
7. **Command palette** for quick shop switching during impersonation

This order lets you ship impersonation independently (immediate value: stop maintaining duplicate views) and layer services on top.

### Why This Beats the Alternatives

- **Not building a separate "services portal"**: The workspace lives inside the product the shop owner already uses. No new URL, no new login, no context switch.
- **Not using a third-party tool**: Intercom/Crisp/Zendesk would add another login, another UI, and would feel disconnected from the shop's admin. Embedding a third-party widget is possible but creates a jarring UX seam.
- **Not overcomplicating the issue model**: No custom fields, no workflows, no sprints, no story points. Title + description + status + priority + due date. If you need more, you're doing project management, not services management. Use Linear for that internally and keep the client-facing layer simple.
- **Impersonation over parallel views**: Every parallel view is a maintenance burden and a divergence risk. When you add a new feature to the shop admin, you'd have to add it to superadmin too. Impersonation means the superadmin always sees exactly what the shop owner sees.

### One Opinion on What Makes This Feel Right

The difference between "admin tool" and "product" is whether the shop owner feels like they're being managed or being served. The services workspace should feel like the shop owner has a dedicated team working for them -- not like they're filing tickets into a queue. Messages should feel like chatting with a colleague. Issue status should feel like transparency, not process.

The impersonation banner should feel confident, not apologetic. "Viewing Oatcult as shop owner" -- direct, clear, no jargon. The exit button is always visible because the superadmin should never feel trapped.

Linear works because it respects your time. The services workspace should work the same way: fast to create an issue, fast to see status, fast to communicate. Every click that could be eliminated should be.
