---
name: analytics-report
description: Generate student metrics reports for zero2claude.dev — progress, engagement, retention, achievements
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[weekly|monthly|custom] [--preview]"
---

# Analytics Report — Student Metrics

Generate comprehensive student metrics reports for **zero2claude.dev** by querying the production PostgreSQL database via Render MCP.

## Service IDs

| Service | Type | ID |
|---------|------|----|
| Database | PostgreSQL | `dpg-d6jbi5fgi27c73d2jiv0-a` |
| Backend API | Web Service | `srv-d6jbmbp4tr6s739ccvcg` |

## Arguments

### Period selector (positional, default: weekly)
- `/analytics-report` — Weekly report (last 7 days)
- `/analytics-report weekly` — Same as above
- `/analytics-report monthly` — Monthly report (last 30 days)
- `/analytics-report custom` — Prompt the user for a start and end date

### Flags
- `--preview` — Show the SQL queries that would run without executing them. Useful for reviewing what data will be pulled.

## Workflow

### 1. Determine the reporting period

Based on the argument:
- **weekly**: `NOW() - INTERVAL '7 days'` to `NOW()`
- **monthly**: `NOW() - INTERVAL '30 days'` to `NOW()`
- **custom**: Ask the user for start/end dates in `YYYY-MM-DD` format

Store the interval as `PERIOD_START` and `PERIOD_END` for use in all queries below.

### 2. If `--preview`, show all queries and stop

Print each query from Section 3 with a short description of what it measures. Do NOT execute any queries. End with: "Run without `--preview` to execute these queries against the production database."

### 3. Execute queries via Render MCP

Use `query_render_postgres` with `postgresId: "dpg-d6jbi5fgi27c73d2jiv0-a"` for all queries. These are **read-only** queries (the Render MCP tool enforces this).

Run the following queries. Where possible, batch independent queries into parallel MCP calls.

#### A. Student Overview

```sql
-- Total registered students
SELECT COUNT(*) AS total_students FROM users WHERE role = 'student';

-- New signups in period
SELECT COUNT(*) AS new_signups FROM users
WHERE role = 'student' AND created_at >= '<PERIOD_START>';

-- Students with at least one completed lesson in period (active)
SELECT COUNT(DISTINCT user_id) AS active_students FROM progress
WHERE completed = true AND completed_at >= '<PERIOD_START>';
```

#### B. Lesson Completion

```sql
-- Lessons completed in period
SELECT COUNT(*) AS lessons_completed FROM progress
WHERE completed = true AND completed_at >= '<PERIOD_START>';

-- Completion rate by level (lessons completed vs total lessons per level)
SELECT
  l.level_id,
  lv.title AS level_title,
  COUNT(DISTINCT l.id) AS total_lessons,
  COUNT(DISTINCT CASE WHEN p.completed = true THEN p.lesson_id END) AS unique_lessons_completed,
  COUNT(CASE WHEN p.completed = true AND p.completed_at >= '<PERIOD_START>' THEN 1 END) AS completions_in_period
FROM lessons l
JOIN levels lv ON l.level_id = lv.id
LEFT JOIN progress p ON p.lesson_id = l.id
WHERE l.is_published = true
GROUP BY l.level_id, lv.title
ORDER BY l.level_id;
```

#### C. Average Progress

```sql
-- Average lessons completed per active student
SELECT
  ROUND(AVG(lesson_count), 1) AS avg_lessons_per_student
FROM (
  SELECT user_id, COUNT(*) AS lesson_count
  FROM progress WHERE completed = true
  GROUP BY user_id
) sub;

-- Students who completed all lessons in a level (level mastery)
SELECT
  l.level_id,
  lv.title AS level_title,
  COUNT(DISTINCT p.user_id) AS students_mastered
FROM progress p
JOIN lessons l ON p.lesson_id = l.id
JOIN levels lv ON l.level_id = lv.id
WHERE p.completed = true
GROUP BY l.level_id, lv.title
HAVING COUNT(DISTINCT p.lesson_id) = (
  SELECT COUNT(*) FROM lessons WHERE level_id = l.level_id AND is_published = true
)
ORDER BY l.level_id;
```

#### D. Streaks and Engagement

