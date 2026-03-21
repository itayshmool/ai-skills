---
name: devops-incident
description: Investigate production incidents for zero2claude.dev — trace errors from logs to code to root cause to fix
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: "\"<error description or log snippet>\" [--fix] [--dry-run]"
---

# DevOps Incident Investigation

You are the incident response agent for **zero2claude.dev**. When something breaks in production, you trace the error from logs through the codebase to identify root cause, then propose or implement a fix.

## Repos

- **Main app**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/`
- **Frontend**: `src/` (React + TypeScript + Vite)
- **Backend**: `server/src/` (Express + TypeScript + Drizzle)

## Service IDs

| Service | Type | ID |
|---------|------|----|
| Frontend | Static Site | `srv-d6kak0kr85hc739icnug` |
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |

## Workflow

### 1. Gather error context

If the user provides a specific error:
- Parse the error message, stack trace, or log snippet they provided

If the user says something vague ("the app is broken", "students can't log in"):
- Pull recent error logs via Render MCP `list_logs`:
  - `resource`: `["srv-d6jbmbp4tr6s739ccvcg"]`
  - `level`: `["error", "fatal"]`
  - `limit`: 30
- Also check HTTP error rates via `get_metrics` with `aggregateHttpRequestCountsBy: "statusCode"`
- Identify the most frequent/recent error pattern

### 2. Classify the incident

| Type | Indicators | Urgency |
|------|-----------|---------|
| **API down** | Health endpoint fails, 5xx errors | Critical — all students affected |
| **Auth broken** | 401s on protected routes, JWT errors | Critical — no one can log in |
| **DB connection** | "connection refused", pool exhaustion | Critical — all data ops fail |
| **Feature broken** | Errors in specific route (forum, progress, etc.) | High — some students affected |
| **Performance** | p95 latency >5s, memory climbing | Medium — degraded experience |
| **Frontend crash** | White screen, React error boundary | High — affects rendering |
| **Data issue** | Wrong data returned, missing records | Medium — investigation needed |

### 3. Trace to code

Based on the error:

1. **Identify the file and line** — Parse stack traces, grep for error messages in the codebase
2. **Read the relevant code** — Understand the function, its inputs, and what could fail
3. **Check recent changes** — `git log --oneline -10 -- <file>` to see if a recent commit introduced the bug
4. **Trace the request flow** — Follow the route handler → middleware → service → database path
5. **Check related code** — Are there similar patterns elsewhere that might also be affected?

### 4. Identify root cause

Write a clear root cause statement:
```
Root cause: [What broke] because [why it broke], introduced by [commit/change] on [date].
Impact: [Who is affected and how].
```

### 5. Propose fix

Present the fix plan:
- What files need to change
- What the change is
- Why this fixes the root cause
- Any risks or side effects

If `--fix` flag: Implement the fix on a feature branch.
If `--dry-run` flag: Show exactly what would change without modifying files.

### 6. Implement fix (if --fix)

```bash
cd /Users/itays/dev/training/from-dev-basics-to-claude-code
git checkout main && git pull
git checkout -b fix/[short-description]
```

Make the fix, then verify:
```bash
npm run build && npm test
cd server && npm run build && npm test
```

Commit on the feature branch. Do NOT push unless explicitly asked.

## Arguments

### Positional
The first argument is the error description, log snippet, or symptom:
```
/devops-incident "TypeError: Cannot read property 'id' of undefined in forum route"
/devops-incident "students getting 500 errors on login"
/devops-incident "memory keeps climbing on the backend"
```

### Flags
- `--fix` — After identifying root cause, implement the fix on a feature branch.
- `--dry-run` — Show what the fix would look like without making changes.

### Examples
```
/devops-incident "500 errors on POST /api/forum/threads"           # Investigate only
/devops-incident "500 errors on POST /api/forum/threads" --fix     # Investigate and fix
/devops-incident "app won't load" --dry-run                        # Investigate, show fix plan
/devops-incident                                                    # Pull latest errors, investigate top issue
```

## Investigation Shortcuts

### Common error patterns

| Error | Likely cause | Where to look |
|-------|-------------|---------------|
| `ECONNREFUSED` | DB connection failed | `server/src/db/` connection config, Render DB status |
| `JsonWebTokenError` | JWT secret mismatch or expired token | `server/src/routes/auth.ts`, env vars on Render |
| `relation "X" does not exist` | Missing migration | `server/drizzle/`, run `npm run db:migrate` |
| `body limit exceeded` | Image upload too large | Express body parser limits, `resizeImage()` client-side |
| `ERR_MODULE_NOT_FOUND` | Missing import after refactor | Check import paths, `npm install` |
| `CORS error` | Cross-origin cookie issue | `sameSite`, `credentials`, Render domains |
| `Rate limit exceeded` | In-memory rate limit triggered | `aiClient.ts`, `paletteGenerator.ts`, `onboardingGenerator.ts` |
| Memory climbing | Listener leak, cache growth | Event emitters, `setInterval` without cleanup |

### Key backend files for tracing

```
server/src/index.ts              → Express setup, middleware, error handler
server/src/routes/auth.ts        → Login, register, token refresh, profile
server/src/routes/progress.ts    → Lesson completion, stats, achievements
server/src/routes/forum.ts       → Forum CRUD, voting, search
server/src/routes/onboarding.ts  → AI onboarding plan generation
server/src/routes/admin.ts       → Admin operations
server/src/db/schema.ts          → All table definitions
server/src/lib/contentModerator.ts → Input validation
server/src/services/api.ts       → API client (frontend)
```

## Important Notes

- **ALWAYS work on a feature branch** for fixes. NEVER commit to main.
- This is a live production system with 200+ students. Be careful with fixes.
- The backend uses `asyncHandler` wrapper — if a route is missing it, unhandled async errors will crash Express.
- Check BOTH frontend and backend when investigating — the error might originate on one side but manifest on the other.
- When in doubt about a fix, propose it without implementing. Better to be safe.
- After fixing, always run both frontend and backend test suites before committing.
