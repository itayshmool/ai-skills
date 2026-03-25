---
name: ops-standup
description: Daily company standup — checks all departments, logs KPIs, identifies blockers, writes a briefing to the Ops dashboard
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__render__list_services, mcp__render__list_deploys, mcp__render__list_logs, mcp__render__get_metrics, mcp__render__query_render_postgres
argument-hint: "[--quick] [--dept <name>]"
---

# Ops Standup — Daily Company Briefing

Run a daily standup across all Zero2Claude departments. Collects KPIs, checks system health, identifies blockers, and writes a briefing to the company dashboard.

## Company Dashboard

- **Google Sheet ID:** `1ELcNNSQeSKcrwXBhV4dclBwPUwc6K9NiMpERabytZ7s`
- **Tabs:** KPIs, Tasks, Agent Log, Incidents
- **Dashboard URL:** https://docs.google.com/spreadsheets/d/1ELcNNSQeSKcrwXBhV4dclBwPUwc6K9NiMpERabytZ7s

## Workflow

### 0. Preflight Checks

Before collecting KPIs, verify required configuration:

```bash
# Check if STATS_API_KEY exists in .env
if ! grep -q "STATS_API_KEY=" .env; then
  echo "❌ ERROR: STATS_API_KEY missing from .env"
  echo "Get it from: Render Dashboard → terminal-trainer-api → Environment → STATS_API_KEY"
  echo "Or ask the user for it (it should have been provided previously)"
  exit 1
fi
```

If the key is missing, stop and request it from the user. Do not proceed with KPI collection.

### 1. Collect KPIs from Production

Query the production database via Render MCP tools and API probes:

```
Backend Service ID: srv-d6jbmbp4tr6s739ccvcg
Frontend Service ID: srv-d6kak0kr85hc739icnug
Database ID: dpg-d6jbi5fgi27c73d2jiv0-a
API Base: https://terminal-trainer-api.onrender.com
```

Collect these metrics:
- **Active Students** — users with progress in last 7 days (query via Render Postgres)
- **Lessons Completed (24h)** — progress records from last 24 hours
- **New Signups (24h)** — user accounts created in last 24 hours
- **Forum Posts (24h)** — new threads created
- **Forum Replies (24h)** — new replies created
- **Help Requests (24h)** — peer help requests
- **Errors (24h)** — error-level logs from Render (use `list_logs` with level=error)
- **Deploys (24h)** — count of deploys via `list_deploys`
- **API p95 (ms)** — response time from `get_metrics` with http_latency

### 2. Append KPIs to Dashboard

Use `appendSpreadsheetRows` to add a new row to the **KPIs** tab:
- Range: `KPIs!A1`
- Values: `[today's date, active students, lessons completed, new signups, forum posts, forum replies, help requests, errors, deploys, api p95, notes]`

### 3. Check Department Health

For each department, run a lightweight check:

| Department | Check |
|-----------|-------|
| **R&D** | Any failing tests? (`npm test` in project root) |
| **DevOps** | Service health (curl API /health), last deploy status |
| **Analytics** | GA4 tag count matches codebase events? (skip if slow) |
| **Marketing** | Landing page responding? (curl about.zero2claude.dev) |
| **Community** | Forum recent activity count, help request queue |
| **Revenue** | Skip (manual) |
| **Legal** | Skip (static pages) |

### 4. Check Open Tasks

Read the **Tasks** tab from the dashboard. Flag any tasks that are:
- Overdue (past due date + still open)
- Blocked (status = "Blocked")
- High priority + unassigned

### 5. Write Briefing

Output a standup briefing in this format:

```
## Daily Standup — [date]

### KPIs (24h)
| Metric | Today | Trend |
|--------|-------|-------|
| Active Students | 45 | — |
| Lessons Completed | 12 | ↑ |
| New Signups | 3 | — |
| Errors | 0 | ✓ |

### Department Status
- R&D: ✓ All tests passing
- DevOps: ✓ Last deploy succeeded (2h ago)
- Community: ⚠ 3 unanswered help requests
- Marketing: ✓ Landing page up

### Blockers
- None

### Action Items
Every action item MUST have an owner. Assign to the relevant department skill or "Itay" for manual tasks.

| # | Action | Owner | Dept |
|---|--------|-------|------|
| 1 | Review 3 unanswered help requests | /community-engage | Community |
```

### 6. Create GitHub Issues for Action Items

