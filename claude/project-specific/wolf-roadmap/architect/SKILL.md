---
name: wolf-architect
description: The Wolf architecture roadmap — system design, technical decisions, scalability planning, and ADRs
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__google-drive__createGoogleDoc, mcp__google-drive__readGoogleDoc, mcp__google-drive__updateGoogleDoc, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows
argument-hint: "<command> [args]"
---

# Wolf Architect — Architecture Roadmap

Architecture management for **The Wolf** platform. Track design decisions, plan system evolution, manage technical strategy, and maintain architectural integrity.

## Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        apps/web                              │
│  Next.js 14 App Router + Tailwind + Recharts                │
│  Chapters I-IX navigation, Pulp Fiction theme               │
│  react-window v2 (org tree), pdfkit (exports)               │
├─────────────────────────────────────────────────────────────┤
│                        apps/api                              │
│  Hono + Drizzle ORM 0.45 + BullMQ                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐            │
│  │ Routes   │ │ Services │ │ Jobs/Workers     │            │
│  │ REST API │→│ Business │→│ Analysis Pipeline│            │
│  │ Hono     │ │ Logic    │ │ Fix Plan Pipeline│            │
│  └──────────┘ └──────────┘ └──────────────────┘            │
├─────────────────────────────────────────────────────────────┤
│  packages/shared — Types + Utilities                        │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL (5433)  │  Redis (6380)  │  Local Disk (uploads)│
│  13 tables          │  BullMQ queues │  CSV files           │
│  Drizzle schema     │  Job state     │  (not S3 yet)        │
└─────────────────────────────────────────────────────────────┘
```

### Agent Pipeline
```
Upload CSV → Column Mapper → Tree Builder → Employee Records
                                                    ↓
                                            Analysis Config
                                                    ↓
                                    ┌───────────────────────────────┐
                                    │     BullMQ Analysis Queue     │
                                    │  ┌─────────┐  ┌───────────┐  │
                                    │  │  Wolf    │→ │  Mirror   │  │
                                    │  │  Agent   │  │  Agent    │  │
                                    │  └─────────┘  └───────────┘  │
                                    │         ↓            ↓        │
                                    │    ┌─────────────────────┐   │
                                    │    │  Consensus Engine   │   │
                                    │    │  7 deterministic    │   │
                                    │    │  validation rules   │   │
                                    │    └─────────────────────┘   │
                                    └───────────────────────────────┘
                                                    ↓
                                    ┌───────────────────────────────┐
                                    │   BullMQ Fix Plan Queue       │
                                    │   Fixer Agent → Phased Plans  │
                                    └───────────────────────────────┘
```

## Commands

### `adr`
Manage Architecture Decision Records.

**Usage:**
- `/wolf-architect adr` — list all ADRs
- `/wolf-architect adr new "<title>"` — create a new ADR
- `/wolf-architect adr supersede <id> "<new decision>"`

ADRs are stored in `docs/adr/` (created on first use).

**ADR format:**
```markdown
# ADR-NNN: <Title>

**Date:** YYYY-MM-DD
**Status:** proposed | accepted | deprecated | superseded by ADR-NNN
**Area:** web | api | shared | infra | data | security

## Context
[What forces are at play? What problem are we solving?]

## Decision
[What we decided to do]

## Consequences
[What becomes easier? What becomes harder?]

