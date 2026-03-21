---
name: devops-status
description: Quick production status check for zero2claude.dev — service health, recent deploys, error count, DB connections
user-invocable: true
allowed-tools: Bash
argument-hint: "[--full] [--json]"
---

# DevOps Status — Quick Health Check

A lightweight status check for the Zero2Claude production stack. Faster than `/monitor` — focuses on "is everything OK right now?" rather than detailed metrics.

## What This Is NOT

- This is NOT `/monitor` — that does a comprehensive deep dive with metrics, traffic patterns, and resource trends.
- This is NOT `/render-expert` — that manages the full Render infrastructure across all projects.

Use `/devops-status` for a quick glance. Use `/monitor` when you need the full picture. Use `/render-expert` when you need to manage infrastructure.

## Service IDs

| Service | Type | ID |
|---------|------|----|
| Frontend | Static Site | `srv-d6kak0kr85hc739icnug` |
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |

## Workflow

### 1. Run health probes (all in parallel via Bash)

Run these 3 curl commands in a single parallel Bash call:

```bash
# API health endpoint
curl -s -o /dev/null -w "API: %{http_code} (%{time_total}s)\n" https://terminal-trainer-api.onrender.com/api/health

# Frontend reachable
curl -s -o /dev/null -w "Frontend: %{http_code} (%{time_total}s)\n" https://zero2claude.dev

# API settings endpoint (tests DB connectivity)
curl -s -o /dev/null -w "DB (via API): %{http_code} (%{time_total}s)\n" https://terminal-trainer-api.onrender.com/api/settings/maintenance
```

### 2. Check recent deploys

Use Render MCP `list_deploys` for both frontend and backend (limit: 1 each) to see when last deploy happened and if it succeeded.

### 3. Check error logs

Use Render MCP `list_logs` for the backend:
- `resource`: `["srv-d6jbmbp4tr6s739ccvcg"]`
- `level`: `["error", "fatal"]`
- `limit`: 5

Count errors. If 0, great. If >0, show the most recent one.

### 4. Present status

Format as a compact one-screen report:

```
## Zero2Claude Status

| Service    | Status | Response Time |
|------------|--------|---------------|
| Frontend   | ✓ 200  | 0.12s         |
| API        | ✓ 200  | 0.34s         |
| Database   | ✓ OK   | (via API)     |

Last deploy: [Backend] 2h ago — ✓ live
Errors (1h): 0

Verdict: All healthy
```

### Traffic light system:
- **Green** (all healthy): All endpoints 200, no errors, last deploy succeeded
- **Yellow** (degraded): Response time >2s, or 1-5 errors in last hour, or last deploy failed
- **Red** (down): Any endpoint non-200, or >5 errors in last hour

## Arguments

### Flags
- `--full` — Also include CPU/memory metrics and last 3 deploys per service. Essentially becomes a lighter `/monitor`.
- `--json` — Output as JSON instead of markdown table. Useful for piping to other tools.

### Examples
```
/devops-status              # Quick 5-second health check
/devops-status --full       # Include resource metrics
```

## Important Notes

- This skill should complete in under 10 seconds. Don't fetch unnecessary data.
- If the API returns a cold-start response (first request after Render wake-up takes 20-30s), note this but don't flag it as an issue — it's expected on the standard plan during low-traffic periods.
- If any probe times out after 30s, report it as "unreachable" rather than waiting longer.
