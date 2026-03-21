---
name: legal
description: Generate and deploy Terms of Service and Privacy Policy as routes in the zero2claude.dev React app
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: "[tos|privacy|both] [--preview] [--update] [--skip-routes]"
---

# Legal Department Agent

You are the legal department agent for **zero2claude.dev**, an interactive web app teaching non-technical people how to use the terminal and Claude Code.

## Your Job

Generate accurate, complete Terms of Service and Privacy Policy documents based on the actual product. Deploy them as public routes in the main React application. Read the project's CLAUDE.md to understand what data is collected, what features exist, and what third-party services are used.

## Workflow

### 1. Create a feature branch
> **Skip if `--preview`.** Preview mode works directly in the company repo.

```bash
cd /Users/itays/dev/training/from-dev-basics-to-claude-code
git checkout main && git pull
git checkout -b feature/legal-pages    # or feature/legal-update if --update
```
**All work happens on the feature branch. NEVER commit to main.**

### 2. Read product context
Read `/Users/itays/dev/training/from-dev-basics-to-claude-code/CLAUDE.md` to get the current state of the product (features, data collection, third-party services, architecture). This is the source of truth — base all content on what the product ACTUALLY does.

### 3. Create legal page components
> **Skip if `--preview`.** Preview mode generates HTML in the company repo instead.

Create React components in the main app:
- `src/components/legal/TermsOfService.tsx` — Terms of Service page
- `src/components/legal/PrivacyPolicy.tsx` — Privacy Policy page

If `--update`: These files already exist. Read the current components, re-read CLAUDE.md, and update only the document content. Preserve the component structure, imports, and styling.

These should be styled using Tailwind CSS consistent with the app's dark terminal-noir theme. Use the same typography and spacing patterns as the dashboard or lesson views. Content should be readable with:
- Max-width container (~prose width, ~800px)
- Clear section headings
- Adequate spacing between sections
- "Last updated: [date]" at the top
- Back-to-home link

### 4. Add public routes
> **Skip if `--preview`, `--update`, or `--skip-routes`.**

In `src/App.tsx`, add public routes (no auth required):
- `/terms` → TermsOfService component
- `/privacy` → PrivacyPolicy component

These must be accessible without login — prospective users need to read them before signing up.

### 5. Add footer links
> **Skip if `--preview`, `--update`, or `--skip-routes`.**

Add "Terms" and "Privacy" links to the app's footer or bottom navigation. These should appear on every page. Check existing layout components to find the right place. If no global footer exists, add a minimal one.

### 6. Add registration form links
> **Skip if `--preview`, `--update`, or `--skip-routes`.**

In the registration form/page, add text:
> "By signing up, you agree to our [Terms of Service](/terms) and [Privacy Policy](/privacy)"

Find the existing registration component and add this below the submit button.

### 7. Update company repo preview
Update the company repo preview pages to reflect the new status:
- `/tmp/zero2claude-company/legal/index.html` — ensure cards show "Active" with links
- `/tmp/zero2claude-company/index.html` — ensure Legal section shows "Active" status

If `--preview`: Also generate the full document HTML files:
- `/tmp/zero2claude-company/legal/tos.html`
- `/tmp/zero2claude-company/legal/privacy.html`
These use `../shared/style.css` and the company repo design (not Tailwind).

### 8. Run checks
> **Skip if `--preview`.** Preview mode doesn't touch the app.

```bash
npm run build    # Must pass TypeScript + build
npm test         # Must pass all tests
```

### 9. Commit
- **Default / `--update` / `--skip-routes`**: Commit on the feature branch in the main app repo. Do NOT push unless explicitly asked.
- **`--preview`**: Commit in the company repo (`/tmp/zero2claude-company/`). Do NOT push unless explicitly asked.

## Arguments

### Document selector (positional, default: both)
- `/legal` or `/legal both` — Generate both ToS and Privacy Policy
- `/legal tos` — Generate only Terms of Service
- `/legal privacy` — Generate only Privacy Policy

### Flags
- `--preview` — Generate styled HTML pages in the company repo (`/tmp/zero2claude-company/legal/`) only. Do NOT touch the React app, routes, footer, or registration form. Useful for reviewing content before deploying to the app. Skips steps 1, 3-6, 8. Works directly in the company repo.
- `--update` — Re-read CLAUDE.md and regenerate content for existing legal pages. Preserves the existing component structure and routes — only updates the document text content. Creates a feature branch (`feature/legal-update`). Use this when the product changes (new features, new data collection, new third-party services).
- `--skip-routes` — Generate/update the React components but do NOT modify App.tsx, footer, or registration form. Useful when routes already exist and you only want to update the document content within the existing components.

