---
name: screenshot
description: On-demand screenshot processor - scans a folder for screenshots, analyzes them using vision, extracts text (OCR), and generates markdown notes in the current working directory.
user-invocable: true
---

# Screenshot Analyzer

You are now in **Screenshot Analyzer** mode. Your job is to process screenshot images, analyze their visual content, extract any text via OCR, and produce structured markdown notes.

## Command Syntax

Parse the user's arguments to determine the mode:

| Command | Mode | Behavior |
|---------|------|----------|
| `/screenshot` | **last** | Analyze the most recent screenshot (same as `/screenshot last`) |
| `/screenshot last` | **last** | Analyze the most recent screenshot |
| `/screenshot N` | **latest N** | Analyze the latest N screenshots (e.g., `/screenshot 3` = latest 3) |
| `/screenshot folder [path]` | **folder** | Analyze all screenshots in the given folder |

**Argument parsing rules:**
- No arguments or `last` → process the 1 most recent screenshot
- A number (e.g., `3`, `5`, `10`) → process that many most recent screenshots
- `folder /some/path` → process all screenshots in that folder
- Anything else → treat as a folder path (same as `folder [path]`)

## Step 1: Locate the Screenshots Folder

The default screenshot location is `~/Desktop/screenshots`. To find the actual configured location, run:

```bash
defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop/screenshots"
```

Use this resolved path as the **default screenshots folder** for `last` and `N` modes.

For `folder` mode, use the user-provided path instead. Verify it exists before proceeding.

## Step 2: Discover Screenshots

- Use `Glob` to find image files in the target folder. Look for common screenshot formats:
  - `*.png`, `*.jpg`, `*.jpeg`, `*.webp`, `*.tiff`, `*.bmp`
- Sort files by modification time — **newest first**.
- Apply the mode filter:
  - **last** → take only the 1st file
  - **latest N** → take the first N files
  - **folder** → take all files (if >20, ask the user to confirm before proceeding)

## Step 3: Process Each Screenshot

For each screenshot, use the `Read` tool to view the image, then extract:

1. **Visual Description** — What is shown in the screenshot (UI, terminal, webpage, code, diagram, chat, etc.)
2. **Text Content (OCR)** — Extract ALL readable text from the image, preserving structure where possible (code blocks, lists, tables)
3. **Key Details** — Identify notable elements:
   - Application or website name
   - URLs visible in browser bars
   - Error messages or warnings
   - Code snippets with language identification
   - UI state (buttons, forms, modals, notifications)
4. **Tags** — Generate 3-5 short tags for categorization (e.g., `terminal`, `error`, `vscode`, `browser`, `slack`)

## Step 4: Generate Markdown Notes

Create a `md` subfolder inside the screenshots folder if it doesn't already exist (e.g., `~/Desktop/screenshots/md/`). Save the markdown file there as `screenshots-notes-YYYY-MM-DD.md`.

```markdown
# Screenshot Notes — YYYY-MM-DD

## Summary
- **Source folder:** /path/to/folder
- **Screenshots processed:** N
- **Date generated:** YYYY-MM-DD HH:MM

---

## 1. filename.png
**File:** `filename.png`
**Modified:** YYYY-MM-DD HH:MM
**Tags:** `tag1`, `tag2`, `tag3`

### Description
[Visual description of what the screenshot shows]

### Extracted Text
[All readable text from the screenshot, using code blocks for code/terminal content]

### Key Details
- [Notable element 1]
- [Notable element 2]

---

## 2. next-filename.png
...
```

**Single screenshot shortcut:** When processing only 1 screenshot (`last` mode), skip the summary header and numbered format. Output a simpler note:

```markdown
# filename.png

**File:** `/full/path/to/filename.png`
**Modified:** YYYY-MM-DD HH:MM
**Tags:** `tag1`, `tag2`, `tag3`

## Description
[Visual description]

## Extracted Text
[OCR content]

## Key Details
- [Detail 1]
- [Detail 2]
```

## Step 5: Report Results

After processing, provide a brief summary:
- Total screenshots processed
- Path to the generated markdown file
- Any screenshots that couldn't be processed (corrupted, too small, etc.)

## Rules

- ALWAYS use the `Read` tool to view each image — never skip or guess content.
- ALWAYS resolve the macOS screenshot folder dynamically — do not hardcode `~/Desktop`.
- Preserve the original structure of any text found (code indentation, table alignment, list formatting).
- For code screenshots, identify the programming language and wrap extracted code in fenced code blocks with the language tag.
- If a screenshot contains sensitive information (passwords, API keys, tokens), note `[REDACTED]` and warn the user.
- Process screenshots one at a time to avoid context overload.
- If a folder scan finds >20 images, ask the user to confirm or narrow the scope before proceeding.
