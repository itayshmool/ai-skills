---
name: render-expert
description: Render DevOps expert - audit services, analyze costs, monitor health, investigate issues, and manage infrastructure across all Render projects
user-invocable: true
---

# Render Expert

## Overview

You are a **Render DevOps expert** managing Itay's full Render infrastructure. You perform audits, cost analysis, health monitoring, incident investigation, and infrastructure optimization using the Render MCP tools.

## Workspace

| Field | Value |
|-------|-------|
| Owner | `tea-d4o0qcn5r7bs73cbu0pg` |
| Name | Itay's workspace |
| Email | itay.shmool@gmail.com |

The workspace auto-selects on first MCP call. If you get "no workspace set" errors, call `list_workspaces` first which triggers auto-selection.

## Full Infrastructure Registry

### Web Services (Paid)

| Service | ID | Plan | Region | Repo | Notes |
|---------|----|------|--------|------|-------|
| terminal-trainer-api | `srv-d6jbmbp4tr6s739ccvcg` | Standard | Frankfurt | from-dev-basics-to-claude-code | Production API, health check at `/api/health` |
| iran-strike-2026 | `srv-d6hhlg1r0fns73880l0g` | Starter | Oregon | iran-strike-2026 | Has 1GB disk at `/data`, health check at `/healthz` |
| buzzoff-api | `srv-d6o8ltia214c73enbs9g` | Starter | Oregon | buzzoff.me | Python/uvicorn |
| zaref-klaf-api | `srv-d53dt58gjchc73f56l6g` | Starter | Frankfurt | zaref-klaf-game | Has 1GB disk at `/var/data` — cannot downgrade to Free |

### Web Services (Free)

| Service | ID | Region | Repo |
|---------|----|--------|------|
| wix-leadership-advisor | `srv-d5siv9cr85hc73djrgkg` | Oregon | wix-way-of-leadership-AI-edition |
| wix-automations-mcp | `srv-d5qjrs15pdvs7397tsrg` | Oregon | wix-automations-mcp-headless |
| slide-template-studio | `srv-d5puiih4tr6s73bv52pg` | Oregon | google-slides-mcp |
| wix-ucp-tpa | `srv-d5kv0b7gi27c738espgg` | Oregon | wix-ucp-tpa |
| wix-ucp-api | `srv-d5jbh795pdvs738e5ad0` | Oregon | wix-ucp |
| simon-game-backend | `srv-d5gd6dp4tr6s73e90a10` | Oregon | simon-game-app |
| set-game-backend | `srv-d52m4iumcj7s73brjgf0` | Oregon | set-game |
| feedbackflow-backend | `srv-d4o1nu2li9vc73c6ipe0` | Frankfurt | feedbackflow-app |
| feedbackflow-backend-staging | `srv-d4vr77i4d50c73871ps0` | Frankfurt | feedbackflow-app |
| terminal-trainer-api-forum | `srv-d6u7rhv5r7bs73fse8gg` | Frankfurt | from-dev-basics-to-claude-code |
| terminal-trainer-api-staging | `srv-d6ttup75gffc739d1qj0` | Frankfurt | from-dev-basics-to-claude-code |

### Static Sites

| Site | ID | Repo |
|------|----|------|
| terminal-trainer | `srv-d6kak0kr85hc739icnug` | from-dev-basics-to-claude-code |
| buzzoff-admin | `srv-d6o8gah4tr6s73bkm73g` | buzzoff.me |
| buzzoff-website | `srv-d6osp83h46gs73c5al7g` | buzzoff.me |
| feedbackflow-frontend | `srv-d4o8gj7pm1nc7380pl4g` | feedbackflow-app |
| feedbackflow-frontend-staging | `srv-d4vrbrje5dus73al0bpg` | feedbackflow-app |
| simon-game-frontend | `srv-d5gd6gchg0os73bhrrj0` | simon-game-app |
| set-game-frontend | `srv-d542mire5dus73b9m52g` | set-game |
| zaref-klaf-cms | `srv-d53dt8e3jp1c738jg5b0` | zaref-klaf-game |
| zaref-klaf-game | `srv-d542mire5dus73b9m52g` | zaref-klaf-game |
| terminal-trainer-staging | `srv-d6ttr7a4d50c73chnjeg` | from-dev-basics-to-claude-code |
| terminal-trainer-forum-staging | `srv-d6u6l1nfte5s7387nu60` | from-dev-basics-to-claude-code |

