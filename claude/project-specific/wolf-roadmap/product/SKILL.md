---
name: wolf-product
description: The Wolf product roadmap — manage features, user stories, prioritization, and product vision
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__google-drive__createGoogleSheet, mcp__google-drive__getGoogleSheetContent, mcp__google-drive__updateGoogleSheet, mcp__google-drive__appendSpreadsheetRows, mcp__google-drive__getSpreadsheetInfo, mcp__google-drive__createGoogleDoc, mcp__google-drive__readGoogleDoc, mcp__google-drive__updateGoogleDoc
argument-hint: "<command> [args]"
---

# Wolf Product — Product Roadmap

Product management for **The Wolf** — AI-native org transformation platform. Define what to build, for whom, and why.

## Product Context

**The Wolf** helps organizations understand their structure, identify dysfunction, and generate remediation plans using dual-agent AI analysis.

### Core User Journey (Today)
1. **Upload** org data (CSV) → column mapping + tree building
2. **Explore** org tree (virtualized, searchable)
3. **Analyze** — Wolf agent identifies issues, Mirror agent challenges
4. **Consensus** — 7 rules validate/contest insights
5. **Fix** — Fixer agent generates phased remediation plans
6. **Export** — PDF reports with scope-aware filenames

### Navigation (Chapters I-IX)
- I: Upload
- II: Org Tree
- III: Performance Data
- IV: Context Documents
- V: Analysis Config
- VI: Run Analysis
- VII: Insights
- VIII: Focus Analysis
- IX: Fix Plans

## Commands

### `vision`
Display the current product vision and strategic priorities.

**Usage:** `/wolf-product vision`

Read CLAUDE.md and recent git history to synthesize:
- What the product does today
- Who the target users are
- What the next strategic priorities should be
- What's missing for product-market fit

### `features`
Manage the feature backlog from a product perspective.

**Usage:**
- `/wolf-product features` — list all planned features with priorities
- `/wolf-product features add "<name>" --user "<persona>" --problem "<what they struggle with>" [--priority high|medium|low]`
- `/wolf-product features prioritize` — re-rank features using ICE scoring (Impact × Confidence × Ease)
- `/wolf-product features spec <id>` — generate a product spec for a feature

### `story`
Write a user story with acceptance criteria.

**Usage:** `/wolf-product story "<as a [user], I want [goal], so that [reason]>"`

**Output format:**
```
## User Story

**As a** [persona]
**I want to** [action]
**So that** [value]

### Acceptance Criteria
- [ ] Given [context], when [action], then [result]
- [ ] ...

### Out of Scope
- [explicitly excluded items]

### UX Notes
- [interaction patterns, Pulp Fiction design system alignment]

### Dependencies
- [API endpoints needed, schema changes, etc.]
```

### `personas`
Define and manage user personas.

**Usage:**
- `/wolf-product personas` — list defined personas
- `/wolf-product personas add "<name>" --role "<role>" --pain "<main pain point>"`

**Default personas for The Wolf:**

| Persona | Role | Pain Point |
|---------|------|-----------|
| **The CHRO** | Chief HR Officer | Can't see org dysfunction patterns across 10k+ employees |
| **The Consultant** | External org advisor | Spends weeks manually analyzing org charts and performance data |
| **The VP** | Division leader | Doesn't know which teams are siloed, bloated, or misaligned |
| **The Analyst** | HR/People analytics | Lacks AI-powered tooling to validate hypotheses about org health |

### `gaps`
Identify product gaps — what's missing from the user journey.

**Usage:** `/wolf-product gaps`

Walk through each chapter (I-IX) and identify:
- Friction points (where users might get stuck)
- Missing features (what they'd expect but don't find)
- UX issues (inconsistencies, dead ends, unclear flows)
- Data gaps (what data would make insights better)

### `compete`
Competitive landscape analysis.

**Usage:** `/wolf-product compete [--search]`

Analyze positioning against:
- Traditional org chart tools (Visier, Orgvue, ChartHop)
- AI analytics platforms (Eightfold, Gloat)
- Consulting approaches (McKinsey 7-S, etc.)

What's The Wolf's unique advantage? (Dual-agent validation, open-source, AI-native)

### `metrics`
Define and track product success metrics.

**Usage:**
- `/wolf-product metrics` — show defined metrics
- `/wolf-product metrics add "<metric>" --target "<value>" --measure "<how>"`

**Default product metrics:**

| Metric | Target | How to Measure |
|--------|--------|---------------|
| Upload → Analysis completion | >80% | Datasets with at least one completed analysis |
| Insight validation rate | >60% | VALIDATED / total insights |
| Fix plan generation rate | >50% | Analyses with fix plans generated |
| Time to first insight | <5 min | Upload timestamp → first insight timestamp |
| PDF export usage | >30% | Analyses with at least one PDF download |

### `release`
Plan a release.

**Usage:** `/wolf-product release "<version>" --theme "<release theme>"`

Generates a release plan:
- Feature list (from completed backlog items)
- User-facing changelog
- Migration notes (if schema changes)
- Rollout plan

## Product Principles

1. **AI does the heavy lifting** — users upload data, AI finds the problems
2. **Trust through transparency** — dual-agent validation shows users WHY an insight matters
3. **Actionable, not academic** — every insight leads to a concrete fix plan
4. **Pulp Fiction personality** — the product has attitude (Wolf = Harvey Keitel's fixer persona)
5. **Multi-tenant by default** — every feature must work for isolated tenants

## Conventions

- Features are described from the user's perspective, not the engineer's
- Every feature needs a persona (who benefits?)
- Priorities use ICE scoring: Impact (1-10) × Confidence (1-10) × Ease (1-10)
- Specs live in Google Docs, linked from the roadmap sheet
- Release themes give a narrative to each version (e.g., "The Cleanup" for data quality improvements)
