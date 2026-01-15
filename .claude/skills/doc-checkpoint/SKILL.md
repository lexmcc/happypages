---
name: doc-checkpoint
description: End-of-session documentation checkpoint. Updates SPEC.md with completed features, adds new learnings to CLAUDE.md, and reviews if CLAUDE.md needs restructuring. Use when finishing a work session, after completing features, or when asked to "checkpoint", "sync docs", or "save progress".
---

# Documentation Checkpoint

Run this skill at the end of a working session to consolidate documentation.

## Step 1: Update SPEC.md

1. Read `SPEC.md` to understand current feature checklist
2. Review what was accomplished in this session (check git log, conversation context)
3. For each completed feature:
   - Mark checkbox as done: `- [ ]` → `- [x]`
   - Add to Version History with today's date
4. Add any new planned features to the "Planned Features" section
5. Update technical details if schemas or APIs changed

### Reorganize Completed Features

After marking features complete, reorganize the checklist:

1. **Move completed items out of "Planned Features":**
   - Items marked `[x]` in "Planned Features" should be moved to the appropriate section
   - Determine the best section based on the feature type (Admin UI, Analytics, etc.)
   - Remove from "Planned Features" after moving

2. **Keep "Planned Features" clean:**
   - This section should only contain `- [ ]` uncompleted items
   - Completed items staying here creates confusion about project status

3. **Example reorganization:**
   ```
   Before:
   ### Planned Features
   - [ ] Email notifications
   - [x] Shareable URLs  <-- completed, should move

   After:
   ### Referral Page (or appropriate section)
   - [x] Shareable URLs  <-- moved here

   ### Planned Features
   - [ ] Email notifications
   ```

## Step 2: Update CLAUDE.md

1. Read current `CLAUDE.md` and all referenced .md files
2. Identify new learnings from this session:
   - Gotchas or bugs encountered and their solutions
   - New patterns or best practices discovered
   - API quirks or undocumented behaviors
   - Configuration tips
3. Add learnings to the appropriate section or referenced file
4. Keep instructions concise - bullet points preferred

## Step 3: Review CLAUDE.md Size

1. Check if CLAUDE.md exceeds ~100 lines
2. If too large, identify sections that could be extracted:
   - Look for self-contained topics (e.g., deployment, testing, specific APIs)
   - Topics referenced infrequently are good extraction candidates
3. Propose extraction plan to user before executing
4. If extracting:
   - Create new `{Topic}.md` file with extracted content
   - Replace section in CLAUDE.md with a reference link
   - Follow existing pattern: `See [Topic.md](./Topic.md) for:`

## Output Format

After completing, summarize:
- Features marked complete in SPEC.md
- New learnings added to CLAUDE.md
- Any restructuring done or recommended

## Notes

- Don't remove historical information from Version History
- Preserve existing formatting and structure
- Ask before making large structural changes
