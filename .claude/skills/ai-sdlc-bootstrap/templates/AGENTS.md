# {{PROJECT_NAME}} — Agent Instructions

> Entry point for AI coding agents: Codex (OpenAI), Antigravity (Google), and any AGENTS.md-compatible tool.
> Claude Code users: read `CLAUDE.md` instead — it adds Claude-specific workflow rules on top of these shared conventions.
>
> **Sync note**: The "Key rules" section below summarises `docs/agents/CONVENTIONS.md`. If you update that file, update the summary here too. Agent config files in this repo: {{AGENT_CONFIG_FILES_LIST}}.

---

## Before starting any work, read these three files

1. **[`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md)** — project context, architecture, tech stack, build commands.
2. **[`docs/agents/CONVENTIONS.md`](docs/agents/CONVENTIONS.md)** — all hard constraints and contribution rules. Non-negotiable.
3. **[`docs/agents/STATUS.md`](docs/agents/STATUS.md)** — current status, what's next, backlog priority order.

---

## Key rules (full detail in `docs/agents/CONVENTIONS.md`)

- **Plan before you code**: For any non-trivial change, write out every file you will create/modify and why, state what you will NOT do, and wait for explicit human approval before writing any implementation code. Silence is not approval.
- **`{{CHECK_COMMAND}}` must pass** before every commit.
- **TDD is mandatory**: write tests before or alongside logic changes, in the same commit.
- **Read before you edit**: read a file before your first edit to it in a session (re-read if it may have changed since), and grep for every call site before changing a function signature or public API.
- **Docs are part of done**: update `docs/agents/STATUS.md`, `docs/CHANGELOG.md`, `docs/issues.md`, `docs/requirements.md`, and `docs/dev-setup.md` (if dependencies/tools changed) in the same commit.
- **Commit via `scripts/agent-commit.sh`**: it adds the agent Co-Authored-By trailer (`{{COAUTHOR_LINE}}`) and lets the post-commit hook log the right author kind in `docs/commit-log.md`. Plain `git commit` will be logged as `manual`.
- **Merge policy**: `{{MERGE_POLICY}}`. See `CONTRIBUTING.md §6`.
- **Before push/merge**: review every `manual` commit in the range — see `CONTRIBUTING.md §10`.

---

## Contribution process

Full rules are in [`CONTRIBUTING.md`](CONTRIBUTING.md). All agents must follow it.

Key checklist before committing:
- [ ] Plan written and approved before implementation
- [ ] Tests written (TDD)
- [ ] `{{CHECK_COMMAND}}` passes
- [ ] Manual test completed (if runtime behaviour changed — see `CONTRIBUTING.md §3`)
- [ ] Docs updated (`docs/agents/STATUS.md`, `CHANGELOG.md`, `issues.md`, `requirements.md`, `dev-setup.md` if deps changed)
- [ ] Repo hygiene files updated where applicable (README, `.gitignore`, CODEOWNERS — see `CONTRIBUTING.md §12`)
- [ ] Commit via `scripts/agent-commit.sh` so the author trailer is set

---

## Architecture boundaries (never cross these)

{{DOMAIN_RULES_BLOCK}}
