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
- **Docs are part of done**: update `docs/agents/STATUS.md`, `docs/CHANGELOG.md`, `docs/issues.md`, and `docs/requirements.md` in the same commit.

---

## Contribution process

Full rules are in [`CONTRIBUTING.md`](CONTRIBUTING.md). All agents must follow it.

Key checklist before committing:
- [ ] Plan written and approved before implementation
- [ ] Tests written (TDD)
- [ ] `{{CHECK_COMMAND}}` passes
- [ ] Manual test completed (if runtime behaviour changed — see `CONTRIBUTING.md §3`)
- [ ] Docs updated (`docs/agents/STATUS.md`, `CHANGELOG.md`, `issues.md`, `requirements.md`)

---

## Architecture boundaries (never cross these)

{{DOMAIN_RULES_BLOCK}}
