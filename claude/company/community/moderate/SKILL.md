---
name: community-moderate
description: Moderate the zero2claude.dev community forum — review flagged content, check for spam, audit moderation rules
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[review|audit|stats] [--period <days>]"
---

# Community Moderation Agent

You are the community moderation agent for **zero2claude.dev**, an interactive web app teaching non-technical people terminal and Claude Code (147 lessons, 14 levels, 200+ students). The app has a community forum with categories, threads, replies, voting, image attachments, and a real-time peer help system.

## What This Is NOT

- This is NOT `/community-engage` -- that measures engagement health and contributor activity.
- This is NOT `/devops-incident` -- that investigates production errors.

Use `/community-moderate` for content quality, spam detection, and moderation rule auditing. Use `/community-engage` for engagement metrics and growth insights.

## Repos and Infrastructure

- **Main app**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/`
- **Backend**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/`
- **Content moderator**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/src/lib/contentModerator.ts`
- **Forum routes**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/src/routes/forum.ts`
- **Admin forum routes**: `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/src/routes/adminForum.ts`

### Service IDs

| Service | Type | ID |
|---------|------|----|
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |

### Database Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `forum_threads` | Thread posts | `id`, `author_id`, `title`, `body`, `image`, `is_pinned`, `is_locked`, `is_deleted`, `vote_score`, `created_at` |
| `forum_replies` | Reply posts | `id`, `thread_id`, `author_id`, `body`, `image`, `is_deleted`, `vote_score`, `created_at` |
| `forum_votes` | Up/downvotes | `id`, `user_id`, `thread_id`, `reply_id`, `value` (+1/-1), `created_at` |
| `forum_categories` | Forum sections | `id`, `name`, `slug`, `is_locked`, `sort_order` |
| `help_requests` | Peer help | `id`, `requester_id`, `helper_id`, `lesson_id`, `message`, `status`, `created_at` |
| `chat_messages` | Help chat | `id`, `help_request_id`, `sender_id`, `content`, `created_at` |
| `users` | All users | `id`, `username`, `display_name`, `role`, `created_at` |

## Arguments

### Subcommand (positional, required)
- `/community-moderate review` -- Review recent posts for content that may have evaded automated moderation
- `/community-moderate audit` -- Audit current moderation rules and suggest improvements
- `/community-moderate stats` -- Moderation statistics and flagged user patterns

### Flags
- `--period <days>` -- Lookback window in days (default: 7)

### Examples
```
/community-moderate review                  # Review last 7 days of posts
/community-moderate review --period 3       # Review last 3 days
/community-moderate audit                   # Audit moderation rules against real content
/community-moderate stats --period 30       # Monthly moderation statistics
```

## Subcommand: Review

Scan recent forum posts for content that may have slipped past the automated moderation pipeline. The automated pipeline (in `contentModerator.ts`) catches obvious profanity, link spam (>5 URLs), and HTML tags, but it cannot catch:
- Leetspeak evasion (e.g., "sh1t", "f\*ck")
- Coded harassment or passive-aggressive language
- Spammers who post rapidly with similar but slightly varied content
- Promotional content without explicit URLs (e.g., "DM me for free crypto tips")
- Off-topic content or low-effort posts that degrade forum quality

### Workflow

#### Step 1: Query recent threads and replies

Use Render MCP `query_render_postgres` with postgres ID `dpg-d6jbi5fgi27c73d2jiv0-a`.

```sql
-- Recent threads (non-deleted)
SELECT
  t.id, t.title, t.body, t.image IS NOT NULL AS has_image,
  t.vote_score, t.is_pinned, t.is_locked, t.is_deleted,
  t.created_at,
  u.username, u.display_name, u.role,
  c.name AS category_name, c.slug AS category_slug
FROM forum_threads t
JOIN users u ON t.author_id = u.id
JOIN forum_categories c ON t.category_id = c.id
WHERE t.created_at > NOW() - INTERVAL '{period} days'
ORDER BY t.created_at DESC
LIMIT 100;
```

```sql
-- Recent replies (non-deleted)
SELECT
  r.id, r.body, r.image IS NOT NULL AS has_image,
  r.vote_score, r.is_deleted, r.created_at,
  u.username, u.display_name,
  t.title AS thread_title, t.id AS thread_id
FROM forum_replies r
JOIN users u ON r.author_id = u.id
JOIN forum_threads t ON r.thread_id = t.id
WHERE r.created_at > NOW() - INTERVAL '{period} days'
ORDER BY r.created_at DESC
LIMIT 200;
```

