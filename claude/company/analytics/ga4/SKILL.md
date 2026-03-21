---
name: analytics-ga4
description: Analyze GA4 traffic and events for zero2claude.dev — page views, user flow, event tracking audit
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, WebSearch
argument-hint: "[audit|events|traffic] [--fix]"
---

# Analytics GA4 — Event Tracking and Traffic Analysis

Audit, document, and maintain GA4 event tracking for **zero2claude.dev**. This skill scans the codebase for `trackEvent()` calls, compares them against the GTM container configuration, and identifies gaps.

## Key Files

| Asset | Path |
|-------|------|
| Analytics utility | `/Users/itays/dev/training/from-dev-basics-to-claude-code/src/utils/analytics.ts` |
| Analytics tests | `/Users/itays/dev/training/from-dev-basics-to-claude-code/src/utils/analytics.test.ts` |
| GTM container JSON | `/Users/itays/dev/training/from-dev-basics-to-claude-code/gtm-container-import.json` |
| GTM container v2 | `/Users/itays/dev/training/from-dev-basics-to-claude-code/gtm-container-import-v2.json` |
| App repo root | `/Users/itays/dev/training/from-dev-basics-to-claude-code/` |

## GA4 Property

- **Measurement ID:** `G-N61KG4YL3F`
- **GTM Container ID:** `GTM-TDRC2MGR`
- **GA4 Dashboard:** `https://analytics.google.com/analytics/web/` (requires Google account access -- cannot be queried programmatically by this skill)

## Arguments

### Task selector (positional, required)
- `/analytics-ga4 audit` — Compare codebase events against GTM container config. Find orphaned or missing events.
- `/analytics-ga4 events` — List all custom GA4 events with parameters, triggers, and source locations.
- `/analytics-ga4 traffic` — Provide guidance for checking GA4 traffic dashboard (no programmatic access).

### Flags
- `--fix` — Only valid with `audit`. Creates missing GTM tags/triggers for orphaned events and updates the container JSON on a feature branch. Without this flag, audit is read-only.

## Workflow

### Task: `audit`

#### Step 1: Scan the codebase for all tracked events

Use Grep to find every `trackEvent(` call in the `src/` directory:

```
Grep pattern: trackEvent\(
path: /Users/itays/dev/training/from-dev-basics-to-claude-code/src
output_mode: content
```

Parse each call to extract:
- **Event name** (first argument string)
- **Parameters** (second argument object keys)
- **Source file and line number**

Also scan for `trackPageView(` calls (these push `page_view` events).

#### Step 2: Parse the GTM container JSON

Read `/Users/itays/dev/training/from-dev-basics-to-claude-code/gtm-container-import.json` and extract:
- All **tags** of type `gaawe` (GA4 Event tags) — note their `eventName` parameter
- All **triggers** — note their conditions (typically matching on `event` from dataLayer)
- All **variables** — note any custom dataLayer variables

Also check `gtm-container-import-v2.json` if it exists (it may be a newer version).

Build a list of event names that have corresponding GTM tags.

#### Step 3: Cross-reference and report

Compare the two lists:

**Orphaned events** (in code but no GTM tag):
Events fired via `trackEvent()` that have no corresponding GA4 Event tag in the GTM container. These events reach the dataLayer but are never sent to GA4.

**Stale GTM tags** (in GTM but not in code):
GA4 Event tags in the container JSON that are not fired by any `trackEvent()` call in the codebase. These may be leftover from removed features.

**Matched events** (properly configured):
Events that exist in both the codebase and the GTM container.

Present as a report:

```markdown
## GA4 Event Audit

### Matched Events (OK)
| Event Name | GTM Tag | Source File(s) | Parameters |
|------------|---------|----------------|------------|
| forum_thread_create | GA4 - Forum Thread Create | ForumThreadCreateModal.tsx | category_id, has_image |
| ... | ... | ... | ... |

### Orphaned Events (in code, no GTM tag)
| Event Name | Source File(s) | Parameters | Action Needed |
|------------|----------------|------------|---------------|
| home_level_expand | HomeScreen.tsx | level_id | Create GTM tag + trigger |
| ... | ... | ... | ... |

### Stale GTM Tags (in GTM, not in code)
| GTM Tag Name | Event Name | Action Needed |
|--------------|------------|---------------|
| ... | ... | Remove or re-implement |

### Summary
- Total events in code: X
- GTM tags configured: X
- Matched: X
- Orphaned (need GTM tags): X
- Stale (need cleanup): X
```

#### Step 4 (only with `--fix`): Create missing GTM configuration

If `--fix` is specified:

1. **Create a feature branch:**
   ```bash
   cd /Users/itays/dev/training/from-dev-basics-to-claude-code
   git checkout main && git pull
   git checkout -b feature/ga4-event-sync
   ```