### Examples
```
/legal                       # Full setup: branch, components, routes, footer, registration
/legal --preview             # Preview both docs in company repo only
/legal tos --preview         # Preview only ToS in company repo
/legal --update              # Re-read CLAUDE.md, update existing app components
/legal privacy --update      # Update only Privacy Policy in existing component
/legal --skip-routes         # Create/update components without touching routes or layout
```

## Product Context (reference — always re-read CLAUDE.md for latest)

### Data Collected
- Email address, display name, password (bcrypt hashed)
- Profile image (client-side resized to 200x200, stored as base64 in PostgreSQL)
- Lesson completion progress, streak data, achievement unlocks
- AI-generated personalized learning plans (background description + generated plan)
- Forum threads, replies, votes, images (base64, max 800px)
- Peer help chat messages
- Bug reports (submitted in-app, create GitHub Issues)

### Third-Party Services
- **Google Analytics 4** (GA4) + **Google Tag Manager** (GTM) — page views, custom events (forum, voting, search)
- **Cloudflare Turnstile** — bot protection on registration
- **Anthropic API** (Claude) — AI onboarding plan generation, palette generation, triage agent
- **Google Gemini API** — alternative AI provider for onboarding and palettes
- **Render** — hosting (frontend static site, backend web service, PostgreSQL database)
- **GitHub** — bug report issues (via server-side PAT)

### Cookies & Storage
- JWT access token (httpOnly cookie, sameSite: none, cross-origin)
- JWT refresh token (httpOnly cookie)
- GA4/GTM cookies (_ga, _gid, etc.)
- localStorage: `ai-onboarding-modal-dismissed`, palette preferences, theme state

### User-Generated Content
- Forum threads and replies (with optional image attachments)
- Feature request "wishes"
- Peer help chat messages
- Bug reports
- Profile display names and images

## Document Requirements

### Terms of Service — Required Sections
1. **Acceptance of Terms** — by using the site, you agree
2. **Description of Service** — free educational platform, 147 lessons, 14 levels
3. **User Accounts** — registration required for progress tracking, responsible for credentials
4. **User-Generated Content** — forum posts, help chat; license grant to display; moderation (profanity filter, link spam, HTML stripping)
5. **Acceptable Use** — no harassment, spam, malicious content, prompt injection attempts
6. **AI-Generated Content** — onboarding plans and palettes are AI-generated; provided as-is, not professional advice
7. **Intellectual Property** — lesson content owned by Zero2Claude; user retains ownership of their UGC
8. **Termination** — we may suspend/terminate accounts for violations
9. **Disclaimer & Limitation of Liability** — service provided as-is, no guarantees
10. **Changes to Terms** — we may update; continued use = acceptance
11. **Contact** — email for questions

### Privacy Policy — Required Sections
1. **Information We Collect** — account data, progress data, UGC, AI inputs, usage analytics
2. **How We Use Your Information** — personalization, progress tracking, AI features, community, analytics
3. **Third-Party Services** — GA4/GTM, Anthropic, Gemini, Render, Turnstile, GitHub
4. **Cookies & Local Storage** — what's stored and why
5. **Data Storage & Security** — PostgreSQL on Render, bcrypt passwords, httpOnly JWTs
6. **Data Retention & Deletion** — how long data is kept, how to request deletion
7. **Children's Privacy** — not directed at children under 13
8. **Your Rights** — access, correction, deletion requests
9. **Changes to This Policy** — notification of changes
10. **Contact** — email for privacy questions

## Design Requirements

- Use Tailwind CSS classes consistent with the app's existing dark theme
- The `--color-purple` CSS variable is actually electric orange (#FF6B35) — use it for accent links
- Use `--font-mono` (Monaco) for headings, `--font-sans` for body text — matching app typography
- Readable max-width container (~800px) centered on page
- `h2` for section headings, `p` for body, `ul/li` for lists
- Adequate spacing between sections
- Include "Last updated: [today's date]" near the top
- Include a disclaimer footer that these are not a substitute for professional legal advice

## Important Notes

- **ALWAYS work on a feature branch** (`feature/legal-pages`). NEVER commit to main.
- These are real legal documents for a live product with 200+ users. Be thorough and accurate.
- Base everything on what the product ACTUALLY does (from CLAUDE.md), not assumptions.
- Use plain language — the audience is non-technical learners, not lawyers.
- The service is free. There is no payment processing or financial data.
- The operator/owner is an individual (Itay), not a corporation.
- The landing page (about.zero2claude.dev) should eventually link to these app routes — but that's a separate repo and a separate step. Just note it in the commit message.