#### Step 2: Check for spam patterns

```sql
-- Users posting rapidly (>5 posts in 1 hour)
SELECT
  u.username, u.display_name, u.id AS user_id,
  COUNT(*) AS post_count,
  MIN(combined.created_at) AS first_post,
  MAX(combined.created_at) AS last_post
FROM (
  SELECT author_id, created_at FROM forum_threads
  WHERE created_at > NOW() - INTERVAL '{period} days' AND is_deleted = false
  UNION ALL
  SELECT author_id, created_at FROM forum_replies
  WHERE created_at > NOW() - INTERVAL '{period} days' AND is_deleted = false
) combined
JOIN users u ON combined.author_id = u.id
GROUP BY u.id, u.username, u.display_name
HAVING COUNT(*) > 5
  AND (MAX(combined.created_at) - MIN(combined.created_at)) < INTERVAL '1 hour'
ORDER BY post_count DESC;
```

```sql
-- Duplicate or near-duplicate content (same user, same body)
SELECT
  u.username, body, COUNT(*) AS times_posted
FROM (
  SELECT author_id, body FROM forum_threads
  WHERE created_at > NOW() - INTERVAL '{period} days' AND is_deleted = false
  UNION ALL
  SELECT author_id, body FROM forum_replies
  WHERE created_at > NOW() - INTERVAL '{period} days' AND is_deleted = false
) combined
JOIN users u ON combined.author_id = u.id
GROUP BY u.username, body
HAVING COUNT(*) > 1
ORDER BY times_posted DESC;
```

#### Step 3: Check for heavily downvoted content

```sql
-- Posts with negative vote scores (community self-moderation signals)
SELECT 'thread' AS type, t.id, t.title, t.body, t.vote_score, u.username, t.created_at
FROM forum_threads t
JOIN users u ON t.author_id = u.id
WHERE t.vote_score < 0
  AND t.created_at > NOW() - INTERVAL '{period} days'
  AND t.is_deleted = false
UNION ALL
SELECT 'reply' AS type, r.id, t.title, r.body, r.vote_score, u.username, r.created_at
FROM forum_replies r
JOIN users u ON r.author_id = u.id
JOIN forum_threads t ON r.thread_id = t.id
WHERE r.vote_score < -1
  AND r.created_at > NOW() - INTERVAL '{period} days'
  AND r.is_deleted = false
ORDER BY vote_score ASC
LIMIT 20;
```

#### Step 4: Check peer help messages

```sql
-- Recent help request messages and chat messages
SELECT
  hr.id AS request_id, hr.message AS request_message,
  hr.status, hr.created_at,
  u.username AS requester
FROM help_requests hr
JOIN users u ON hr.requester_id = u.id
WHERE hr.created_at > NOW() - INTERVAL '{period} days'
ORDER BY hr.created_at DESC
LIMIT 50;
```

#### Step 5: Analyze and report

Review all fetched content manually. Look for:
1. **Evasion patterns** -- Leetspeak, character substitution, Unicode tricks
2. **Rapid posting** -- Same user flooding threads or replies
3. **Duplicate content** -- Copy-pasted spam across multiple threads
4. **Low-quality content** -- Single-word replies, "bump", off-topic derailing
5. **External links** -- Promotional URLs that are just under the 5-link spam threshold
6. **Downvoted content** -- Posts the community has flagged via votes
7. **Inappropriate help messages** -- Abuse of the peer help system

### Output format

Present findings as a markdown report:

```markdown
## Moderation Review — Last {period} Days

### Summary
- Posts scanned: X threads + Y replies
- Flagged items: Z
- Spam patterns detected: N

### Flagged Content

| # | Type | Author | Content Preview | Reason | Severity |
|---|------|--------|----------------|--------|----------|
| 1 | Thread | @user | "..." | Possible evasion | Medium |
| 2 | Reply  | @user | "..." | Duplicate spam   | High   |

### Rapid Posting Alerts
(table of users posting suspiciously fast)

### Heavily Downvoted Content
(table of community-flagged posts)

### Recommendations
- Specific moderation actions to take (delete, lock, warn user)
- Patterns to add to automated moderation (if recurring)
```

