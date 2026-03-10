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

1. Ask the user whether they want a **standard run** or a **dry run**.

2. Build and run the agent from the repo root:
   - Standard: `cd /Users/itays/dev/training/from-dev-basics-to-claude-code/agent && npm run build && npm start`
   - Dry run: `cd /Users/itays/dev/training/from-dev-basics-to-claude-code/agent && npm run build && DRY_RUN=true npm start`

   Use a **10-minute timeout** since each issue investigation spawns a Claude Code instance.

3. After the run completes, summarize:
   - Number of issues found and processed
   - Decision per issue (issue number, title, decision, confidence)
   - Any PRs created (with URLs)
   - Total API cost
   - Any errors

4. If the user asks to check previous run logs:
   ```bash
   cat /Users/itays/dev/training/from-dev-basics-to-claude-code/agent/logs/triage-$(date +%Y-%m-%d).log
   ```

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

~$0.30-0.40 per issue investigation. Auto-fix adds ~$0.20-0.50. A 5-issue run costs ~$1.50-2.00.
