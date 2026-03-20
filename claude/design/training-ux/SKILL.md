---
name: training-ux
description: UX design specialist for interactive training and educational applications. Use when building lessons, quizzes, tutorials, onboarding flows, learning dashboards, or any interface where the goal is teaching users a skill. Covers learning psychology, progressive disclosure, gamification, accessibility, and engagement patterns specific to education.
user-invocable: true
---

# Training & Education UX Skill

Design and build exceptional interactive training experiences. This skill encodes learning science, instructional design patterns, and UX principles specific to educational applications — from lesson flows to quiz interfaces, progress systems to achievement mechanics.

## When to Use This Skill

- Building lesson/tutorial/course interfaces
- Designing quiz, assessment, or practice components
- Creating progress tracking, dashboards, or streak systems
- Implementing gamification (achievements, XP, badges, leaderboards)
- Building onboarding or guided walkthroughs
- Any UI where the primary goal is **teaching someone something**

## Core Philosophy: Learning-First UX

Training apps are NOT content apps. The interface must actively support the learning process:

1. **Reduce Cognitive Load** — The UI should never compete with the content being learned. Every decorative element, animation, or layout choice must be weighed against: "does this help or hinder comprehension?"
2. **Scaffolded Complexity** — Start simple, layer in complexity. The interface itself should model the pedagogy.
3. **Active Over Passive** — Prefer interactions that require thought (fill-in-blank, drag-sort, click-match) over passive consumption (walls of text, auto-playing video).
4. **Immediate, Meaningful Feedback** — Every learner action gets a response. Not just "correct/incorrect" but *why*.
5. **Safe Failure** — Learners must feel safe to experiment and fail. Never punish mistakes harshly. Show progress despite errors.

## Learning Psychology Principles

### Spacing & Interleaving
- Break content into digestible chunks (5-9 items per section)
- Mix question types within a lesson — don't cluster all quizzes at the end
- Space review of previously learned concepts across sessions

### Retrieval Practice
- Prefer recall over recognition (fill-in-blank > multiple choice when appropriate)
- Test understanding through application, not just memorization
- Use interactive components that require the learner to *produce* answers

### Progressive Disclosure
- Reveal information in layers: concept → example → practice → assessment
- Don't show all lesson content at once — guide through a sequence
- Collapse advanced details behind expandable sections
- Use "Continue" or "Next" gates between sections to create pacing

