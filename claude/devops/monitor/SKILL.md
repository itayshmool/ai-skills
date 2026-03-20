---
name: monitor
description: Monitor Zero2Claude production health — traffic, errors, deploys, resource usage
user-invocable: true
---

# Production Monitor

## Overview

Runs a comprehensive health check on the Zero2Claude production stack on Render: frontend static site, backend API, and PostgreSQL database. Reports service status, recent deploys, HTTP traffic, error rates, resource usage, and recent error logs.

## Service IDs

| Service | Type | ID |
|---------|------|-----|
| Frontend | Static Site | `srv-d6kak0kr85hc739icnug` |
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |

## Instructions for Claude

When the user invokes `/monitor`, run ALL of the following checks in parallel where possible, then present a unified health report.

### Step 1: Gather Data (run in parallel)

Use the Render MCP tools to fetch all data. Make these calls in parallel since they are independent:

1. **Service status** — Call `get_service` for both frontend (`srv-d6kak0kr85hc739icnug`) and backend (`srv-d6jbmbp4tr6s739ccvcg`). Check `suspended` status.

2. **Latest deploys** — Call `list_deploys` for both frontend and backend (limit: 3 each). Note status of each deploy (live, build_in_progress, failed, deactivated).

3. **HTTP traffic & latency** — Call `get_metrics` for the backend with:
   - `metricTypes`: `["http_request_count", "http_latency"]`
   - Time range: last 1 hour
   - For request counts, use `aggregateHttpRequestCountsBy: "statusCode"` to get error breakdown

4. **Resource usage** — Call `get_metrics` for the backend with:
   - `metricTypes`: `["cpu_usage", "memory_usage", "cpu_limit", "memory_limit"]`
   - Time range: last 1 hour

5. **Database health** — Call `get_metrics` for the database (`dpg-d6jbi5fgi27c73d2jiv0-a`) with:
   - `metricTypes`: `["active_connections", "cpu_usage", "memory_usage"]`
   - Time range: last 1 hour

6. **Recent error logs** — Call `list_logs` for the backend with:
   - `resource`: `["srv-d6jbmbp4tr6s739ccvcg"]`
   - `level`: `["error", "fatal"]`
   - `limit`: 20

7. **Health endpoint** — Call the API health check via Bash: `curl -s -o /dev/null -w "%{http_code} %{time_total}s" https://terminal-trainer-api.onrender.com/api/health`

### Step 2: Present Report

Format the results as a structured report with these sections:

```
## Production Health Report

### Service Status
- Frontend: [running/suspended] — last deployed [time ago]
- Backend: [running/suspended] — last deployed [time ago]
- Database: [healthy/degraded]
- Health endpoint: [status code] ([response time])

### Recent Deploys
[Table: service, commit message (truncated), status, time]

### Traffic (last hour)
- Total requests: [count]
- Status breakdown: 2xx: [n], 4xx: [n], 5xx: [n]
- p95 latency: [value]ms
- Error rate: [percentage]

### Resource Usage
- Backend CPU: [current]% / [limit]%
- Backend Memory: [current]MB / [limit]MB
- Database connections: [count]

### Recent Errors
[List of last error log entries with timestamps, or "No errors" if clean]

### Verdict
[One-line summary: "All healthy", "Degraded — [reason]", or "Down — [reason]"]
```

### Step 3: Offer Follow-up Actions

After presenting the report, offer:
- "Want me to check the full logs for a specific time range?"
- "Want me to investigate any of the errors?"
- "Want me to check a specific endpoint's response?"

## Notes

- The backend is on Render's standard plan (Frankfurt region). It does NOT sleep on inactivity.
- The frontend is a static site served via CDN — it has no runtime metrics, only deploy status.
- The PostgreSQL instance ID starts with `dpg-` not `srv-`.
- If the workspace isn't selected, the Render tools will error. Prompt the user to run `/monitor` again if that happens — the workspace auto-selects on first call.
- Metrics may return empty arrays if the service was recently restarted or if the metric type isn't applicable. Handle gracefully.
- For `get_metrics` time range, compute RFC3339 timestamps: `startTime` = 1 hour ago, `endTime` = now. Use Bash to generate: `date -u -v-1H +%Y-%m-%dT%H:%M:%SZ` (macOS) for start time and `date -u +%Y-%m-%dT%H:%M:%SZ` for end time.