Severity levels:
- **Critical** -- Slurs, threats, or explicit content that evaded the filter. Action needed immediately.
- **High** -- Clear spam or abuse. Should be deleted.
- **Medium** -- Borderline content that needs human judgment (e.g., sarcasm, passive aggression).
- **Low** -- Quality concerns (off-topic, low-effort) -- flag but don't necessarily remove.

## Subcommand: Audit

Analyze the current moderation rules in `contentModerator.ts` and evaluate their effectiveness against actual forum content.

### Workflow

#### Step 1: Read the current moderation code

Read `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/src/lib/contentModerator.ts` to extract:
- The profanity word list (`PROFANITY_WORDS` array)
- The link spam threshold (`MAX_LINKS`)
- The max content length (`maxLength` parameter)
- The HTML stripping regex
- The whitespace normalization rules

#### Step 2: Read the input sanitizer

Read `/Users/itays/dev/training/from-dev-basics-to-claude-code/server/src/lib/inputSanitizer.ts` to understand the prompt injection guard used in the peer help dual pipeline.

#### Step 3: Check for edge cases in actual content

Query real forum content to test against the current rules:

```sql
-- All posts containing URLs (check if link detection is working)
SELECT id, body, 'thread' AS type
FROM forum_threads
WHERE body ~ 'https?://' AND is_deleted = false
UNION ALL
SELECT id, body, 'reply' AS type
FROM forum_replies
WHERE body ~ 'https?://' AND is_deleted = false
LIMIT 50;
```

```sql
-- Longest posts (test max-length effectiveness)
SELECT 'thread' AS type, id, LENGTH(body) AS body_length, LEFT(body, 100) AS preview
FROM forum_threads WHERE is_deleted = false
UNION ALL
SELECT 'reply' AS type, id, LENGTH(body) AS body_length, LEFT(body, 100) AS preview
FROM forum_replies WHERE is_deleted = false
ORDER BY body_length DESC
LIMIT 20;
```

#### Step 4: Evaluate moderation rules

Analyze the profanity list for:
- **Coverage gaps** -- Common evasion patterns not covered (leetspeak, Unicode homoglyphs, character insertion)
- **False positive risk** -- Words that could trigger on legitimate content (e.g., "assess" containing "ass" -- check the word boundary regex handles this)
- **Missing categories** -- Types of abuse not covered (doxxing, solicitation, scam patterns)
- **Threshold review** -- Is MAX_LINKS=5 appropriate? Is maxLength=10000 enough or too generous?

#### Step 5: Report

```markdown
## Moderation Audit Report

### Current Rules Summary

| Rule | Setting | Assessment |
|------|---------|------------|
| Profanity filter | {N} words, word-boundary regex | ... |
| Link spam | >{MAX_LINKS} URLs | ... |
| Max length | {maxLength} chars | ... |
| HTML stripping | Regex-based | ... |
| Whitespace normalization | Collapse 4+ newlines, 3+ spaces | ... |

### Profanity List Analysis
- Words covered: {count}
- Categories: explicit ({n}), slurs ({n}), fraud ({n}), threats ({n})
- Known gaps: [list of evasion patterns not caught]
- False positive risks: [list of legitimate words that might match]

### Recommendations
1. [Specific additions to the profanity list]
2. [Threshold adjustments]
3. [New detection patterns to add]
4. [Structural improvements to the moderation pipeline]
```

## Subcommand: Stats

Generate moderation statistics for the specified period.

### Workflow

#### Step 1: Gather posting volume

```sql
-- Post volume by day
SELECT
  DATE(created_at) AS day,
  COUNT(*) FILTER (WHERE type = 'thread') AS threads,
  COUNT(*) FILTER (WHERE type = 'reply') AS replies
FROM (
  SELECT created_at, 'thread' AS type FROM forum_threads
  WHERE created_at > NOW() - INTERVAL '{period} days'
  UNION ALL
  SELECT created_at, 'reply' AS type FROM forum_replies
  WHERE created_at > NOW() - INTERVAL '{period} days'
) combined
GROUP BY DATE(created_at)
ORDER BY day DESC;
```

#### Step 2: Deleted content (moderation actions)

```sql
-- Deleted threads and replies (moderation removals)
SELECT
  'thread' AS type, t.id, t.title, LEFT(t.body, 100) AS preview,
  u.username, t.created_at
FROM forum_threads t
JOIN users u ON t.author_id = u.id
WHERE t.is_deleted = true
  AND t.created_at > NOW() - INTERVAL '{period} days'
UNION ALL
SELECT
  'reply' AS type, r.id, t.title, LEFT(r.body, 100) AS preview,
  u.username, r.created_at
FROM forum_replies r
JOIN users u ON r.author_id = u.id
JOIN forum_threads t ON r.thread_id = t.id
WHERE r.is_deleted = true
  AND r.created_at > NOW() - INTERVAL '{period} days'
ORDER BY created_at DESC;
```

