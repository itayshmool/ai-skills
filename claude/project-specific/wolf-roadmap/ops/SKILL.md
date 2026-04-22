---
name: wolf-ops
description: The Wolf ops roadmap — track milestones, manage sprints, log progress, monitor health across the platform
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__google-drive__createGoogleSheet, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__google-drive__getSpreadsheetInfo, mcp__google-drive__listGoogleSheets, mcp__google-drive__createGoogleDoc, mcp__google-drive__readGoogleDoc, mcp__google-drive__updateGoogleDoc
argument-hint: "<command> [args]"
---

# Wolf Ops — Roadmap & Operations

Operational command center for **The Wolf** platform. Track milestones, manage the roadmap, log progress, and keep the project on rails.

## Project Context

- **Repo:** `/Users/itays/dev/wix/the-wolf`
- **Monorepo:** Turborepo + pnpm (`apps/web`, `apps/api`, `packages/shared`)
- **Stack:** Next.js 14 + Hono + PostgreSQL + Redis + BullMQ
- **Status:** MVP complete (phases 0-9), entering post-MVP iteration
- **GitHub:** `itayshmool/the-wolf` (if applicable, else local-only)

## Commands

### `status`
Show current project health and roadmap progress.

**Usage:** `/wolf-ops status`

**Steps:**
1. Read `CLAUDE.md` for current project state
2. Check git log for recent activity: `git log --oneline -20`
3. Check for open issues: `gh issue list --state open` (if GitHub remote exists)
4. Check Docker services: `docker compose ps`
5. Run quick health check on dev environment

**Output format:**
```
## The Wolf — Ops Status

### Project Phase
MVP complete. Post-MVP iteration.

### Recent Activity (7 days)
- [commit summary, grouped by area]

### Infrastructure
- PostgreSQL (5433): ✓ / ✗
- Redis (6380): ✓ / ✗
- Web (3100): ✓ / ✗ / not running
- API (4100): ✓ / ✗ / not running

### Open Issues
- [list or "none tracked"]

### Roadmap Progress
- [milestone summary from roadmap sheet/doc]
```

### `roadmap`
View or update the roadmap.

**Usage:**
- `/wolf-ops roadmap` — view current roadmap
- `/wolf-ops roadmap add "<milestone>" --phase <n> --area <web|api|shared|infra> [--priority high|medium|low]`
- `/wolf-ops roadmap update <id> <status>` — status: planned, in-progress, done, blocked

If no roadmap Google Sheet exists yet, create one with ID stored in `apps/web/.env.local` as `WOLF_ROADMAP_SHEET_ID`. Structure:

**Roadmap Sheet tabs:**

**Milestones (A:H)**
| ID | Phase | Milestone | Area | Priority | Status | Owner | Notes |

**Sprint Log (A:G)**
| Sprint | Start | End | Goals | Completed | Velocity | Notes |

**Decisions (A:F)**
| Date | Decision | Context | Area | Decided By | Status |

### `sprint`
Manage sprint cycles.

**Usage:**
- `/wolf-ops sprint start "<goals>"` — start a new sprint, log goals
- `/wolf-ops sprint end` — close current sprint, calculate velocity
- `/wolf-ops sprint current` — show active sprint and progress

### `decision`
Log an architectural or product decision.

**Usage:** `/wolf-ops decision "<what we decided>" --context "<why>" --area <area>`

### `health`
Deep health check — goes beyond `status` to verify the full stack.

**Usage:** `/wolf-ops health`

**Steps:**
1. Docker services up? (`docker compose ps`)
2. Database connectivity (`pnpm --filter api exec -- npx drizzle-kit check` or similar)
3. Build check: `pnpm build` (turbo)
4. Test check: `pnpm test` (if tests exist)
5. Disk usage of uploads directory
6. Redis connectivity
7. BullMQ queue status (pending/failed jobs)

### `changelog`
Generate a changelog from git history.

**Usage:** `/wolf-ops changelog [--since <date|tag>] [--format brief|detailed]`

Read git log, group commits by area (web/api/shared), and produce a formatted changelog.

## Conventions

- All roadmap data lives in a Google Sheet (created on first use)
- Decisions are append-only (never edit past decisions, add new ones)
- Sprint velocity = completed milestones / planned milestones
- Areas: `web`, `api`, `shared`, `infra`, `design`, `data`
- Priorities: `high`, `medium`, `low`
- Every blocked item must have a note explaining the blocker
