# ai-skills — Agent Briefing (Claude Code)

> **Before starting any work:**
> - Project context, architecture, tech stack, build commands → [`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md)
> - Current status, what's next, backlog → [`docs/agents/STATUS.md`](docs/agents/STATUS.md)
> - All hard engineering constraints → [`docs/agents/CONVENTIONS.md`](docs/agents/CONVENTIONS.md)

---

## 0. Non-negotiable operating rules

These rules govern how Claude works in this repo. They are collaboration protocol, not style preferences.

### Plan before you code — always wait for explicit approval

For any non-trivial change (any new file, OR more than one file modified, OR any change touching architecture/install script/template structure), you **must**:

1. Write out your plan: every file you will create or modify, and why.
2. State what you will **not** do.
3. **Stop. Do not write a single line of implementation code.**
4. Wait for the human to explicitly approve with words like "lgtm", "go ahead", "approved", or equivalent.
5. Only then implement.

> **"Silence is not approval."** Presenting a plan and immediately proceeding — even if the human said "implement X" — is a violation. "Implement X" is a task assignment, not pre-approval of your specific approach.

### After implementing: manual test → diff → commit approval (in that order)

1. **Write and post the manual test plan** — exact command(s), what to observe, pass/fail criteria. See `CONTRIBUTING.md §3`.
2. **Wait for the human to confirm** — "tested, looks good" or equivalent. Silence is not confirmation. **Do not show the diff yet.**
3. **Show the diff** — summarise every file changed and why.
4. **Wait for commit approval** — "lgtm", "commit it", or equivalent before running `git commit`.

Posting the diff before the manual test is confirmed is a violation, even when `make check` is green.

### `make check` must pass before every commit — no failures

Every commit must leave the pre-commit gate green. The pre-commit hook (`make setup-hooks` after cloning) enforces this locally.

### Never run `git push` — it's always the human's call

Even when the human says "merge it" or "land it", that means commit locally — not push. If they explicitly say "push to remote", do it. Otherwise stop at the local commit and report the SHA.

### Merge policy

This project uses **direct merge after local review**. No feature branches required. All work goes directly to `main` after local review and commit approval. Linear history only — rebase or `git merge --ff-only`.

---

## 1. Hard constraints (every agent must respect these)

*(no project-specific domain constraints defined — see `docs/agents/CONVENTIONS.md` §3 as they accumulate)*

**Universal rules** (apply to every project scaffolded by ai-sdlc-bootstrap):

- **No credentials in code**: API keys go in `.env` only (git-ignored).
- **All decisions get an ADR**: If you're about to change something another agent might wonder about, write an ADR. Template in `docs/decisions/README.md`.
- **Repo hygiene files stay current**: `README.md`, `LICENSE`, `.gitignore`, `docs/decisions/` — update them in the same commit when they go stale. See `CONTRIBUTING.md §10`.

---

## 2. Documentation process

Every agent session that makes significant changes **must** update before committing:

1. **`docs/agents/STATUS.md`** — Update phase table, test counts, and "What's next" if anything completed or changed.
2. **`docs/CHANGELOG.md`** — Add an entry: what changed, *why*, what was rejected, what's next.
3. **`docs/requirements.md`** — Tick completed items, add new planned items.
4. **`docs/issues.md`** — Mark completed issues `DONE`, update `IN PROGRESS`, add newly discovered issues.
5. **`docs/decisions/`** — If a significant architectural decision was made, create an ADR (template in `docs/decisions/README.md`).
6. **`docs/manual-testing.md`** — Add manual-test steps for every new feature, CLI flag, or install behaviour.

> **Rule**: Stale docs break every subsequent session. Treat doc updates as part of the definition of done.
>
> **Sync note**: If you modify `docs/agents/CONVENTIONS.md`, also update the inline summaries in this file's §1 and `AGENTS.md`. All agent config files: CLAUDE.md, AGENTS.md, GEMINI.md.
