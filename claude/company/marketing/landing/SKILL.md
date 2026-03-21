---
name: marketing-landing
description: Update the zero2claude.dev landing page (about.zero2claude.dev) to reflect current product state
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: "[--preview] [--diff-only]"
---

# Marketing Landing Page Agent

You are the landing page agent for **zero2claude.dev**. The marketing landing page lives at `about.zero2claude.dev` in a separate repo.

## Your Job

Keep the landing page in sync with the actual product. When new levels, lessons, features, or student counts change, update the landing page to reflect reality.

## Repos

- **Main app**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/`
- **Landing page**: `/Users/itays/dev/training/zero2claude-landing/`

## Workflow

### 1. Read product context
Read `/Users/itays/dev/training/from-dev-basics-to-claude-code/CLAUDE.md` to get the current state:
- Number of levels and lessons
- Feature list (forum, peer help, AI onboarding, TTS, etc.)
- Student count
- Curriculum table (level names, topics, lesson counts)

### 2. Read current landing page
Read the landing page source at `/Users/itays/dev/training/zero2claude-landing/` to understand what's currently displayed.

### 3. Identify discrepancies
Compare the product state (CLAUDE.md) with what the landing page shows. Look for:
- Outdated lesson/level counts
- Missing features (new features not mentioned)
- Outdated curriculum table
- Stale student count
- Missing or incorrect links

If `--diff-only`: Stop here. Report the discrepancies and exit without making changes.

### 4. Create a feature branch
> **Skip if `--preview`.**

```bash
cd /Users/itays/dev/training/zero2claude-landing
git checkout main && git pull
git checkout -b feature/landing-update
```

### 5. Update the landing page
Make targeted edits to bring the landing page in sync. Only change what's actually stale — don't redesign or restructure.

Common updates:
- Level/lesson count numbers
- Curriculum table rows
- Feature highlight sections
- Student count ("200+ students" → actual number)
- New feature callouts
- Footer links (Terms, Privacy, Blog if they exist)

### 6. Commit on feature branch
Do NOT push unless explicitly asked.

## Arguments

### Flags
- `--preview` — Show what would change without creating a branch or making edits. Outputs a diff-style report.
- `--diff-only` — Only identify discrepancies between CLAUDE.md and the landing page. Don't make any changes. Useful for auditing.

### Examples
```
/marketing-landing                  # Full update: branch, edit, commit
/marketing-landing --diff-only      # Just report what's out of date
/marketing-landing --preview        # Show planned changes without editing
```

## Important Notes

- The landing page is a **separate repo** (`zero2claude-landing`). Do not confuse it with the main app repo.
- The landing page is static HTML/CSS/JS — no React, no build step.
- Only update what's actually stale. Don't redesign or add new sections unless explicitly asked.
- The landing page auto-deploys to Render on push to main, so be careful with pushes.
- If the landing page repo is not cloned locally, inform the user and provide the clone command: `git clone https://github.com/itayshmool/zero2claude-landing /Users/itays/dev/training/zero2claude-landing`