Every action item that surfaces a bug, incident, or work item MUST be filed as a GitHub issue.

**Repo:** `itayshmool/from-dev-basics-to-claude-code` (the main product repo)

```bash
gh issue create --repo itayshmool/from-dev-basics-to-claude-code \
  --title "[Ops Standup] <short title>" \
  --body "<full description with context, logs, links>" \
  --label "ops"
```

After creating the issue:
1. Note the issue number (e.g. `#325`)
2. Write a clickable HYPERLINK into the **Tasks** tab Notes column and **Incidents** tab Issue column.
   Use `valueInputOption: USER_ENTERED` and write a Google Sheets formula:
   ```
   =HYPERLINK("https://github.com/itayshmool/from-dev-basics-to-claude-code/issues/325", "#325")
   ```
3. Reference it in the standup briefing

Action items table format (updated):

| # | Action | Owner | Dept | Issue |
|---|--------|-------|------|-------|
| 1 | Fix forum 500 errors | /devops-incident | DevOps | #325 |

### 7. Log the Standup

Append a row to the **Agent Log** tab:
- Timestamp, "ops-standup", "Daily standup", "Completed — [summary]", duration, notes

## Arguments

- `--quick` — Skip department health checks, only collect KPIs and write to dashboard
- `--dept <name>` — Run standup for a single department only (e.g., `--dept devops`)
- `--lessons-learned <issue-numbers>` — Post-incident review: analyze fixed issues, identify prevention gaps, auto-improve skill instructions

---

## Lessons Learned Mode (`--lessons-learned`)

**Purpose:** After fixing production issues, conduct a post-incident review to strengthen development practices and prevent similar issues in the future.

**Usage:** `/ops-standup --lessons-learned 363,364,365`

### Workflow

#### 1. Fetch Issue Context

For each issue number provided:
- Fetch issue details from GitHub: `gh issue view <number> --json title,body,labels,closedAt,comments`
- Fetch related commits: `gh issue view <number> --json comments` and extract commit SHAs
- Read commit diffs: `git show <commit-sha>`
- Understand: What broke? How was it fixed?

#### 2. Root Cause Analysis

For each issue, identify:

**Technical Root Cause:**
- What code pattern caused the failure?
- What assumption was wrong?
- What edge case wasn't handled?

**Process Gap:**
- Which skill/workflow should have caught this?
  - `/qa` — Should code review have blocked this?
  - `/developer` — Should TDD have prevented this?
  - `/ops-standup` — Should monitoring have detected this sooner?
  - `/devops-incident` — Should deployment checks have caught this?

**Missing Guardrail:**
- What check/test/validation was absent?
- What documentation was unclear or missing?

#### 3. Map Issues to Skills

Create a mapping of which skills need improvements:

| Issue | Root Cause | Affected Skill(s) | Missing Guardrail |
|-------|-----------|-------------------|-------------------|
| #363 | Drizzle raw SQL binding | `/qa`, `/developer` | Drizzle query validation in QA checklist |
| #364 | Stale token in Socket.IO | `/qa`, `/developer` | Auth token lifecycle checks |
| #365 | Missing local env var | `/ops-standup` | Env validation in standup preflight |

#### 4. Generate Skill Improvements

For each affected skill, draft improvements to add to their SKILL.md:

**Format:**
```markdown
## Lessons Learned

### [Date] - [Issue Title]

**What happened:** Brief description of the incident

**Root cause:** Technical explanation

**New guardrail:**
- [ ] Specific check to add to this skill's workflow
- [ ] Validation rule to enforce
- [ ] Test pattern to follow

**Example:**
```

#### 5. Update Skill Instructions