### Desirable Difficulty
- Challenges should be just beyond current ability (Vygotsky's zone of proximal development)
- Provide hints that scaffold without giving away answers
- Adaptive difficulty when possible — adjust based on performance

### Dual Coding
- Pair text explanations with visual representations (diagrams, interactive trees, terminal previews)
- Use multiple modalities: read, see, do
- Visual metaphors reduce abstraction (e.g., file tree as actual tree, terminal as conversation)

## Interactive Component Design

### Quizzes & Assessments

**Multiple Choice / Quiz:**
- 3-4 options maximum — more causes decision paralysis
- Wrong answers should be plausible (tests understanding, not elimination)
- On submit: highlight correct answer in green, selected wrong in red with explanation
- Never allow re-answering the same question without clearing visual state
- Show a brief explanation for BOTH correct and incorrect answers

**Fill-in-the-Blank:**
- Provide clear context around the blank so learners know what's expected
- Accept reasonable variations (trimmed whitespace, case-insensitive when appropriate)
- Show the correct answer alongside their attempt on incorrect submission
- Use monospace font for code/command blanks, proportional for prose

**Click-Match / Drag-Sort:**
- Clear visual affordance: items look draggable/clickable (shadow, grab cursor, slight lift)
- Smooth animations on connect/reorder (150-250ms ease-out)
- Visual confirmation on correct placement (green pulse, checkmark)
- Allow undo/reset without penalty
- Touch-friendly: minimum 44px touch targets, generous spacing between items

**Interactive Simulations:**
- Sandbox environments where learners can experiment freely
- Clear "expected" vs "actual" output comparison
- Step-by-step mode for complex processes
- Reset to initial state button always visible

### Lesson Flow & Narrative

**Section Sequencing:**
- Each section should have ONE clear learning objective
- Narrative → Concept → Example → Practice pattern works reliably
- Use "section complete" visual indicators (checkmark, progress bar fill)
- Transitions between sections should feel like turning a page, not loading a new app

**Narrative Blocks:**
- Conversational, second-person tone ("You'll notice that..." not "The user will notice...")
- Short paragraphs (2-3 sentences max)
- Highlight key terms on first use (bold or accent color, not both)
- Code snippets inline with explanation, not separated into distant panels

**Terminal / Code Blocks:**
- Distinct visual treatment: dark background, monospace, clear borders
- Syntax highlighting that matches common terminal themes
- Copy button for commands
- Line numbers for multi-line code
- Clearly distinguish input (what to type) from output (what you'll see)

### Progress & Motivation Systems

**Progress Tracking:**
- Show progress at multiple granularities: overall course, current level, current lesson
- Use progress bars, not just numbers ("Lesson 3 of 12" + visual bar)
- Mark completed items distinctly (not just greyed out — use checkmarks, color change)
- Show a "smart continue" that picks up exactly where the learner left off

**Streaks & Consistency:**
- Display current streak prominently but not obnoxiously
- Streak freeze/grace period to prevent demotivation from one missed day
- Weekly/monthly activity heatmap (like GitHub contribution graph)

**Achievements & Badges:**
- Unlock criteria should be clear and achievable (not mysterious)
- Toast notification on unlock — celebratory but not interruptive
- Achievement gallery in profile/dashboard
- Mix milestone achievements (complete Level 3) with behavioral ones (5-day streak, speed achievements)
- Rarity indicators create aspiration without discouraging beginners

**XP / Points (if used):**
- Points should map to meaningful actions (completing lessons, not just clicking)
- Avoid inflation — don't award points for trivial actions
- Show XP gain animation at moment of earning
- Level-up moments should feel significant (modal, animation, new unlock)

## Visual Design for Education

### Layout Principles

**Content Width:**
- Lesson content: 680-720px max width for readability
- Interactive components: can extend wider (up to 960px) for drag-sort, file trees
- Always centered with generous side margins
- Mobile: full-width with 16-24px horizontal padding

**Visual Hierarchy in Lessons:**
```
Level indicator / breadcrumb          (smallest, muted)
Lesson title                          (large, bold, accent)
Section heading                       (medium, semi-bold)
Narrative text                        (base size, readable)
Interactive component                 (visually distinct zone)
Feedback / explanation                (slightly smaller, muted bg)
Navigation (prev/next)                (bottom, fixed or sticky)
```

**The "Learning Surface":**
- Lesson content area should feel like a distinct surface — slightly elevated, card-like
- Clear separation from navigation chrome, sidebar, header
- Calm background that doesn't fatigue during long study sessions
- Warm dark themes reduce eye strain for extended learning

### Color in Education

**Semantic Color Usage:**
- Green = correct, complete, success, positive feedback
- Red/Coral = incorrect, error (but never harsh — use warm reds)
- Amber/Gold = hint, warning, partial credit, "almost there"
- Blue = informational, neutral highlight, links
- Accent color = brand, primary actions, current progress
- Muted/Grey = disabled, locked, not-yet-available

**Feedback Colors Must Be Accessible:**
- Don't rely on color alone — always pair with icons (checkmark, X, warning triangle)
- Ensure 4.5:1 contrast ratio minimum for feedback text
- Color-blind safe: red/green distinction must have shape/icon backup

### Typography for Learning

**Reading Comfort is Paramount:**
- Body text: 16-18px, 1.6-1.75 line-height (more generous than typical apps)
- Short line lengths: 60-75 characters per line
- Sufficient paragraph spacing: 1.25-1.5em
- Left-aligned text (never justified — uneven word spacing harms reading)

**Code/Terminal Typography:**
- Monospace: 14-16px with 1.5 line-height
- Use a font with clear character distinction: `0` vs `O`, `1` vs `l` vs `I`
- Recommended: JetBrains Mono, Fira Code, Source Code Pro, Monaco
- Tab width: 2 spaces for display

**Headings:**
- Clear size steps between heading levels
- Use the brand/display font for lesson titles
- Section headings can use the same font at smaller weight/size
- Don't go deeper than H3 within lesson content

### Animation & Transitions

**Purposeful Motion:**
- Section transitions: subtle slide or fade (200-300ms)
- Correct answer: brief green pulse/highlight (300ms)
- Wrong answer: gentle shake + red highlight (400ms, not aggressive)
- Achievement unlock: celebratory animation (confetti, glow) — 1-2 seconds max
- Progress bar fill: smooth animated transition (500ms ease-out)
- Drag/drop: follow cursor with slight lag for natural feel

**Motion Restraint:**
- Reduce motion for `prefers-reduced-motion` users
- No looping animations during content reading
- No animation that blocks the learner from proceeding
- Loading states: skeleton screens over spinners when possible

## Accessibility for Education

Training apps must be MORE accessible than typical apps — learners come from all backgrounds and abilities.

### WCAG 2.1 AA Minimum
- 4.5:1 contrast for body text, 3:1 for large text and UI components
- All interactive elements keyboard-navigable (Tab, Enter, Space, Arrow keys)
- Focus indicators visible and high-contrast
- All images have alt text; decorative images use `alt=""`

### Education-Specific Accessibility
- Quiz options navigable by keyboard (arrow keys between options, Enter to select)
- Drag-and-drop has keyboard alternative (select + move with arrows, or click-to-place)
- Terminal simulations have screen-reader-friendly output announcements
- Progress updates announced to screen readers (aria-live regions)
- Timed activities have generous timeouts or no time pressure by default
- Text resizing up to 200% without layout breaking

### Cognitive Accessibility
- Clear, simple language (avoid jargon until it's been taught)
- Consistent navigation — same place, same behavior, every lesson
- Predictable interaction patterns — don't change how quizzes work mid-course
- Error messages that explain what went wrong AND what to do next

## Responsive Design for Learning

### Mobile Learning
- Touch targets: minimum 44x44px, ideally 48x48px
- Drag-and-drop: convert to tap-to-select on mobile (dragging on small screens is frustrating)
- Code blocks: horizontal scroll with clear scroll indicator, or wrap with line numbers
- Fixed bottom navigation bar for prev/next lesson
- Collapsible sidebar for level/lesson navigation

### Tablet
- Split view potential: lesson content left, interactive component right
- Larger touch targets than mobile aren't needed — standard sizing works
- Can show more progress context (sidebar + content)

### Desktop
- Sidebar navigation for level/lesson browsing
- Wider interactive components (side-by-side comparisons, larger file trees)
- Keyboard shortcuts for power users (N = next section, P = previous, H = hint)

## Anti-Patterns to Avoid

- **Wall of Text** — Break it up. If a section is more than 3 paragraphs without interaction, add one.
- **Mystery Meat Navigation** — Always show where the learner is (level, lesson, section) and where they're going.
- **Premature Assessment** — Don't quiz on concepts not yet taught. Sequence matters.
- **Harsh Failure States** — "WRONG!" in red caps is hostile. Use "Not quite — here's why..." with explanation.
- **Infinite Scroll Lessons** — Break into clear sections with gates. Scrolling through a 20-section lesson is overwhelming.
- **Decoration Over Function** — Fancy backgrounds and animations that slow down the experience or distract from content.
- **Hidden Progress** — If the learner can't tell how far along they are, motivation drops.
- **Forced Linear Progression Without Escape** — Let advanced learners skip ahead or test out of sections they know.
- **Auto-advancing** — Never move to the next section automatically. Let the learner control pacing.
- **Modal Overload** — Don't use modals for lesson content. Modals are for confirmations and achievements only.

## Implementation Checklist

When building a training interface, verify:

- [ ] Each lesson section has ONE clear learning objective
- [ ] Interactive components appear every 2-4 narrative sections
- [ ] Feedback on every learner action (correct, incorrect, partial)
- [ ] Progress visible at all times (level, lesson, section)
- [ ] Keyboard navigation works for all interactive components
- [ ] Mobile-friendly: touch targets, no hover-only interactions, readable text
- [ ] Color is never the sole indicator (always paired with icon/text)
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Content width optimized for reading (680-720px)
- [ ] "Continue where I left off" works reliably
- [ ] Achievement/feedback moments feel rewarding, not annoying
- [ ] Error states guide the learner toward the correct answer
