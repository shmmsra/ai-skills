# ai-skills — Changelog

> Chronological log of what changed in this repo and *why*. The "why" matters more than the "what" — the diff already shows the what.
>
> Update at the end of every session. Newest entries at the top.

---

## 2026-09-30 — AISKL-007: install Copilot skills as native agent skills

**What changed**: `scripts/install.sh` and `scripts/install.ps1` now install the GitHub Copilot target as a full skill directory — `.github/skills/<name>/` (project scope) or `~/.copilot/skills/<name>/` (user scope) — mirroring the Claude Code install (VERSION-aware skip, `--update` overwrite, per-skill `linguist-vendored`). Any legacy `<!-- skill:<name> -->` block the old installer appended to `.github/copilot-instructions.md` is removed on install. Updated agent-menu labels, scope prompt text, README install table, and OVERVIEW.

**Why**: The old installer inlined the SKILL.md body into `.github/copilot-instructions.md`, which Copilot treats as always-on repository instructions — not a skill — so skills never appeared as `/<name>` in Copilot CLI. Supporting files (`reference/`, `templates/`) were also dropped, and user scope silently fell back to project. Copilot CLI discovers skills only in `.github/skills`, `.claude/skills`, `.agents/skills` (project) and `~/.copilot/skills`, `~/.agents/skills` (user); notably it does not read `~/.claude/skills`.

**What was rejected**: installing Copilot user-scope skills into `~/.agents/skills` (shared with other tools, less discoverable as Copilot-specific); symlinking from `~/.claude/skills` (user declined; couples two agents' install state); keeping the `copilot-instructions.md` block alongside the new skill (duplicates the instructions into every prompt).

**What's next**: No follow-up; `skills/**` unchanged, so no `dist` republish needed.

---

## 2026-08-22 — AISKL-005: add vocal-ai skill

**What changed**: Added `skills/vocal-ai/` (SKILL.md, VERSION, README.md, `reference/setup.md`) — a skill that generates speech from text via the local, offline `vocalai` CLI (Chatterbox TTS over ONNX), for use cases like demo-recording narration. The skill orchestrates the upstream `vocal-ai` repo's own `install.sh`/`install.ps1` for first-time setup and updates rather than duplicating that logic, and defaults the binary/model cache to `~/.vocal-ai` (via `VOCALAI_INSTALL_DIR`) so it's fetched once and reused across projects instead of per-repo.

**Why**: The user wanted an agent-usable way to synthesize speech (e.g. voiceovers) without re-deriving the CLI's setup steps every session, and without silently duplicating an installer that vocal-ai already keeps idempotent and version-checked upstream.

**What was rejected**: Vendoring a copy of `install.sh`'s logic inside this repo (would drift from upstream); an ADR (no new architectural pattern — follows the existing SKILL.md + VERSION + README + reference/ shape used by `book-companion`); per-project install location (re-downloads a multi-file model set per repo for no benefit).

**What's next**: No open follow-up; pull the skill via the installer/subtree flow when needed in a consumer repo.

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