For each skill identified in step 3:
- Read the skill's SKILL.md file (e.g., `~/.claude/skills/qa/SKILL.md`)
- Add a new entry to the "Lessons Learned" section (create if doesn't exist)
- Update relevant checklist sections with new guardrails
- Commit changes: `git commit -m "ops: lessons learned from #363 - add Drizzle query validation to QA"`

**Example for `/qa` skill:**
```markdown
### 2. API Routes
- [ ] Every new route is wrapped in `asyncHandler`
- [ ] Drizzle queries use type-safe operators (gt, eq, lt) instead of raw SQL templates  ← NEW
- [ ] All user-facing queries filter by `req.user!.userId`
```

#### 6. Create Lessons Learned Report

Generate a detailed report document:

**Location:** `specs/LESSONS_LEARNED_[YYYY-MM-DD].md`

**Template:**
```markdown
# Lessons Learned Report — [Date]

## Issues Analyzed
- #363: News & Releases 500 errors
- #364: Socket.IO WebSocket failures
- #365: STATS_API_KEY missing

## Executive Summary
[2-3 sentence summary of what went wrong and what we're doing about it]

## Detailed Analysis

### Issue #363: [Title]

**Timeline:**
- Deployed: [timestamp]
- First error: [timestamp]
- Detected: [timestamp]
- Fixed: [timestamp]
- Duration: [X hours]

**Impact:**
- Error count: 10 failures in 24h
- Affected users: All logged-in users
- Severity: High (user-facing 500 errors)

**Root Cause:**
[Technical explanation with code examples]

**Fix:**
[What we changed, with code diffs]

**Prevention:**
Skills updated:
- `/qa`: Added Drizzle query validation to API Routes checklist
- `/developer`: Added note about raw SQL template literal risks

New tests added:
- [List any new test patterns]

**Stakeholders:**
- R&D (fix implementation)
- DevOps (monitoring)
- Users (experienced errors)

---

## Skill Updates Applied

| Skill | Section | Change |
|-------|---------|--------|
| `/qa` | API Routes | Added Drizzle query validation guardrail |
| `/developer` | TDD | Added auth token lifecycle test pattern |
| `/ops-standup` | Preflight | Added local env validation check |

## Metrics

- Issues analyzed: 3
- Skills improved: 3
- New guardrails added: 5
- Estimated prevention rate: 80% (similar issues should be caught in code review)

## Action Items

- [ ] Team review of updated skill instructions
- [ ] Retrospective meeting with stakeholders (if high-severity)
- [ ] Update onboarding docs with new patterns
```

#### 7. Log to Dashboard

Append to the **Agent Log** tab:
```
Timestamp | Agent | Task | Status | Duration | Notes
2026-03-25 | ops-standup | Lessons learned | Completed | 15min | Analyzed #363,#364,#365. Updated 3 skills. Report: specs/LESSONS_LEARNED_2026-03-25.md
```

#### 8. Stakeholder Communication

If issues had high severity (production outage, data loss, security):
- Create a summary for stakeholders
- Recommend a retrospective meeting
- Document in Incidents tab on dashboard

### Important Notes

- **Run this AFTER fixing issues**, not during the incident
- **Be blame-free**: Focus on systems and processes, not individuals
- **Be specific**: "Add Drizzle query validation" not "be more careful"
- **Be actionable**: Every lesson learned should produce a concrete change to a skill or checklist
- **Commit skill changes**: Treat skill improvements like code — version control them
- **Test improvements**: Next time you run `/qa`, the new guardrail should catch similar issues

### Example Usage

```bash
# After fixing today's production issues:
/ops-standup --lessons-learned 363,364,365

# The skill will:
# 1. Analyze all 3 GitHub issues
# 2. Read commit diffs (fb50fd0, c546774)
# 3. Identify /qa and /ops-standup need improvements
# 4. Update ~/.claude/skills/qa/SKILL.md
# 5. Update ~/.claude/skills/ops-standup/SKILL.md
# 6. Create specs/LESSONS_LEARNED_2026-03-25.md
# 7. Log to CEO dashboard
```

## SQL Queries (for Render Postgres)

```sql
-- Active students (7 days)
SELECT COUNT(DISTINCT user_id) FROM progress WHERE updated_at > NOW() - INTERVAL '7 days';

-- Lessons completed (24h)
SELECT COUNT(*) FROM progress WHERE completed = true AND updated_at > NOW() - INTERVAL '1 day';

-- New signups (24h)
SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL '1 day';

-- Forum activity (24h)
SELECT COUNT(*) FROM forum_threads WHERE created_at > NOW() - INTERVAL '1 day';
SELECT COUNT(*) FROM forum_replies WHERE created_at > NOW() - INTERVAL '1 day';

-- Help requests (24h)
SELECT COUNT(*) FROM help_requests WHERE created_at > NOW() - INTERVAL '1 day';
```

## Important Notes

- The Render Postgres MCP tool runs read-only queries. Use `query_render_postgres` with the database ID.
- Render free tier: API may cold-start (30s). Retry once if first probe times out.
- KPI row should be appended, never overwritten. Each day gets its own row.
- If a department check fails, note it in the briefing but don't block the standup.
- Keep the briefing concise — this is a 2-minute read, not a report.
