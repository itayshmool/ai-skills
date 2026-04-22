---
name: wolf-qa
description: The Wolf QA roadmap — test coverage tracking, quality gates, regression management, and release readiness
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows
argument-hint: "<command> [args]"
---

# Wolf QA — Quality Assurance Roadmap

Quality management for **The Wolf** platform. Track test coverage, plan testing strategies, manage quality gates, and ensure release readiness.

## Project Context

- **Repo:** `/Users/itays/dev/wix/the-wolf`
- **Monorepo:** `apps/web` (Next.js 14), `apps/api` (Hono), `packages/shared`
- **Test frameworks:** Vitest (check `vitest.config.*` in each workspace)
- **Build:** `pnpm build` (Turborepo)
- **Critical paths:** Data ingestion → Analysis pipeline → Insight generation → Fix plans

## Commands

### `coverage`
Analyze current test coverage across the monorepo.

**Usage:** `/wolf-qa coverage [--area <web|api|shared>]`

**Steps:**
1. Find all source files: `apps/web/src/**/*.{ts,tsx}`, `apps/api/src/**/*.ts`, `packages/shared/src/**/*.ts`
2. Find all test files: `**/*.test.{ts,tsx}`, `**/*.spec.{ts,tsx}`
3. Match source files to test files
4. Identify uncovered source files
5. Calculate coverage by area and by module

**Output format:**
```
## Test Coverage Report

### Summary
| Area | Source Files | Test Files | Coverage |
|------|-------------|------------|----------|
| web | 45 | 12 | 27% |
| api | 30 | 8 | 27% |
| shared | 5 | 2 | 40% |

### Uncovered Critical Paths
- ✗ apps/api/src/services/ingestion/column-mapper.ts (13 rules, 0 tests)
- ✗ apps/api/src/services/ingestion/tree-builder.ts (manager resolution, 0 tests)
- ✗ apps/api/src/jobs/analysis-worker.ts (agent pipeline, 0 tests)

### Coverage Priorities (by risk)
1. [HIGH] Ingestion pipeline — data corruption risk
2. [HIGH] Analysis consensus engine — 7 rules with no tests
3. [MED] API route handlers — tenant isolation
4. [MED] Fix plan generation — output quality
5. [LOW] Frontend components — visual, harder to unit test
```

### `plan`
Create a testing strategy for a specific area or feature.

**Usage:** `/wolf-qa plan "<area or feature>"`

**Steps:**
1. Read the relevant source code
2. Identify testable units (functions, routes, components)
3. Classify by test type (unit, integration, e2e)
4. Prioritize by risk (data corruption > wrong output > UI glitch)
5. Generate test file stubs if requested

**Output format:**
```
## Test Plan: <area>

### Unit Tests
| # | What to Test | File | Priority |
|---|-------------|------|----------|
| 1 | Column mapper — email detection | column-mapper.test.ts | HIGH |
| 2 | Column mapper — name detection | column-mapper.test.ts | HIGH |

### Integration Tests
| # | What to Test | Scope | Priority |
|---|-------------|-------|----------|
| 1 | CSV upload → tree building | ingestion pipeline | HIGH |

### Edge Cases
- Empty CSV upload
- CSV with missing manager column
- Circular manager references
- Duplicate employee IDs
- Unicode names / special characters
```

### `gate`
Run a quality gate check (like `/qa` but Wolf-specific).

**Usage:** `/wolf-qa gate [--pre-push | --pre-release]`

**Pre-push gate:**
1. TypeScript: `pnpm build` (all workspaces)
2. Tests: `pnpm test` (all workspaces)
3. Lint check (if configured)
4. Check for `console.log` statements in committed code
5. Check for hardcoded tenant IDs or dev-only code
6. Verify no `.env` files or secrets in diff

**Pre-release gate (stricter):**
All of pre-push, plus:
7. Run full test suite with coverage report
8. Check all API routes have error handling
9. Verify multi-tenant isolation (no queries without `tenant_id` filter)
10. Check BullMQ job handlers are idempotent
11. Verify PII handling (encryption path tested)
12. Database schema matches code (no missing columns)

### `regression`
Track and manage known regressions.

**Usage:**
- `/wolf-qa regression` — list known regressions
- `/wolf-qa regression add "<description>" --area <area> --severity <critical|high|medium|low>`
- `/wolf-qa regression verify <id>` — re-test a regression to confirm it's fixed

### `matrix`
Generate a test matrix for a release or feature.

**Usage:** `/wolf-qa matrix "<feature or release>"`

Produces a test matrix covering:
- Happy paths per chapter (I-IX)
- Error paths (invalid data, network failures, queue failures)
- Multi-tenant scenarios (data isolation)
- PII scenarios (with and without encryption key)
- Browser/viewport considerations (mobile + desktop)
- Concurrent analysis runs

### `debt`
Track testing debt — areas that need tests but don't have them.

**Usage:** `/wolf-qa debt`

Scan for:
1. Source files without corresponding test files
2. Functions with high cyclomatic complexity but no tests
3. Error handling paths that are never tested
4. API routes without integration tests
5. Queue workers without job-level tests

## Quality Standards for The Wolf

### Must-Test Areas
- **Ingestion pipeline** — column mapping rules, tree building, manager resolution
- **Consensus engine** — all 7 validation rules
- **Tenant isolation** — every API route filters by tenant_id
- **PII handling** — encryption/decryption round-trip
- **Queue jobs** — idempotent execution, retry behavior, error handling
- **PDF generation** — output structure (not pixel-perfect)

### Known Gotchas (Test These!)
- Hono route ordering — specific routes before catch-all `/:param`
- `Evgeniya Samarskaya` root node edge case in Wix data
- Multiple datasets from testing — queries should use `status = 'ready'`
- Manager resolution disambiguation (same name, different departments)
- File uploads stored locally (not S3) — disk space considerations

### Test Naming Convention
```
describe('ColumnMapper', () => {
  it('should detect email columns by header name', () => {})
  it('should detect email columns by content pattern', () => {})
  it('should handle missing headers gracefully', () => {})
})
```

## Conventions

- Coverage reports include file-level detail, not just percentages
- Test plans are ordered by risk (highest first)
- Every regression gets a test before it's marked fixed
- Quality gates are pass/fail — no "soft" warnings for critical checks
- Test debt is tracked alongside tech debt
