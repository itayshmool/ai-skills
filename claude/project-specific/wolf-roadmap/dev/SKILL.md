---
name: wolf-dev
description: The Wolf dev roadmap — plan features, track technical debt, manage implementation tasks with TDD
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__google-drive__getSpreadsheetInfo
argument-hint: "<command> [args]"
---

# Wolf Dev — Development Roadmap

Development task management for **The Wolf** platform. Plan features, track tech debt, manage implementation backlogs, and enforce engineering standards.

## Project Context

- **Repo:** `/Users/itays/dev/wix/the-wolf`
- **Monorepo:** `apps/web` (Next.js 14), `apps/api` (Hono), `packages/shared`
- **DB:** Drizzle ORM 0.45 + PostgreSQL (schema in `apps/api/src/db/schema.ts`)
- **Queue:** BullMQ (analysis pipeline + fix-plan pipeline)
- **13 tables:** tenants, users, datasets, employees, employee_paths, performance_datasets, performance_metrics, context_documents, analyses, insights, fix_plans, analytics_cache, audit_log

## Commands

### `backlog`
View or manage the development backlog.

**Usage:**
- `/wolf-dev backlog` — show all open items grouped by area
- `/wolf-dev backlog add "<task>" --area <web|api|shared|db|queue> [--type feature|bugfix|debt|refactor] [--priority high|medium|low]`
- `/wolf-dev backlog pick` — suggest the next highest-impact task to work on
- `/wolf-dev backlog done <id>` — mark a task complete

### `debt`
Track and manage technical debt.

**Usage:**
- `/wolf-dev debt` — list known tech debt
- `/wolf-dev debt add "<description>" --area <area> --impact <high|medium|low>`
- `/wolf-dev debt scan` — scan codebase for common debt signals

**Debt scan checks:**
1. `TODO` / `FIXME` / `HACK` comments in source files (exclude node_modules)
2. Files with no test coverage (source files without corresponding `.test.` files)
3. Large files (>300 lines) that may need splitting
4. Unused exports or dead code signals
5. Dependencies with known issues (`pnpm audit`)
6. Schema gaps (columns referenced in code but not in schema)

### `feature`
Plan a feature before implementing it.

**Usage:** `/wolf-dev feature "<name>" [--scope <description>]`

**Steps:**
1. Read relevant existing code to understand current state
2. Identify affected files and modules
3. Propose implementation approach (files to create/modify)
4. Define acceptance criteria
5. Write task breakdown (each task = a single commit)
6. Ask user for approval before proceeding

**Output format:**
```
## Feature: <name>

### Current State
[What exists today]

### Proposed Changes
| # | Task | Area | Files |
|---|------|------|-------|
| 1 | ... | api | src/routes/... |

### Acceptance Criteria
- [ ] ...

### Technical Notes
- [patterns to follow, gotchas, dependencies]

### Test Plan
- [ ] Unit: ...
- [ ] Integration: ...
```

### `scope`
Analyze the scope and impact of a proposed change.

**Usage:** `/wolf-dev scope "<description>"`

Traces through the codebase to identify:
- Which files would need to change
- Which tests would need updating
- Database migration needs
- API contract changes
- Frontend component impacts

### `deps`
Check dependency health.

**Usage:** `/wolf-dev deps`

**Steps:**
1. `pnpm audit` — security vulnerabilities
2. `pnpm outdated` — stale packages
3. Check for duplicate dependencies across workspaces
4. Flag any packages pinned to exact versions with known issues

### `schema`
Review and plan database schema changes.

**Usage:**
- `/wolf-dev schema` — show current schema summary
- `/wolf-dev schema plan "<change>"` — plan a migration

Read `apps/api/src/db/schema.ts`, summarize tables/columns, and if planning a change, show the Drizzle schema diff needed.

## Engineering Standards

When planning or reviewing work, enforce these:

1. **Route ordering in Hono** — specific routes before catch-all `/:param` routes
2. **Tenant isolation** — every query must filter by `tenant_id`
3. **PII handling** — names encrypted when `PII_ENCRYPTION_KEY` is set
4. **No raw SQL** — use Drizzle typed operators (eq, gt, lt, etc.)
5. **Queue jobs** — idempotent, with retry logic, proper error handling
6. **Frontend** — Pulp Fiction design system (wolf-card, wolf-btn-*, font-display/body)
7. **Duplicate rendering** — mobile + desktop instances must both be updated

## Conventions

- Feature type: `feature`, `bugfix`, `debt`, `refactor`
- Areas: `web`, `api`, `shared`, `db`, `queue`
- Every feature plan must include a test plan
- Tech debt items should include impact assessment
- Schema changes require explicit migration planning
