# AI Skills for Claude Code

28 custom skills for software engineering, design, DevOps, and workflow automation.

## Quick Start

```bash
git clone https://github.com/itayshmool/ai-skills.git
cd ai-skills
./install.sh
```

This creates symlinks from `~/.claude/skills/` into this repo.
Changes in the repo are instantly available in Claude Code.

To remove: `./uninstall.sh`

## Skills

### Modes (5)

Generic work modes usable in any project.

| Skill | Command | Description |
|-------|---------|-------------|
| architect | `/architect` | System design, patterns, scalability, technical decisions |
| debug | `/debug` | Hypothesis-driven systematic debugging |
| developer | `/developer` | Senior developer mode with strict TDD |
| product | `/product` | Product manager — requirements, priorities, value delivery |
| reviewer | `/reviewer` | Code review — bugs, security, testing, maintainability |

### Design (9)

UI/UX, frontend, and visual design.

| Skill | Command | Description |
|-------|---------|-------------|
| frontend-design | `/frontend-design` | Distinctive, production-grade frontend interfaces |
| design-audit | `/design-audit` | Systematic UI/UX audit with phased implementation plans |
| training-ux | `/training-ux` | UX specialist for educational and training applications |
| modern-css | `/modern-css` | Modern CSS features (Container Queries, View Transitions, etc.) |
| typography | `/typography` | Professional typography rules for screen-based text |
| relationship-design | `/relationship-design` | AI-first interfaces with memory, trust, and relationships |
| bencium-controlled-ux-designer | `/bencium-controlled-ux-designer` | Expert UI/UX guidance for accessible interfaces |
| bencium-impact-designer | `/bencium-impact-designer` | High-impact, production-grade frontend design |
| bencium-innovative-ux-designer | `/bencium-innovative-ux-designer` | Innovative, creative frontend interface design |

### DevOps (4)

Infrastructure, deployment, and system operations.

| Skill | Command | Description |
|-------|---------|-------------|
| render-expert | `/render-expert` | Render infrastructure audit, costs, health, and management |
| monitor | `/monitor` | Zero2Claude production health monitoring |
| google-play-publisher | `/google-play-publisher` | Google Play Store publishing lifecycle |
| iterm-setup | `/iterm-setup` | iTerm2 + Oh My Zsh + Powerlevel10k setup |

### Workflows (3)

Multi-step automated processes.

| Skill | Command | Description |
|-------|---------|-------------|
| feature-dev | `/feature-dev` | Guided feature development with codebase exploration |
| pr-review-toolkit | `/pr-review-toolkit:review-pr` | Comprehensive PR review with specialized agents |
| screenshot | `/screenshot` | Screenshot processor — vision/OCR analysis, markdown notes |

### Project-Specific (4)

Skills tied to a specific codebase.

| Skill | Command | Description |
|-------|---------|-------------|
| add-backend | `/add-backend` | Scaffold a new LLM backend for multi-bark-pack |
| domains-api-developer | `/domains-api-developer` | Domain registrar API integration expert |
| lesson-writer | `/lesson-writer` | Zero2Claude curriculum lesson writer |
| run-triage-agent | `/run-triage-agent` | Zero2Claude bug triage — polls GitHub issues, investigates, acts |

### Utilities (3)

System tools and workspace automation.

| Skill | Command | Description |
|-------|---------|-------------|
| voice | `/voice` | Voice input — record and transcribe via Whisper (Hebrew + English) |
| gdrive-fixer | `/gdrive-fixer` | Audit and organize a messy Google Drive |
| gphoto-fixer | `/gphoto-fixer` | Audit and organize Google Photos |

## Repo Structure

```
claude/
├── modes/            # 5 — generic work modes
├── design/           # 9 — UI/UX/frontend
├── devops/           # 4 — infrastructure
├── workflows/        # 3 — multi-step automation
├── project-specific/ # 4 — codebase-tied
└── utilities/        # 3 — system tools
```

Categories are for repo organization only. The install script flattens
them into `~/.claude/skills/` via symlinks (Claude Code only scans the
top level).

## Adding a New Skill

1. Create `claude/<category>/<skill-name>/SKILL.md`
2. Run `./install.sh`
3. The skill is immediately available.

## How Sync Works

Symlinks, not copies:

```
~/.claude/skills/architect  →  <repo>/claude/modes/architect/
~/.claude/skills/voice      →  <repo>/claude/utilities/voice/
```

Edit files in the repo and they're instantly live in Claude Code.
