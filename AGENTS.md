# ai-skills — Agent Instructions

> Entry point for AI coding agents: Codex (OpenAI) and any AGENTS.md-compatible tool.
> Claude Code users: read `CLAUDE.md` instead — it adds Claude-specific workflow rules on top of these shared conventions.
>
> **Sync note**: The "Key rules" section below summarises `docs/agents/CONVENTIONS.md`. If you update that file, update the summary here too. Agent config files in this repo: CLAUDE.md, AGENTS.md, GEMINI.md.

---

## Before starting any work, read these three files

1. **[`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md)** — project context, architecture, tech stack, build commands.
2. **[`docs/agents/CONVENTIONS.md`](docs/agents/CONVENTIONS.md)** — all hard constraints and contribution rules. Non-negotiable.
3. **[`docs/agents/STATUS.md`](docs/agents/STATUS.md)** — current status, what's next, backlog priority order.

---

## Key rules (full detail in `docs/agents/CONVENTIONS.md`)

- **Plan before you code**: For any non-trivial change, write out every file you will create/modify and why, state what you will NOT do, and wait for explicit human approval before writing any implementation code. Silence is not approval.
- **`make check` must pass** before every commit.
- **Docs are part of done**: update `docs/agents/STATUS.md`, `docs/CHANGELOG.md`, `docs/issues.md`, `docs/requirements.md`, and `docs/manual-testing.md` (if install/runtime behaviour changed) in the same commit.
- **Merge policy**: direct merge after local review. No feature branches required. Linear history — rebase or `git merge --ff-only`.
- **Never `git push`**: pushing is always the human's call.

---

## Contribution process

Full rules are in [`CONTRIBUTING.md`](CONTRIBUTING.md). All agents must follow it.

Key checklist before committing:
- [ ] Plan written and approved before implementation
- [ ] `make check` passes
- [ ] Manual test completed (if runtime/install behaviour changed — see `CONTRIBUTING.md §3`)
- [ ] Docs updated (`docs/agents/STATUS.md`, `CHANGELOG.md`, `issues.md`, `requirements.md`)
- [ ] Repo hygiene files updated where applicable (README, `.gitignore` — see `CONTRIBUTING.md §10`)

---

## Architecture boundaries (never cross these)

*(no project-specific domain constraints defined — see `docs/agents/CONVENTIONS.md` §3 as they accumulate)*
