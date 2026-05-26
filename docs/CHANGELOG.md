# ai-skills — Changelog

> Chronological log of what changed in this repo and *why*. The "why" matters more than the "what" — the diff already shows the what.
>
> Update at the end of every session. Newest entries at the top.

---

## 2026-05-26 — AISKL-002: move skills to skills/ and add skills-dist CI

**What changed**: Moved `ai-sdlc-bootstrap/` and `book-companion/` under a `skills/` subdirectory. Added a GitHub Actions workflow (`publish-dist.yml`) that splits `skills/` into a `skills-dist` branch on every push to `main`, giving git-subtree consumers a clean skills-only branch. Updated `scripts/install.sh` and `install.ps1` to discover and copy skills from `skills/<name>/`. Removed the now-unnecessary `cleanup_skills_dir` function from both scripts. Added `make publish-dist` target. Updated README, OVERVIEW.md, and manual-testing.md.

**Why**: Root directory was getting noisy as the skill library grew. The `skills-dist` branch lets subtree consumers pull only skill files without getting repo scaffolding. The CI automation means the dist branch is always in sync with `main` without any manual step.

**What was rejected**: Adding tags per commit to the dist branch for back-referencing — unnecessary noise given that dist commit messages already mirror the originating main commit messages.

**What's next**: AISKL-003 — per-skill `VERSION` file for install no-op detection.

---

## 2026-05-26 — ai-sdlc-bootstrap scaffold

**What changed**: Bootstrapped the AI-driven SDLC workflow on this repo via the `ai-sdlc-bootstrap` skill. Added agent-config layer (CLAUDE.md, AGENTS.md, GEMINI.md), `docs/agents/` triad, `CONTRIBUTING.md`, `docs/issues.md`, ADR template, and pre-commit gate (`make check`).

**Why**: This project will be developed by humans + multiple AI agents across many sessions. Without the agent-config layer and a strict plan/test/commit workflow, every session starts from zero. The scaffold installs the contract.

**What was rejected**: *(none — first scaffold)*

**What's next**: Begin Phase 1 work as tracked in `docs/issues.md`.

---

*Add new entries above this line. Format: `## YYYY-MM-DD — Short title`, followed by `What / Why / Rejected / Next` sub-headings.*
