---
name: ops-kpi
description: Manage the company KPI dashboard — add metrics, update tasks, log incidents, query trends
user-invocable: true
allowed-tools: Bash, Read, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__google-drive__getSpreadsheetInfo, mcp__render__query_render_postgres
argument-hint: "<command> [args]"
---

# Ops KPI — Dashboard Management

Direct interface to the Zero2Claude company dashboard. Add tasks, log incidents, query KPI trends, and manage the shared state that other Ops skills read from.

## Company Dashboard

- **Google Sheet ID:** `1ELcNNSQeSKcrwXBhV4dclBwPUwc6K9NiMpERabytZ7s`
- **Tabs:** KPIs, Tasks, Agent Log, Incidents
- **Database ID:** `dpg-d6jbi5fgi27c73d2jiv0-a`

## Commands

### `add-task`
Add a task to the Tasks tab.

**Usage:** `/ops-kpi add-task <department> "<task>" --owner <owner> [--priority high|medium|low] [--due <date>]`

`--owner` is **required**. Use a skill name (e.g. `/devops-status`, `/community-engage`) or `Itay` for manual tasks.

**Example:**
```
/ops-kpi add-task devops "Set up UptimeRobot for API endpoint" --owner Itay --priority high --due 2026-03-28
```

Append to **Tasks** tab:
- ID: Auto-increment (read last row, increment)
- Department, Task, Owner (**required**), Priority (default: medium), Status (default: Open), Due, Notes

### `add-incident`
Log an incident.

**Usage:** `/ops-kpi add-incident <severity> "<description>" [--owner <name>]`

Severity levels: `critical`, `high`, `medium`, `low`

**Example:**
```
/ops-kpi add-incident high "API returning 500 on /api/progress endpoint"
```

Append to **Incidents** tab:
- ID: Auto-increment
- Date: today
- Severity, Description, Owner (default: Itay), Status (default: Open), Resolution (empty)

### `resolve-incident`
Mark an incident as resolved.

**Usage:** `/ops-kpi resolve-incident <id> "<resolution>"`

Update the matching row in the **Incidents** tab:
- Status → Resolved
- Resolution → provided text

### `update-task`
Update a task's status.

**Usage:** `/ops-kpi update-task <id> <status> [--notes "<note>"]`

Status values: `Open`, `In Progress`, `Done`, `Blocked`

### `log`
Write an entry to the Agent Log.

**Usage:** `/ops-kpi log <agent-name> "<action>" "<result>" [--duration <time>]`

**Example:**
```
/ops-kpi log devops-deploy "Pre-deploy checklist" "All checks passed" --duration 45s
```

### `trend`
Query KPI trends from the dashboard.

**Usage:** `/ops-kpi trend [--metric <name>] [--days <n>]`

Read the KPIs tab and display:
- If `--metric` specified: show that metric over time with sparkline-style visualization
- If no metric: show all metrics for the last N days (default: 7)

Format output as a compact table with trend arrows.

### `status`
Show current dashboard overview — latest KPIs, open tasks, open incidents.

**Usage:** `/ops-kpi status`

Read all 4 tabs and present a compact summary:
```
## Company Dashboard — [date]

### Latest KPIs
Active Students: 42 | Lessons (24h): 8 | Signups (24h): 2 | Errors: 0

### Open Tasks (3)
- [HIGH] Set up UptimeRobot (DevOps) — due Mar 28
- [MED] Write blog post (Marketing) — due Apr 1
- [LOW] Add certificates (Community) — no due date

### Open Incidents (0)
All clear.

### Recent Agent Activity (24h)
- ops-standup ran at 09:00 — OK
- devops-status ran at 14:30 — Yellow (API p95 > 2s)
```

## Tab Schemas

### KPIs (A:K)
| Date | Active Students | Lessons Completed | New Signups | Forum Posts | Forum Replies | Help Requests | Errors (24h) | Deploys | API p95 (ms) | Notes |

### Tasks (A:H)
| ID | Department | Task | Owner | Priority | Status | Due | Notes |

### Agent Log (A:F)
| Timestamp | Agent | Action | Result | Duration | Notes |

### Incidents (A:G)
| ID | Date | Severity | Description | Owner | Status | Resolution |

## Important Notes

- Always read the current sheet data before appending/updating to get correct row positions and IDs.
- Task and Incident IDs are simple incrementing integers (read last row's ID, add 1).
- When updating rows, use `updateGoogleSheet` with the exact cell range (e.g., `Tasks!F3` for status of task in row 3).
- The dashboard is the shared state between all Ops skills. Keep it accurate.
- Use RAW value input option for most writes (data is stored as-is, no formula evaluation needed).
