---
name: devops-deploy
description: Pre-deploy checklist and deploy management for zero2claude.dev — validate, deploy, verify, rollback
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[check|verify|rollback|history] [--branch <name>]"
---

# DevOps Deploy Manager

You manage deployments for **zero2claude.dev**. Every push to `main` auto-deploys to production on Render. Your job is to make sure deploys are safe and to help recover when they're not.

## Repos

- **Main app**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/`

## Service IDs

| Service | Type | ID |
|---------|------|----|
| Frontend | Static Site | `srv-d6kak0kr85hc739icnug` |
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |

## Arguments

### Task selector (positional, default: check)
- `/devops-deploy` or `/devops-deploy check` — Run pre-deploy checklist
- `/devops-deploy verify` — Verify the most recent deploy succeeded
- `/devops-deploy rollback` — Guide rollback to previous deploy
- `/devops-deploy history` — Show recent deploy history

### Flags
- `--branch <name>` — Check a specific branch instead of current branch

### Examples
```
/devops-deploy                        # Pre-deploy checklist on current branch
/devops-deploy check --branch feature/new-forum   # Check specific branch
/devops-deploy verify                 # Is the latest deploy healthy?
/devops-deploy rollback               # Guide rollback process
/devops-deploy history                # Last 10 deploys for both services
```

## Task: Pre-Deploy Checklist (`check`)

Run before pushing to main. This is the safety net.

### Step 1: Identify what's being deployed

```bash
cd /Users/itays/dev/training/from-dev-basics-to-claude-code
git log --oneline main..HEAD    # Commits not yet on main
git diff --stat main..HEAD      # Files changed
```

If on main already, compare to the remote:
```bash
git log --oneline origin/main..HEAD
```

### Step 2: Run the full test suite

```bash
# Frontend
npm run build
npm test

# Backend
cd server
npm run build
npm test
```

All must pass. If anything fails, stop and report.

### Step 3: Check for risky changes

Scan the diff for red flags:

| Check | What to look for | Risk |
|-------|-----------------|------|
| **Schema changes** | Files in `server/drizzle/` | Migrations are irreversible |
| **Auth changes** | Changes to `auth.ts`, `AuthContext.tsx` | Could lock out all users |
| **Environment vars** | New `process.env.*` or `import.meta.env.*` references | Must be set on Render first |
| **Package changes** | `package-lock.json` diffs | New deps need `npm install` on Render |
| **API routes** | New or changed routes | Frontend/backend version mismatch |
| **Admin settings** | Changes to `site_settings` usage | Could affect all users |
| **Breaking changes** | Renamed exports, changed API contracts | May break client/server compat |

### Step 4: Present report

```
## Pre-Deploy Report

Branch: feature/xyz → main
Commits: 3
Files changed: 7

### Test Results
- Frontend build: ✓ pass
- Frontend tests: ✓ 789 passed
- Backend build: ✓ pass
- Backend tests: ✓ 142 passed

### Risk Assessment
- [ ] No schema migrations
- [ ] No auth changes
- [!] New env var: RESEND_API_KEY — must be set on Render before deploy
- [ ] No breaking API changes

### Verdict: Safe to deploy (with 1 action item)
Action: Set RESEND_API_KEY on Render backend before pushing.
```

## Task: Verify Deploy (`verify`)

Run after pushing to main to confirm the deploy succeeded.

### Step 1: Check deploy status

Use Render MCP `list_deploys` for both frontend and backend (limit: 1 each).

Expected: status `live` for the most recent deploy.

### Step 2: Health probes

```bash
curl -s -o /dev/null -w "API: %{http_code} (%{time_total}s)\n" https://terminal-trainer-api.onrender.com/api/health
curl -s -o /dev/null -w "Frontend: %{http_code} (%{time_total}s)\n" https://zero2claude.dev
```

### Step 3: Check error logs

Use Render MCP `list_logs` for the backend:
- `level`: `["error", "fatal"]`
- `limit`: 10
- Time range: last 10 minutes

### Step 4: Report

```
## Deploy Verification

Frontend deploy: ✓ live (2 min ago)
Backend deploy: ✓ live (3 min ago)

Health: API 200 (0.34s), Frontend 200 (0.12s)
Errors since deploy: 0

Verdict: Deploy successful
```

## Task: Rollback (`rollback`)

Guide the user through a rollback. Render doesn't have a one-click rollback, so we use git.

### Step 1: Identify what to rollback to

```bash
git log --oneline -5    # Show recent commits
```

### Step 2: Present rollback options

```
## Rollback Options

1. Revert last commit: `git revert HEAD && git push`
   - Safest — creates a new commit that undoes the change
   - Preserves git history

2. Reset to previous commit: `git reset --hard HEAD~1 && git push --force`
   - ⚠️ Destructive — rewrites history
   - Only use if revert is too complex (e.g., merge conflicts)

3. Redeploy previous build on Render dashboard
   - No git changes needed
   - Temporary — next push will deploy the broken code again
```

### Step 3: Execute (only with user confirmation)

NEVER force-push without explicit user approval. Present the options and wait.

## Task: Deploy History (`history`)

### Step 1: Fetch deploys

Use Render MCP `list_deploys` for both frontend and backend (limit: 5 each).

### Step 2: Present

```
## Deploy History

### Backend (terminal-trainer-api)
| # | Commit | Status | Time |
|---|--------|--------|------|
| 1 | abc1234 — Add peer help | ✓ live | 2h ago |
| 2 | def5678 — Fix forum search | deactivated | 5h ago |
...

### Frontend (terminal-trainer)
| # | Commit | Status | Time |
|---|--------|--------|------|
| 1 | abc1234 — Add peer help | ✓ live | 2h ago |
...
```

## Important Notes

- **Pushes to main auto-deploy.** There is no staging gate. The pre-deploy checklist IS the gate.
- Frontend and backend deploy independently. A backend-only change won't trigger a frontend redeploy.
- Database migrations run automatically on backend deploy (`npm run db:migrate` in Render build command).
- Migrations are irreversible on production. If a migration is wrong, you need a new migration to undo it.
- Render build takes 2-5 minutes typically. The backend restarts after deploy.
- The frontend is a static site on CDN — deploys propagate in seconds after build.
- Feature branches can deploy to staging services if configured on Render (see `terminal-trainer-api-staging` and `terminal-trainer-staging`).