## Alternatives Considered
[What else we could have done and why we didn't]
```

### `audit`
Architectural audit — check system health and identify drift.

**Usage:** `/wolf-architect audit [--area <area>]`

**Checks:**
1. **Layering** — Do routes call services, not DB directly?
2. **Tenant isolation** — Every query filtered by tenant_id?
3. **Error boundaries** — Every route wrapped in error handling?
4. **Type safety** — Shared types used consistently across web/api?
5. **Queue patterns** — Jobs idempotent? Retry logic correct?
6. **Schema alignment** — Drizzle schema matches actual usage?
7. **Dependency direction** — shared ← api, shared ← web (never api ↔ web)?
8. **Secret management** — No hardcoded keys, PII encryption configured?

**Output:** Table of checks with pass/fail/warning and specific file references.

### `evolve`
Plan the next architectural evolution.

**Usage:** `/wolf-architect evolve "<goal>"`

Examples:
- `/wolf-architect evolve "add real-time analysis progress"`
- `/wolf-architect evolve "move to S3 for file storage"`
- `/wolf-architect evolve "add Clerk authentication"`

**Steps:**
1. Analyze current architecture relevant to the goal
2. Identify what needs to change (with specific files)
3. Propose approach with trade-offs
4. Identify risks and migration path
5. Estimate blast radius (how many files/modules affected)
6. Create ADR if decision is significant

### `diagram`
Generate architecture diagrams.

**Usage:**
- `/wolf-architect diagram system` — full system overview
- `/wolf-architect diagram data` — data flow from upload to insight
- `/wolf-architect diagram "<component>"` — specific component deep-dive

Outputs ASCII diagrams that can be embedded in docs.

### `boundaries`
Analyze and enforce module boundaries.

**Usage:** `/wolf-architect boundaries`

Check that:
- `apps/web` only imports from `packages/shared`, never from `apps/api`
- `apps/api` only imports from `packages/shared`, never from `apps/web`
- `packages/shared` has no app-specific dependencies
- Route files don't contain business logic (should delegate to services)
- Services don't import from route layer

### `scale`
Analyze scaling bottlenecks and plan for growth.

**Usage:** `/wolf-architect scale "<scenario>"`

Examples:
- `/wolf-architect scale "10k employees per dataset"`
- `/wolf-architect scale "100 concurrent analyses"`
- `/wolf-architect scale "multi-region deployment"`

Analyze current architecture against the scenario and identify:
- Bottlenecks (DB queries, queue throughput, memory)
- Required changes (indexes, caching, horizontal scaling)
- Architecture changes needed (if any)

### `stack`
Review and recommend technology decisions.

**Usage:**
- `/wolf-architect stack` — current stack overview with versions
- `/wolf-architect stack evaluate "<technology>" --for "<purpose>"`

### `security`
Security architecture review.

**Usage:** `/wolf-architect security`

Review:
1. Authentication (currently dev-token only → Clerk planned)
2. Authorization (RLS defined but not enforced)
3. PII encryption (AES-256-GCM when key present)
4. Tenant isolation (middleware + query-level)
5. Input validation (CSV uploads, API inputs)
6. Secret management (env vars, no vault yet)
7. CORS configuration
8. Rate limiting (BullMQ has 5/min, API has none)

## Architectural Principles for The Wolf

1. **Multi-tenant first** — every feature must isolate tenant data
2. **Queue over sync** — long operations go through BullMQ, never block requests
3. **Schema as truth** — Drizzle schema is the single source of truth for data model
4. **Layered architecture** — routes → services → data access (no shortcuts)
5. **Shared types** — API contracts defined in `packages/shared`
6. **Fail loud** — prefer errors over silent data corruption
7. **Encrypt by default** — PII encrypted when key is available

## Known Architecture Debt

| Item | Impact | Area |
|------|--------|------|
| File uploads on local disk (not S3) | Can't scale horizontally | infra |
| Dev token auth (no Clerk) | No real user isolation | security |
| RLS policies not enforced at connection level | Defense-in-depth gap | security |
| No API rate limiting | Abuse risk | api |
| No WebSocket/SSE for analysis progress | Users poll or refresh | web |
| Single Redis instance | No HA for queue | infra |

## Conventions

- ADRs are numbered sequentially (ADR-001, ADR-002, ...)
- Every significant decision gets an ADR (not just architecture — also tech choices)
- Diagrams use ASCII art for portability
- Audit results reference specific files and line numbers
- Evolution plans include rollback strategy
