---
name: run-triage-agent
description: Build and run the self-healing bug triage agent that polls GitHub issues, investigates via Claude Code Agent SDK, and takes autonomous action (close, comment, or create fix PRs)
user-invocable: true
---

# Run Self-Healing Triage Agent

## Overview

The triage agent lives at `agent/` in the repo root. It:
1. Fetches open GitHub issues labeled `bug` + `student-report` (without `triage-processed`)
2. For each issue, spawns a Claude Code instance (read-only) to investigate the codebase
3. Decides: `auto-fixed`, `needs-review`, or `not-a-bug`
4. Acts:
   - **not-a-bug**: Comments explanation, labels `not-a-bug`, closes issue
   - **needs-review**: Comments findings, labels `needs-human-review`
   - **auto-fixed**: Creates fix in isolated git worktree, pushes branch, creates draft PR
5. Labels every processed issue `triage-processed`
6. POSTs run results to server API for admin dashboard + email notifications

## How to Run

### Standard run (real actions on GitHub):
```bash
cd agent && npm run build && npm start
```

### Dry run (logs only, no GitHub side effects):
```bash
cd agent && DRY_RUN=true npm run build && DRY_RUN=true npm start
```

### Dev mode (tsx, no compile step):
```bash
cd agent && npm run dev
```

## Instructions for Claude

When the user invokes this skill:

1. Ask the user which mode they want:
   - **Standard run** — Full triage (processes open issues, spawns Claude Code instances, costs ~$0.30-0.40/issue)
   - **Dry run** — Full triage but logs only, no GitHub side effects
   - **Fixed** — Notify reporters of fixed bugs (lightweight, no Claude Code, no cost)

2. For **standard** or **dry run**, follow the Standard/Dry Run steps below.

3. For **fixed** mode, follow the Fixed Mode steps below.

4. After any run completes, summarize the results.

---

## Standard / Dry Run Mode

1. Build and run the agent from the repo root:
   - Standard: `cd /Users/itays/dev/training/from-dev-basics-to-claude-code/agent && npm run build && npm start`
   - Dry run: `cd /Users/itays/dev/training/from-dev-basics-to-claude-code/agent && npm run build && DRY_RUN=true npm start`

   Use a **10-minute timeout** since each issue investigation spawns a Claude Code instance.

2. After the run completes, summarize:
   - Number of issues found and processed
   - Decision per issue (issue number, title, decision, confidence)
   - Any PRs created (with URLs)
   - Total API cost
   - Any errors

3. If the user asks to check previous run logs:
   ```bash
   cat /Users/itays/dev/training/from-dev-basics-to-claude-code/agent/logs/triage-$(date +%Y-%m-%d).log
   ```

---

## Fixed Mode — Notify reporters of deployed fixes

This mode does NOT build or run the agent. It uses `gh` CLI and the server API directly.

### Step 1: Find closed issues that haven't been notified

```bash
gh issue list \
  --repo itayshmool/from-dev-basics-to-claude-code \
  --state closed \
  --label "bug,student-report" \
  --json number,title,body,labels \
  --limit 100
```

Filter the JSON output to exclude issues that already have the `fix-notified` label (check `labels[].name`).

If no issues remain after filtering, tell the user "No closed bug issues pending notification" and stop.

### Step 2: Parse reporter info from each issue

For each issue, extract reporter email and name from the `body` field:
- **Email**: Match `**Reported by:** username (email@example.com)` — regex: `\*\*Reported by:\*\*\s*\S+\s*\(([^)]+@[^)]+)\)`
- **Name**: Match `**Reported by:** username` — regex: `\*\*Reported by:\*\*\s*(\S+)`

Filter out any issues where email could not be extracted.

Show the user a summary table:
```
Found N closed issues to notify:
  #123 - "Title here" → reporter@example.com (displayName)
  #456 - "Other title" → other@example.com (otherName)
```

Ask the user to **confirm** before sending.

### Step 3: Send notifications via server API

Get the GitHub PAT from the agent `.env` file (not `gh auth token`, which returns an OAuth token that doesn't match the server's PAT):

```bash
source /Users/itays/dev/training/from-dev-basics-to-claude-code/agent/.env

curl -s -X POST https://terminal-trainer-api.onrender.com/api/admin/triage/notify-fixed \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H "Content-Type: application/json" \
  -d '<JSON payload>'
```

Build the JSON payload from the parsed issues:
```json
{
  "issues": [
    { "issueNumber": 123, "title": "...", "reporterEmail": "...", "reporterName": "..." }
  ]
}
```

The server handles idempotency — if an email was already sent for an issue, it returns `skipped`.

### Step 4: Label notified issues

For each issue where the server returned `status: "sent"`, add the `fix-notified` label:

```bash
gh issue edit NUMBER --repo itayshmool/from-dev-basics-to-claude-code --add-label "fix-notified"
```

Do NOT label issues that were `skipped` or `failed`.

### Step 5: Summarize

Report to the user:
- How many notifications were sent, skipped (already notified), or failed
- Which issues were labeled `fix-notified`
- Any errors

---

## Environment

All config is auto-detected. No manual setup needed.

| Variable | Source |
|----------|--------|
| `GITHUB_PAT` | Auto-detected from `gh auth token` |
| `GITHUB_OWNER` / `GITHUB_REPO` | Auto-detected from `git remote get-url origin` |
| `API_URL` | Defaults to `https://terminal-trainer-api.onrender.com` |
| `PROJECT_ROOT` | Defaults to repo root |
| `LOG_DIR` | Defaults to `agent/logs/` |
| `DRY_RUN` | `false` by default, set `true` for safe testing |

Config file: `agent/.env` (overrides auto-detection if set)

## Key Files

| File | Purpose |
|------|---------|
| `agent/src/index.ts` | Entry point: polls issues, orchestrates triage loop |
| `agent/src/config.ts` | Zod-validated config with auto-detection |
| `agent/src/github.ts` | Octokit wrapper (issues, labels, comments, PRs) |
| `agent/src/claudeAgent.ts` | Claude Code Agent SDK: investigate (read-only) + fix (worktree) |
| `agent/src/issueParser.ts` | Parses bug report markdown from issue body |
| `agent/src/reportResults.ts` | POSTs results to server API |
| `agent/src/logger.ts` | File + console logger (daily rotation) |

## Automation

The agent also runs automatically every hour via macOS launchd:
- Plist: `agent/com.zero2claude.triage-agent.plist`
- Logs: `agent/logs/launchd-stdout.log`, `agent/logs/launchd-stderr.log`

## Costs

- **Standard/Dry run**: ~$0.30-0.40 per issue investigation. Auto-fix adds ~$0.20-0.50. A 5-issue run costs ~$1.50-2.00.
- **Fixed mode**: $0 (no Claude Code instances, just API calls)