2. **For each orphaned event**, add to the GTM container JSON:
   - A new **trigger** that fires when `event` equals the event name
   - A new **GA4 Event tag** (`gaawe` type) that:
     - Uses measurement ID `G-N61KG4YL3F`
     - Sets the `eventName` to match
     - Maps each parameter from the `trackEvent()` call as an event parameter using the corresponding dataLayer variable
   - New **dataLayer variables** for any parameters not already defined

   Follow the existing patterns in the container JSON for tag structure, IDs, and fingerprints. Increment IDs from the highest existing ID.

3. **Write the updated container JSON** back to the file.

4. **Run build and tests** to verify nothing is broken:
   ```bash
   cd /Users/itays/dev/training/from-dev-basics-to-claude-code
   npm run build && npm test
   ```

5. **Commit the changes** on the feature branch. Do NOT push unless the user explicitly asks.

6. **Tell the user** to import the updated container JSON into GTM at:
   `https://tagmanager.google.com/#/container/accounts/6344948341/containers/246703075/workspaces`

Without `--fix`, just present the audit report and suggest running with `--fix` to resolve orphaned events.

---

### Task: `events`

List every GA4 custom event with full details.

#### Step 1: Scan the codebase

Same as audit Step 1 -- find all `trackEvent()` and `trackPageView()` calls.

#### Step 2: Build event catalog

For each unique event name, document:
- **Event name**
- **Parameters** (with types inferred from the call site)
- **Source file(s)** and line number(s)
- **User action** that triggers it (inferred from surrounding code context -- read a few lines around each call)
- **GTM status** (has tag / missing tag -- quick check against the container JSON)

#### Step 3: Present as a catalog

```markdown
## GA4 Event Catalog — zero2claude.dev

### Lesson Events
| Event | Parameters | Triggered By | Source | GTM |
|-------|-----------|-------------|--------|-----|
| `lesson_start` | lesson_id, level_id | Student opens a lesson | LessonView.tsx:93 | ... |
| `lesson_complete` | lesson_id, level_id | Student finishes last section | LessonView.tsx:229 | ... |
| `lesson_skip` | lesson_id, level_id | Student clicks skip | LessonView.tsx:165 | ... |
| `section_advance` | lesson_id, section_index, section_type | Student moves to next section | LessonView.tsx:209 | ... |

### Interactive Component Events
| Event | Parameters | Triggered By | Source | GTM |
|-------|-----------|-------------|--------|-----|
| `quiz_answer` | correct, selected_index | Student answers quiz | Quiz.tsx | ... |
| `fill_in_blank_answer` | correct | Student submits fill-in-blank | FillInBlank.tsx | ... |
| `terminal_command` | command_name | Student runs a terminal command | TerminalStep.tsx | ... |

### Forum Events
| Event | Parameters | Triggered By | Source | GTM |
|-------|-----------|-------------|--------|-----|
| `forum_thread_create` | category_id, has_image | Student creates thread | ForumThreadCreateModal.tsx | ... |
| `forum_reply_create` | thread_id, has_image | Student posts reply | ForumReplyEditor.tsx | ... |
| `forum_vote` | target_type, target_id, action | Student votes | ForumVoteButton.tsx | ... |
| `forum_search` | query, results_count | Student searches forum | ForumSearchBar.tsx | ... |

### Auth Events
| Event | Parameters | Triggered By | Source | GTM |
|-------|-----------|-------------|--------|-----|
| `login` | method | Student logs in | AuthContext.tsx | ... |
| `sign_up` | method | Student registers | AuthContext.tsx | ... |

### Other Events
(TTS, onboarding, palette, achievement, page_view, etc.)
```

Group events by feature area for readability. Fill in the GTM column with "OK" or "MISSING" based on the container JSON check.

---

### Task: `traffic`

Since GA4 data cannot be accessed programmatically without the GA4 Data API (which requires service account credentials not available to this skill), guide the user to check traffic manually.

#### Step 1: Provide dashboard links

```markdown
## GA4 Traffic — Manual Check

### Quick Links
- **GA4 Real-time:** https://analytics.google.com/analytics/web/#/p<PROPERTY_ID>/realtime
- **GA4 Reports:** https://analytics.google.com/analytics/web/#/p<PROPERTY_ID>/reports
- **GTM Workspace:** https://tagmanager.google.com/#/container/accounts/6344948341/containers/246703075/workspaces

### What to Check
1. **Users (7d/30d):** Reports > Life cycle > Acquisition > Overview
2. **Page Views:** Reports > Life cycle > Engagement > Pages and screens
3. **Custom Events:** Reports > Life cycle > Engagement > Events
4. **User Flow:** Reports > Life cycle > Engagement > User engagement
5. **Retention:** Reports > Life cycle > Retention

### Key Custom Events to Monitor
- `lesson_start` / `lesson_complete` — lesson engagement funnel
- `forum_thread_create` / `forum_reply_create` — community engagement
- `sign_up` — conversion tracking
- `ai_onboarding_start` / `ai_onboarding_complete` — onboarding funnel
```