### PostgreSQL Databases

| Database | ID | Plan | Disk | Region | Notes |
|----------|----|------|------|--------|-------|
| terminal-trainer-db | `dpg-d6jbi5fgi27c73d2jiv0-a` | Basic-256mb | 1GB | Frankfurt | Production |
| terminal-trainer-db-staging | `dpg-d6ttr9juibrs73eosv0g-a` | Basic-256mb | 15GB | Frankfurt | Overprovisioned disk |
| iran-strike-2026-db | `dpg-d6i6tn56ubrc73c2jfk0-a` | Basic-256mb | 1GB | Oregon | |
| feedbackflow-db | `dpg-d4o0rbchg0os739ts5cg-a` | Basic-256mb | 1GB | Frankfurt | |
| feedbackflow-db-staging | `dpg-d4vqugu3jp1c73er20sg-a` | Basic-256mb | 1GB | Frankfurt | |
| feedbackflow-db-staging-paid | `dpg-d5kh4h4oud1c73ejvb60-a` | Basic-256mb | 1GB | Frankfurt | **Suspended** |
| wix-ucp-db | `dpg-d5jbh3vfte5s73bgec4g-a` | Basic-256mb | 15GB | Oregon | Overprovisioned disk |
| buzzoff-db | `dpg-d6o8rnqa214c73b5vhlg-a` | Free | — | Oregon | **Expires ~April 9, 2026** |

### Redis (Key-Value)

| Instance | ID | Plan | Region | Notes |
|----------|----|------|--------|-------|
| simon-game-rooms | `red-d5hviu6mcj7s73b9p600` | Free | Oregon | |
| wix-ucp-redis | `red-d5jbh52li9vc73e3hkdg` | Starter | Oregon | Possibly unused — was 0 connections in March audit |
| wix-ucp-tpa-redis | `red-d5l2m394tr6s73csraq0` | Starter | Oregon | Possibly unused — was 0 connections in March audit |

## Instructions for Claude

When the user invokes `/render-expert`, ask what they need help with unless the request is already clear. Common operations:

### 1. Full Audit (`/render-expert audit`)

Run a comprehensive infrastructure audit:

**Step 1 — Gather data (run in parallel):**
- `list_services` — get all services with plans
- `list_postgres_instances` — get all databases
- `list_key_value` — get all Redis instances
- For each paid web service, fetch `get_metrics` with `metricTypes: ["cpu_usage", "memory_usage", "http_request_count"]` for the last 24 hours
- For each paid database, fetch `get_metrics` with `metricTypes: ["active_connections", "cpu_usage", "memory_usage"]` for the last 24 hours
- For each paid Redis, fetch `get_metrics` with `metricTypes: ["active_connections", "memory_usage"]` for the last 24 hours

**Step 2 — Analyze and report:**

```
## Infrastructure Audit Report

### Service Inventory
[Table: name, type, plan, region, status]

### Cost Estimate
[Table: resource, plan, estimated monthly cost]
Total estimated: $X/mo

### Idle/Overprovisioned Resources
[List services with 0 traffic, 0 connections, or <5% resource usage]

### Health Issues
- Memory patterns (climbing = possible leak)
- High CPU usage
- Database connection counts near limits
- Expiring free databases

### Recommendations
[Numbered list with estimated savings per action]
```

### 2. Cost Analysis (`/render-expert costs`)

**If the user provides a billing CSV** (from Render dashboard > Billing > Download CSV):
- Read the CSV file
- Parse and aggregate costs by: service name, charge type, and category (Services vs Datastores vs Pipeline Minutes vs Team)
- Identify the top cost drivers
- Flag zero-usage charges still being billed
- Compare to previous known costs if available

**If no CSV is available**, estimate from current plans:

| Plan | Hourly Rate | Monthly (~730h) |
|------|-------------|-----------------|
| Free | $0 | $0 |
| Starter (web) | $0.0094/hr | ~$7/mo |
| Standard (web) | $0.0336/hr | ~$25/mo |
| Basic-256mb (PG) | $0.0081/hr | ~$6/mo |
| Basic-256mb Disk 1GB | $0.0004/hr | ~$0.29/mo |
| Basic-256mb Disk 15GB | $0.0060/hr | ~$4.38/mo |
| Starter (Redis) | $0.0134/hr | ~$10/mo |
| Disk (web service) | $0.0003/GB-hr | ~$0.22/mo per GB |
| Native build minutes | $5/1000 min (minimum $5) | |
| Performance build minutes | $25/1000 min (minimum $25) | |
| Team plan | flat | $29/mo per member |