```sql
-- Students with multi-day activity streaks (consecutive days with completions)
-- This finds the longest current streak per student active in the period
WITH daily_activity AS (
  SELECT DISTINCT user_id, DATE(completed_at) AS activity_date
  FROM progress
  WHERE completed = true AND completed_at >= '<PERIOD_START>'
),
streak_groups AS (
  SELECT user_id, activity_date,
    activity_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_date))::int AS streak_group
  FROM daily_activity
),
streaks AS (
  SELECT user_id, COUNT(*) AS streak_length
  FROM streak_groups
  GROUP BY user_id, streak_group
)
SELECT
  COUNT(CASE WHEN streak_length >= 3 THEN 1 END) AS students_3day_streak,
  COUNT(CASE WHEN streak_length >= 7 THEN 1 END) AS students_7day_streak,
  MAX(streak_length) AS longest_streak
FROM (
  SELECT user_id, MAX(streak_length) AS streak_length FROM streaks GROUP BY user_id
) per_user;
```

#### E. Lessons Skipped

```sql
-- Skip rate
SELECT
  COUNT(CASE WHEN skipped = true AND skipped_at >= '<PERIOD_START>' THEN 1 END) AS skipped_in_period,
  COUNT(CASE WHEN completed = true AND completed_at >= '<PERIOD_START>' THEN 1 END) AS completed_in_period
FROM progress;
```

#### F. Forum Activity

```sql
-- Forum activity in period
SELECT
  (SELECT COUNT(*) FROM forum_threads WHERE created_at >= '<PERIOD_START>' AND is_deleted = false) AS new_threads,
  (SELECT COUNT(*) FROM forum_replies WHERE created_at >= '<PERIOD_START>' AND is_deleted = false) AS new_replies,
  (SELECT COUNT(*) FROM forum_votes WHERE created_at >= '<PERIOD_START>') AS new_votes,
  (SELECT COUNT(DISTINCT author_id) FROM forum_threads WHERE created_at >= '<PERIOD_START>' AND is_deleted = false) AS unique_thread_authors,
  (SELECT COUNT(DISTINCT author_id) FROM forum_replies WHERE created_at >= '<PERIOD_START>' AND is_deleted = false) AS unique_reply_authors;
```

#### G. Peer Help

```sql
-- Help requests in period
SELECT
  COUNT(*) AS total_requests,
  COUNT(CASE WHEN status = 'resolved' THEN 1 END) AS resolved,
  COUNT(CASE WHEN status = 'open' THEN 1 END) AS still_open,
  COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled
FROM help_requests
WHERE created_at >= '<PERIOD_START>';
```

#### H. AI Onboarding Adoption

```sql
-- AI onboarding plans generated
SELECT
  COUNT(*) AS total_plans,
  COUNT(CASE WHEN created_at >= '<PERIOD_START>' THEN 1 END) AS plans_in_period
FROM ai_onboarding_plans;

-- AI onboarding generation attempts (including retries)
SELECT COUNT(*) AS generation_attempts,
  SUM(input_tokens + output_tokens) AS total_tokens
FROM ai_onboarding_log
WHERE created_at >= '<PERIOD_START>';
```

#### I. Retention (monthly report only)

Only run this for `monthly` or `custom` periods longer than 14 days:

```sql
-- Week-over-week retention: students active in week 1 who returned in week 2, 3, 4
WITH week1 AS (
  SELECT DISTINCT user_id FROM progress
  WHERE completed = true
    AND completed_at >= '<PERIOD_START>'
    AND completed_at < '<PERIOD_START>'::timestamp + INTERVAL '7 days'
),
week2 AS (
  SELECT DISTINCT user_id FROM progress
  WHERE completed = true
    AND completed_at >= '<PERIOD_START>'::timestamp + INTERVAL '7 days'
    AND completed_at < '<PERIOD_START>'::timestamp + INTERVAL '14 days'
),
week3 AS (
  SELECT DISTINCT user_id FROM progress
  WHERE completed = true
    AND completed_at >= '<PERIOD_START>'::timestamp + INTERVAL '14 days'
    AND completed_at < '<PERIOD_START>'::timestamp + INTERVAL '21 days'
),
week4 AS (
  SELECT DISTINCT user_id FROM progress
  WHERE completed = true
    AND completed_at >= '<PERIOD_START>'::timestamp + INTERVAL '21 days'
    AND completed_at < '<PERIOD_START>'::timestamp + INTERVAL '28 days'
)
SELECT
  (SELECT COUNT(*) FROM week1) AS week1_active,
  (SELECT COUNT(*) FROM week1 w1 JOIN week2 w2 ON w1.user_id = w2.user_id) AS retained_week2,
  (SELECT COUNT(*) FROM week1 w1 JOIN week3 w3 ON w1.user_id = w3.user_id) AS retained_week3,
  (SELECT COUNT(*) FROM week1 w1 JOIN week4 w4 ON w1.user_id = w4.user_id) AS retained_week4;
```

