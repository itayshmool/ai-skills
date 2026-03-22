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
2. Write it into the **Tasks** tab Notes column (e.g. `Issue #325`)
3. Write it into the **Incidents** tab Issue column if it's an incident
4. Reference it in the standup briefing

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
