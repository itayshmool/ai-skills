---
name: ops-review
description: Weekly company review — analyzes KPI trends, department performance, and strategic priorities for Zero2Claude
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__google-drive__createGoogleDoc, mcp__render__list_services, mcp__render__list_deploys, mcp__render__list_logs, mcp__render__get_metrics, mcp__render__query_render_postgres
argument-hint: "[--period <days>] [--output doc]"
---

# Ops Review — Weekly Company Analysis

Deep weekly review of Zero2Claude operations. Analyzes KPI trends from the dashboard, reviews department performance, identifies patterns, and produces strategic recommendations.

## Company Dashboard

- **Google Sheet ID:** `1ELcNNSQeSKcrwXBhV4dclBwPUwc6K9NiMpERabytZ7s`
- **Tabs:** KPIs, Tasks, Agent Log, Incidents

## Workflow

### 1. Read KPI History

Fetch the last 7 rows from the **KPIs** tab using `getGoogleSheetContent`:
- Range: `KPIs!A1:K30` (grab enough rows to get the last week)

Calculate:
- **Trends** — direction for each metric (↑ growing, ↓ declining, → flat)
- **Averages** — 7-day average for each metric
- **Anomalies** — any day with >2 standard deviations from average

### 2. Review Completed Tasks

Read the **Tasks** tab. Summarize:
- Tasks completed this week
- Tasks still open
- New tasks added
- Blocked items and how long they've been blocked

### 3. Review Agent Activity

Read the **Agent Log** tab for the past 7 days. Summarize:
- How many times each agent ran
- Success/failure rates
- Total agent time spent
- Any recurring failures

### 4. Review Incidents

Read the **Incidents** tab. Summarize:
- Open incidents
- Incidents resolved this week
- Incident severity distribution
- Mean time to resolution

### 5. Department Deep Dive

For each department, analyze production data:

**R&D / Product:**
- Lesson completion rates by level (which levels are students stuck on?)
- Forum category activity (which topics get most engagement?)
- AI onboarding adoption rate

**DevOps:**
- Deploy frequency and success rate
- Error rates and patterns
- API latency trends (get_metrics with http_latency)
- Resource usage trends (CPU, memory)

**Community:**
- Forum growth (new threads, replies, active users)
- Help request queue (fulfilled vs abandoned)
- Feature request votes (top 5 by votes)

**Marketing:**
- New signups trend (growing or flat?)
- Landing page health

### 6. Produce Review Document

Format the review as:

```
# Zero2Claude Weekly Review — Week of [date]

## Executive Summary
[2-3 sentences: what happened, what matters, what to do]

## KPI Dashboard
| Metric | This Week (avg) | Last Week (avg) | Trend |
|--------|----------------|-----------------|-------|
| Active Students | 42 | 38 | ↑ +10% |
| ... | | | |

## Department Highlights
### R&D
- [key observation]
### DevOps
- [key observation]
### Community
- [key observation]

## Wins
1. [thing that went well]

## Concerns
1. [thing that needs attention]

## Recommended Actions
1. [Priority 1 — actionable item]
2. [Priority 2 — actionable item]
3. [Priority 3 — actionable item]

## Next Week Focus
[What the company should prioritize]
```

### 7. Log the Review

Append to the **Agent Log** tab:
- Timestamp, "ops-review", "Weekly review", result summary, duration

## Arguments

- `--period <days>` — Review period in days (default: 7)
- `--output doc` — Also create a Google Doc with the review (in addition to console output)

## SQL Queries

```sql
-- Completion rates by level
SELECT l.level_number, COUNT(CASE WHEN p.completed THEN 1 END)::float / NULLIF(COUNT(*), 0) as rate
FROM progress p JOIN lessons l ON p.lesson_id = l.id
WHERE p.updated_at > NOW() - INTERVAL '7 days'
GROUP BY l.level_number ORDER BY l.level_number;

-- Top feature requests by votes
SELECT ft.title, ft.id,
  (SELECT COUNT(*) FROM forum_votes fv WHERE fv.thread_id = ft.id AND fv.value = 1) as upvotes
FROM forum_threads ft
JOIN forum_categories fc ON ft.category_id = fc.id
WHERE fc.slug = 'feature-requests'
ORDER BY upvotes DESC LIMIT 5;

-- Signup trend (daily for last 7 days)
SELECT DATE(created_at) as day, COUNT(*) as signups
FROM users WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at) ORDER BY day;

-- AI onboarding adoption
SELECT COUNT(*) as total_plans FROM ai_onboarding_plans;
SELECT COUNT(*) as total_users FROM users;
```

## Important Notes

- This is a strategic document, not a status check. Focus on insights and recommendations, not just numbers.
- Compare to previous periods when data is available.
- Be honest about concerns — the review is for the founder, not investors.
- Keep recommendations actionable and prioritized.
- If dashboard data is sparse (early days), note this and work with what's available.