### 4. Format the report

Present results as a structured markdown report. Use this template:

```markdown
# Zero2Claude Student Metrics Report
**Period:** [start date] to [end date] ([weekly/monthly])
**Generated:** [current date and time]

---

## Student Overview
| Metric | Value |
|--------|-------|
| Total registered students | X |
| New signups (period) | X |
| Active students (period) | X |
| Active rate | X% (active / total) |

## Lesson Progress
| Metric | Value |
|--------|-------|
| Lessons completed (period) | X |
| Avg lessons per student (all time) | X |
| Skip rate (period) | X% |

### Completions by Level
| Level | Title | Total Lessons | Unique Completed | Period Completions | Students Mastered |
|-------|-------|---------------|------------------|-------------------|-------------------|
| 0 | ... | 6 | ... | ... | ... |

## Engagement
| Metric | Value |
|--------|-------|
| 3+ day streaks | X students |
| 7+ day streaks | X students |
| Longest streak | X days |

## Forum Activity
| Metric | Value |
|--------|-------|
| New threads | X |
| New replies | X |
| New votes | X |
| Unique posters | X |

## Peer Help
| Metric | Value |
|--------|-------|
| Help requests | X |
| Resolved | X |
| Still open | X |
| Resolution rate | X% |

## AI Onboarding
| Metric | Value |
|--------|-------|
| Total plans (all time) | X |
| Plans generated (period) | X |
| Token usage (period) | X |

## Retention (monthly only)
| Week | Active Students | Retained from Week 1 | Retention Rate |
|------|----------------|----------------------|----------------|
| Week 1 | X | - | - |
| Week 2 | - | X | X% |
| Week 3 | - | X | X% |
| Week 4 | - | X | X% |
```

### 5. Offer follow-up analysis

After presenting the report, suggest:
- "Want me to drill into a specific level's completion funnel?"
- "Want me to identify students who dropped off mid-level?"
- "Want me to compare this period with the previous period?"
- "Want me to find the most popular (and least popular) lessons?"

## Database Schema Reference

Key tables and columns used by this skill:

- **users**: `id`, `role` ('student'|'admin'), `display_name`, `email`, `created_at`
- **progress**: `user_id`, `lesson_id`, `completed` (bool), `completed_at`, `skipped`, `skipped_at`, `section_index`
- **levels**: `id` (int), `title`, `order`, `is_published`
- **lessons**: `id` (varchar like '1.1'), `level_id`, `title`, `order`, `is_published`
- **forum_threads**: `id`, `category_id`, `author_id`, `is_deleted`, `reply_count`, `vote_score`, `created_at`
- **forum_replies**: `id`, `thread_id`, `author_id`, `is_deleted`, `vote_score`, `created_at`
- **forum_votes**: `id`, `user_id`, `thread_id`, `reply_id`, `value`, `created_at`
- **help_requests**: `id`, `requester_id`, `helper_id`, `lesson_id`, `status` ('open'|'resolved'|'cancelled'), `created_at`
- **ai_onboarding_plans**: `id`, `user_id`, `created_at`
- **ai_onboarding_log**: `id`, `user_id`, `input_tokens`, `output_tokens`, `model`, `created_at`

## Important Notes

- All queries are **read-only**. The Render MCP `query_render_postgres` tool wraps queries in a read-only transaction.
- Replace `<PERIOD_START>` with the actual timestamp in RFC3339/ISO format before executing.
- The `progress` table has a unique constraint on `(user_id, lesson_id)` — each student has at most one row per lesson.
- `lesson_id` values look like `'1.1'`, `'2.3'`, `'4b.1'` etc. The numeric prefix before the dot matches the `level_id` (except for sub-levels like 4b, 6b, 6c, 6d, 6e which map to specific integer IDs).
- Forum threads/replies have `is_deleted` soft-delete flag. Always filter with `is_deleted = false` for accurate counts.
- The retention query is expensive. Only run it for monthly or custom periods >= 14 days.
- If a query returns no rows for a metric, display 0 rather than omitting the row.
- The database is on Render's PostgreSQL. If the query times out, suggest narrowing the date range.
