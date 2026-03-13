# Journal — HappyPages Product

## 2026-03-05 21:15 | HappyPages Product | session | [wrap]
Continued n8n workflow setup. Imported and tested Trello workflow — switched from Trello node to HTTP Request node for multi-board support (3 boards), confirmed Field Doctor card activity captured. Imported and tested Granola EOD Safety Net workflow — discovered cache structure differences (start field is object not string, quick notes live in documents not events). Fixed event date parsing, added standalone document/quick note handling as separate path. Tested with quick note — Haiku misclassified "n8n testing" as prospect, cleaned up bogus entry and improved classification prompt with tooling/software examples and explicit rule. Simplified Granola workflow to 2 nodes (removed Read File node, reads directly with fs). All 3 n8n workflows (Gmail, Trello, Granola) ready to activate.

## 2026-03-05 17:40 | HappyPages Product | session | [wrap]
Implemented client status system (active/prospect/inactive/internal) across the ops stack. Extended project-client-map.json to object format with name+status. Updated 3 Python hooks (resolve_client dict extraction), 5 skills (map format + status grouping), 3 n8n workflows (client extraction + Haiku auto-classification). Created /prospect skill for add/convert/deactivate. Created Internal catch-all directory. Set up n8n with Gmail workflow — Haiku classifies unmatched emails as existing/prospect/ignore. Tested end-to-end: Rollr auto-created as prospect from email classification. Debugged n8n v2 sandbox issues (fs, https, fetch, process.env, binary write).

## 2026-03-04 22:08 | HappyPages Product | session | [precompact]
Recent commits: 58e1c35 Add specs for Shop#metafield_namespace, e198fcf Fix dynamic metafield namespace + add missing webhook metafield write, ff3dd25 Fix sidebar Dashboard staying highlighted on all admin pages

## 2026-03-06 18:11 | HappyPages Site | code | [commit]
Auto-focus first pill on ops dashboard load — 1 file changed

## 2026-03-07 08:02 | HappyPages Site | code | [commit]
Restyle superadmin to match ops dashboard density — 25 files changed

## 2026-03-07 08:06 | HappyPages Site | code | [commit]
Fix font class: font-[ops] → font-ops to use theme token — 2 files changed

## 2026-03-09 09:56 | HappyPages Site | code | [commit]
Update docs for weeks 12-13: performance dashboard, metafield namespace, superadmin reskin, ops dashboard — 5 files changed

## 2026-03-11 13:18 | HappyPages Site | code | [commit]
Fix discount creation failing on Shopify API 2025-10 — 1 file changed

## 2026-03-11 13:48 | HappyPages Site | code | [commit]
Fix discount context field: use enum string "ALL" not boolean true — 1 file changed

## 2026-03-11 14:00 | HappyPages App | session | [wrap]
Fixed Shopify discount creation: `context.all` requires enum string `"ALL"` not boolean `true` (API 2025-10 breaking change). Two fixes in `discount_provider.rb`. All 647 specs pass. Deployed to staging and production.

## 2026-03-12 15:32 | HappyPages Site | code | [commit]
Add new-customers-only setting for referral discounts — 6 files changed

## 2026-03-12 16:05 | HappyPages Site | code | [commit]
Restrict sidebar collapse to superadmin only — 3 files changed