Note: The GA4 property ID is embedded in the measurement ID `G-N61KG4YL3F`. The user needs to find the numeric property ID from their GA4 admin settings to construct direct report URLs.

#### Step 2: Suggest improvements

Based on the current event catalog (run a quick scan of `trackEvent` calls), suggest:
- Events that could benefit from additional parameters
- Funnels that could be defined in GA4 (e.g., sign_up -> ai_onboarding_start -> lesson_start -> lesson_complete)
- Missing events for important user actions (e.g., help_request_create, palette_change_save, profile_image_upload)
- Whether GA4 Explorations could surface useful insights from existing data

## Known Events in the Codebase

This is the current catalog of `trackEvent()` calls as of the last audit. Always re-scan to get the latest -- the code is the source of truth.

| Event Name | Parameters | Source |
|------------|-----------|--------|
| `page_view` | page_path, page_title | analytics.ts (trackPageView) |
| `lesson_start` | lesson_id, level_id | LessonView.tsx |
| `lesson_complete` | lesson_id, level_id | LessonView.tsx |
| `lesson_skip` | lesson_id, level_id | LessonView.tsx |
| `section_advance` | lesson_id, section_index, section_type | LessonView.tsx |
| `quiz_answer` | correct, selected_index | Quiz.tsx |
| `fill_in_blank_answer` | correct | FillInBlank.tsx |
| `terminal_command` | command_name | TerminalStep.tsx |
| `achievement_unlock` | achievement_id, achievement_name | AchievementContext.tsx |
| `login` | method | AuthContext.tsx |
| `sign_up` | method | AuthContext.tsx |
| `forum_thread_create` | category_id, has_image | ForumThreadCreateModal.tsx |
| `forum_reply_create` | thread_id, has_image | ForumReplyEditor.tsx |
| `forum_vote` | target_type, target_id, action | ForumVoteButton.tsx |
| `forum_search` | query, results_count | ForumSearchBar.tsx |
| `tts_play` | section_type, lesson_id | ListenButton.tsx |
| `tts_stop` | section_type, lesson_id, duration_seconds | ListenButton.tsx |
| `palette_change` | palette_id | PalettePicker.tsx |
| `ai_onboarding_start` | (none) | AIOnboarding.tsx |
| `ai_onboarding_complete` | provider | AIOnboarding.tsx |
| `ai_onboarding_skip` | (none) | HomeScreen.tsx |
| `home_level_expand` | level_id | HomeScreen.tsx |

## GTM Container Structure

The GTM container JSON follows this structure:

- **Tags** (`containerVersion.tag[]`): Each tag has a `type` field. GA4 Event tags use type `gaawe`. The GA4 Configuration tag uses type `googtag`.
- **Triggers** (`containerVersion.trigger[]`): Custom event triggers match on `event` from the dataLayer using `type: "CUSTOM_EVENT"` and a `customEventFilter`.
- **Variables** (`containerVersion.variable[]`): DataLayer variables use `type: "v"` (Data Layer Variable) with a `dataLayerVariable` key specifying the variable name to read.

When adding new tags/triggers/variables (`--fix`):
- Increment `tagId`, `triggerId`, `variableId` from the highest existing value
- Generate a unique `fingerprint` (use current timestamp in milliseconds)
- Follow the exact structure of existing entries
- Always set `measurementIdOverride` to `G-N61KG4YL3F` on GA4 Event tags

## Important Notes

- The GTM container JSON is checked into the repo for version control, but the **live GTM container** is managed through the GTM web UI. After updating the JSON with `--fix`, the user must manually import it into GTM.
- All code changes from `--fix` go on a feature branch. **Never commit directly to main.**
- Run `npm run build && npm test` before committing any changes.
- The `trackEvent` function in `analytics.ts` is a thin wrapper around `window.dataLayer?.push()`. It does not validate event names or parameters -- any string is accepted.
- Some events use parameters that are standard GA4 parameters (like `method` for `login`/`sign_up`). These do not need custom dimensions in GA4. Custom parameters (like `lesson_id`, `category_id`) need to be registered as custom dimensions in GA4 admin settings for them to appear in reports.
- There may be two GTM container JSON files (`gtm-container-import.json` and `gtm-container-import-v2.json`). Always check both. The v2 file may be a newer version. Use the most recent one (check `exportTime` in the JSON).
- This skill cannot access GA4 data directly. For actual traffic numbers, the user must check the GA4 dashboard manually or set up the GA4 Data API with service account credentials.
