# {{PROJECT_NAME}} — Antigravity / Gemini Agent Instructions

> Google Antigravity / Gemini agent entry point. Extends `AGENTS.md` with Antigravity-specific context.
> Read `AGENTS.md` and the `docs/agents/` files before starting any work — they contain the full conventions and constraints.
>
> **Sync note**: This file contains Antigravity-specific notes only — no duplicated rule summaries. If you add a new agent tool to this repo, create a thin adapter and add it to the list in `AGENTS.md`.

---

## Before starting any work

1. **[`AGENTS.md`](AGENTS.md)** — shared rules for all agents (plan/test/commit workflow, architecture boundaries)
2. **[`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md)** — project context and architecture
3. **[`docs/agents/CONVENTIONS.md`](docs/agents/CONVENTIONS.md)** — all hard constraints
4. **[`docs/agents/STATUS.md`](docs/agents/STATUS.md)** — current status and backlog

---

## Antigravity-specific notes

**Plan → Execute → Verify alignment**: {{PROJECT_NAME}} requires an explicit planning step before any non-trivial implementation. This maps naturally onto Antigravity's Plan phase. Do not skip the planning step even when the Execute phase suggests proceeding — explicit human approval ("lgtm", "go ahead", or equivalent) is required before writing implementation code.

**Multi-agent mode**: If using Antigravity's parallel agent feature, each agent must read `docs/agents/CONVENTIONS.md` independently. Architecture boundary rules apply to every agent — one agent cannot authorise another to cross a boundary.

**Verify phase gate**: `{{CHECK_COMMAND}}` is the required gate for the Verify phase. Do not mark a task complete until it passes cleanly. If it fails, diagnose and fix — do not bypass.

**Commit attribution**: Use `scripts/agent-commit.sh "<message>"` to commit. It adds the configured Co-Authored-By trailer (`{{COAUTHOR_LINE}}`) and lets the post-commit hook record the commit as agent-authored in `docs/commit-log.md`. Plain `git commit` logs as `manual` and gates the next push.

**Merge policy**: `{{MERGE_POLICY}}`. Before any push/merge, review every `manual` commit in the range — see `CONTRIBUTING.md §10`.

**Dev environment**: New tools / MCPs / dependencies you introduce must be reflected in `docs/dev-setup.md` in the same commit.
