# ai-skills

A collection of Claude Code custom skills for software engineering workflows.

## Skills

| Skill | Description |
|-------|-------------|
| **architect** | System design mode — focuses on patterns, scalability, and technical decisions |
| **debug** | Hypothesis-driven debugging with systematic investigation |
| **developer** | Senior developer mode with strict TDD (red-green-refactor) workflow |
| **product** | Product manager mode — requirements clarity, priorities, and value delivery |
| **reviewer** | Code review mode — bugs, security, testing, and maintainability |
| **frontend-design** | Create distinctive, production-grade frontend interfaces with high design quality |
| **feature-dev** | Guided end-to-end feature development with codebase exploration and architecture focus |
| **pr-review-toolkit** | Comprehensive PR review using specialized agents (comments, tests, errors, types, quality) |
| **add-backend** | Scaffold a new LLM backend for multi-bark-pack |
| **domains-api-developer** | Domain registrar API integration expert for new provider implementations |
| **iterm-setup** | Install and configure iTerm2 with Oh My Zsh, Powerlevel10k, and dev plugins |

## Usage

These skills are automatically available as slash commands in Claude Code when this repo is configured. Invoke them with:

```
/architect
/debug
/developer
/product
/reviewer
/frontend-design
/feature-dev
/review-pr
```

## Structure

```
claude/
├── add-backend/SKILL.md
├── architect/SKILL.md
├── debug/SKILL.md
├── developer/SKILL.md
├── domains-api-developer/SKILL.md
├── feature-dev/commands/feature-dev.md
├── frontend-design/SKILL.md
├── frontend-design-plugin/SKILL.md
├── iterm-setup/SKILL.md
├── pr-review-toolkit/commands/review-pr.md
├── product/SKILL.md
└── reviewer/SKILL.md
```