#### Step 3: Locked and pinned threads

```sql
-- Admin moderation actions
SELECT
  id, title, is_pinned, is_locked, is_deleted,
  created_at, updated_at
FROM forum_threads
WHERE (is_pinned = true OR is_locked = true OR is_deleted = true)
  AND updated_at > NOW() - INTERVAL '{period} days'
ORDER BY updated_at DESC;
```

#### Step 4: Vote patterns (community self-moderation)

```sql
-- Vote distribution
SELECT
  CASE
    WHEN value = 1 THEN 'upvote'
    WHEN value = -1 THEN 'downvote'
  END AS vote_type,
  COUNT(*) AS count
FROM forum_votes
WHERE created_at > NOW() - INTERVAL '{period} days'
GROUP BY value;
```

```sql
-- Users who received the most downvotes
SELECT
  u.username, u.display_name, u.id AS user_id,
  COUNT(*) AS downvotes_received
FROM forum_votes v
JOIN users u ON (
  (v.thread_id IS NOT NULL AND v.thread_id IN (
    SELECT id FROM forum_threads WHERE author_id = u.id
  )) OR
  (v.reply_id IS NOT NULL AND v.reply_id IN (
    SELECT id FROM forum_replies WHERE author_id = u.id
  ))
)
WHERE v.value = -1
  AND v.created_at > NOW() - INTERVAL '{period} days'
GROUP BY u.id, u.username, u.display_name
ORDER BY downvotes_received DESC
LIMIT 10;
```

#### Step 5: Peer help moderation

```sql
-- Help requests by status
SELECT status, COUNT(*) AS count
FROM help_requests
WHERE created_at > NOW() - INTERVAL '{period} days'
GROUP BY status
ORDER BY count DESC;
```

#### Step 6: Report

```markdown
## Moderation Statistics — Last {period} Days

### Volume
| Metric | Count |
|--------|-------|
| Threads created | X |
| Replies posted | Y |
| Total posts | Z |
| Posts per day (avg) | N |

### Moderation Actions
| Action | Count |
|--------|-------|
| Threads deleted | X |
| Replies deleted | Y |
| Threads locked | Z |
| Threads pinned | N |

### Deletion Rate
- Thread deletion rate: X/Y = Z%
- Reply deletion rate: X/Y = Z%
- Overall moderation rate: X/Y = Z%

### Community Self-Moderation (Votes)
| Metric | Count |
|--------|-------|
| Total upvotes | X |
| Total downvotes | Y |
| Downvote ratio | Z% |

### Most Downvoted Users
| Username | Downvotes Received |
|----------|-------------------|
| @user1 | N |
| @user2 | N |

### Daily Volume Breakdown
| Date | Threads | Replies |
|------|---------|---------|
| YYYY-MM-DD | X | Y |

### Peer Help
| Status | Count |
|--------|-------|
| open | X |
| taken | Y |
| resolved | Z |
| cancelled | N |
```

## Important Notes

- **Read-only.** This skill queries data and reads code. It does NOT modify posts, ban users, or change moderation rules. It reports findings for a human to act on.
- All queries use `query_render_postgres` with postgres ID `dpg-d6jbi5fgi27c73d2jiv0-a`. This tool runs read-only transactions.
- The `image` column in threads and replies stores base64 data URIs. Do NOT include the full image data in output -- only note whether an image is present (`has_image`).
- Deleted posts (`is_deleted = true`) are soft-deleted. They remain in the database but are hidden from the forum UI.
- The profanity filter uses word-boundary regex (`\b`), which means "ass" will NOT match "assess" or "class". This is correct behavior -- do not flag it as a false positive risk.
- The content moderation pipeline runs server-side on write endpoints only. Content already in the database was either posted before moderation was added, or it passed the filter at write time.
- Rate limits (in-memory, not in DB): 5 threads/hour, 20 replies/hour per user. These are not queryable from the database -- note this limitation in reports.
- When reporting flagged content, truncate post bodies to 100 characters in tables. Include full text only when specifically discussing a flagged item.
