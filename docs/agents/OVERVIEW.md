# ai-skills — Project Overview

> Canonical reference for project context, architecture, tech stack, and build commands.
> Read before asking architecture questions or evaluating new libraries/frameworks.

---

## What is this project?

**ai-skills** — A collection of reusable AI agent skills for Claude Code, Cursor, GitHub Copilot, Gemini CLI, Windsurf, and Aider.

**Owner**: Shivam Mishra
**AI-first SDLC**: Designed to be built by humans and multiple AI agents across many sessions. Every significant decision and status change is committed to this repo so agents never need manual context transfer.

---

## Architecture in 30 seconds

Each skill is a self-contained directory under `skills/`. A `SKILL.md` defines the skill body (instructions, context, templates). Install scripts (`scripts/install.sh`, `scripts/install.ps1`) let consumers pull any skill into their own repo for any supported agent. A `skills-dist` branch (auto-published by CI on every push to `main`) exposes only the skill directories — no repo meta files — for clean `git subtree` consumption.

```
ai-skills/
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md               ← skill body (Claude Code reads this)
│       └── templates/, reference/ ← supporting files (Claude Code-specific)
└── scripts/
    ├── install.sh             ← macOS/Linux interactive installer
    └── install.ps1            ← Windows PowerShell installer
```

Consumers pull skills via `git subtree add` into `.claude/skills/` (Claude Code), `.cursor/rules/` (Cursor), `.github/copilot-instructions.md` (Copilot), etc.

---

## Key decisions (quick reference)

Full ADRs in [`docs/decisions/`](../decisions/). Read the ADR before changing anything related to that decision.

| # | Decision | Short rationale |
|---|----------|-----------------|
| [ADR-001](../decisions/0001-adopt-ai-sdlc.md) | Adopt the ai-sdlc-bootstrap workflow | Plan-first, TDD-enforced, docs-as-done, multi-agent compatible |

*Add new rows as ADRs accumulate.*

---

## Tech stack

| Layer | Tech | Key files |
|-------|------|-----------|
| Language(s) | Markdown, Shell, MDC/Cursor rules | — |
| Testing | (none — docs/scripts repo; validated manually) | `docs/manual-testing.md` |
| CI | (none) | — |
| Build | Makefile | `Makefile` |

---

## Build and run

```bash
make check        # pre-commit gate — syntax-checks all shell scripts
make setup-hooks  # one-time: installs pre-commit hook
```

**First-time setup**: clone the repo, run `make setup-hooks` once to wire the pre-commit hook. No dependencies beyond `bash` and `make`.

---

## Repository layout

```
.
├── README.md                   # Project description + install + AI-SDLC pointer
├── LICENSE                     # MIT
├── .gitignore
├── CLAUDE.md                   # Claude Code adapter → docs/agents/
├── AGENTS.md                   # Codex/OpenAI adapter → docs/agents/
├── GEMINI.md                   # Gemini CLI adapter → docs/agents/
├── CONTRIBUTING.md             # Workflow + merge policy + commit conventions
├── Makefile                    # make check, make setup-hooks, make publish-dist
├── skills/                     # All skill directories live here
│   └── <skill-name>/
│       ├── SKILL.md
│       └── templates/, reference/
├── docs/
│   ├── agents/                 # AGENT-CRITICAL: OVERVIEW.md, CONVENTIONS.md, STATUS.md
│   ├── decisions/              # ADRs
│   ├── CHANGELOG.md
│   ├── requirements.md
│   ├── issues.md
│   └── manual-testing.md
├── scripts/
│   ├── install.sh              # macOS/Linux interactive installer
│   ├── install.ps1             # Windows PowerShell installer
│   └── setup-hooks.sh          # Installs pre-commit hook
└── .github/workflows/
    └── publish-dist.yml        # Auto-publishes skills-dist branch on push to main
```

*Update this tree as the project grows. Agents read it to navigate.*

---

## Further reading

External docs / wikis that were used to inform this scaffold:

*(none — README is sufficient)*