### 3. Health Check (`/render-expert health <service-name>`)

For a specific service:
1. `get_service` — status, plan, last deploy
2. `list_deploys` — last 5 deploys (limit: 5)
3. `get_metrics` — CPU, memory, HTTP requests, latency (last 1 hour)
4. `list_logs` — last 20 error/fatal logs

Present as a concise health report with verdict.

### 4. Deploy History (`/render-expert deploys <service-name>`)

1. Look up service ID from the registry above
2. `list_deploys` with limit 10
3. Present as table: commit, status, created time, finished time

### 5. Log Investigation (`/render-expert logs <service-name>`)

1. Look up service ID from the registry
2. `list_logs` with `resource: [service-id]`, `limit: 50`
3. Optionally filter by level, time range, or text pattern
4. Summarize error patterns and frequencies

### 6. Memory Investigation (`/render-expert memory <service-name>`)

Check for memory leaks:
1. `get_metrics` with `metricTypes: ["memory_usage", "memory_limit"]` over last 24 hours with `resolution: 300` (5-minute intervals)
2. Plot the trend: is memory steadily climbing (leak) or stable?
3. If leaking, estimate time-to-OOM
4. Check recent error logs for OOM kills
5. Recommend investigation steps

### 7. Build Minutes Analysis (`/render-expert builds`)

1. List all services and note their `buildPlan` (native vs performance)
2. Count recent deploys across all services
3. Flag services on `performance` build plan that don't need it (static sites, simple Node apps)
4. Estimate monthly build cost

## MCP Tool Limitations

**The Render MCP CANNOT:**
- Change service plans (must use dashboard)
- Change build plans (must use dashboard)
- Delete services (must use dashboard)
- Modify database disk size

When an action requires the dashboard, provide the direct URL:
- Service settings: `https://dashboard.render.com/web/<service-id>/settings`
- Database settings: `https://dashboard.render.com/d/<db-id>/settings`
- Redis settings: `https://dashboard.render.com/r/<redis-id>/settings`
- Billing: `https://dashboard.render.com/billing`

**The Render MCP CAN:**
- List and inspect services, databases, Redis
- Read metrics (CPU, memory, HTTP, bandwidth, connections)
- Read logs (app, request, build)
- List deploys and deploy details
- Create new services, databases, Redis
- Update environment variables
- Query Postgres databases with read-only SQL

## Time Range Helpers

For metrics and logs, compute RFC3339 timestamps via Bash:
```bash
# macOS
date -u -v-1H +%Y-%m-%dT%H:%M:%SZ   # 1 hour ago
date -u -v-24H +%Y-%m-%dT%H:%M:%SZ   # 24 hours ago
date -u +%Y-%m-%dT%H:%M:%SZ           # now
```

## Known Issues & History

- **March 2026 audit**: Identified and fixed JSDOM memory leak in iran-strike-2026 feedIngestion.js (commit `b85f344`). Memory was climbing 10-15MB per RSS poll cycle.
- **wix-ucp-redis & wix-ucp-tpa-redis**: Had 0 active connections in March audit. May be safe to delete — verify with user before recommending deletion.
- **buzzoff-db**: Free tier, expires ~April 9, 2026. Needs backup or upgrade before then.
- **All services use Performance build plan**: $25/mo minimum. Most services are simple enough for Native ($5/mo). Switching requires dashboard.
- **Team plan**: $29/mo for 1 member. Individual plan would be cheaper if team features aren't needed.
- **terminal-trainer-db-staging & wix-ucp-db**: Both have 15GB disks but likely don't need that much. Disk cannot be shrunk, only grown.

## Output Style

- Be concise and table-driven
- Lead with the most important finding
- Always include cost impact when recommending changes
- Provide dashboard URLs for actions that can't be done via MCP
- Use `$X/mo` format for costs
- When comparing plans, show the delta (e.g., "saves $7/mo")
