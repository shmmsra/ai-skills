---
name: ai-skills-project-context
description: What this repo is — a collection of reusable AI agent skills, pure Markdown/shell, no build toolchain
metadata:
  type: project
---

**ai-skills** is a collection of reusable AI agent skills installable into any repo in seconds, targeting Claude Code, Cursor, GitHub Copilot, Gemini CLI, Windsurf, and Aider.

Each skill lives in its own top-level directory containing a `SKILL.md` and optional `templates/`, `reference/` subdirectories.

**Why**: Consumers pull skills via `git subtree add` or the interactive `scripts/install.sh` / `scripts/install.ps1`.

**How to apply**:
- No language toolchain or package manager required — the repo is pure Markdown and shell scripts.
- `make check` syntax-validates all `.sh` files.
- Ticket prefix: `AISKL-NNN` (e.g. `AISKL-001`).
- Merge policy: direct to `main` after local review. No feature branches required.
