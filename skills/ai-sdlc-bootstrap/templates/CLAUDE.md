# {{PROJECT_NAME}} — Agent Briefing (Claude Code)

> **Before starting any work:**
> - Project context, architecture, tech stack, build commands → [`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md)
> - Current status, what's next, backlog → [`docs/agents/STATUS.md`](docs/agents/STATUS.md)
> - All hard engineering constraints → [`docs/agents/CONVENTIONS.md`](docs/agents/CONVENTIONS.md)

---

## 0. Non-negotiable operating rules

These rules govern how Claude works in this repo. They are collaboration protocol, not style preferences.

### Plan before you code — always wait for explicit approval

For any non-trivial change ({{NONTRIVIAL_DEFINITION}}), you **must**:

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

Posting the diff before the manual test is confirmed is a violation, even when `{{CHECK_COMMAND}}` is green.

### `{{CHECK_COMMAND}}` must pass before every commit — no CI failures

Every commit must leave CI green. The pre-commit hook (`make setup-hooks` after cloning) enforces this locally.

### Commit via `scripts/agent-commit.sh` — never plain `git commit`

When you commit, use `scripts/agent-commit.sh "<message>"`. It:

1. Adds the agent Co-Authored-By trailer (`{{COAUTHOR_LINE}}`) so this commit is recognised as agent-authored.
2. Lets the post-commit hook record the right author kind in `docs/commit-log.md`.

Running plain `git commit` strips you of agent attribution — the commit will be logged as `manual` and require human re-review before it can be pushed/merged.

### Before pushing or merging — review every `manual` commit in range

This repo gates push/merge on §10 of CONTRIBUTING.md. Before doing either:

1. Open `docs/commit-log.md`.
2. For every row tagged `manual` in the push/merge range, run `git show <sha>` and audit it against `docs/agents/CONVENTIONS.md`.
3. Surface any concern to the human. **Never push/merge a manual commit you cannot vouch for.**

### Merge policy

This project enforces `{{MERGE_POLICY}}`. See `CONTRIBUTING.md §6` for the exact contract. Summary:

{{MERGE_POLICY_BLOCK}}

### Related projects

This repo declares relationships with other projects — see [`docs/agents/OVERVIEW.md`](docs/agents/OVERVIEW.md) § Related projects. Before working on anything that touches a related project's domain, read that project's own agent docs first, even if not auto-loaded. See `CONTRIBUTING.md §14`.

---

## 1. Hard constraints (every agent must respect these)

{{DOMAIN_RULES_BLOCK}}

**Universal rules** (apply to every project scaffolded by ai-sdlc-bootstrap):

- **No credentials in code**: API keys go in `.env` only (git-ignored).
- **All decisions get an ADR**: If you're about to change something another agent might wonder about, write an ADR. Template in `docs/decisions/README.md`.
- **Ask before approval-gated operations**: {{APPROVAL_GATES_LIST}}
- **Repo hygiene files stay current**: `README.md`, `LICENSE`, `CODEOWNERS`, `.gitignore`, `docs/dev-setup.md`, IDE configs — update them in the same commit when they go stale. See `CONTRIBUTING.md §12`.

---

## 2. Documentation process

Every agent session that makes significant changes **must** update before committing:

1. **`docs/agents/STATUS.md`** — Update phase table, test counts, and "What's next" if anything completed or changed.
2. **`docs/CHANGELOG.md`** — Add an entry: what changed, *why*, what was rejected, what's next.
3. **`docs/requirements.md`** — Tick completed items, add new planned items.
4. **`docs/issues.md`** — Mark completed issues `DONE`, update `IN PROGRESS`, add newly discovered issues. (For GitHub/JIRA backends, update the external ticket and reference its ID in the commit.)
5. **`docs/decisions/`** — If a significant architectural decision was made, create an ADR (template in `docs/decisions/README.md`).
6. **`docs/manual-testing.md`** — Add manual-test steps for every new feature, CLI flag, UI element, or API route.
7. **`docs/dev-setup.md`** — If you added a dependency, CLI tool, MCP server, skill, or language toolchain, update the install instructions. The reproducibility of onboarding depends on this file.
8. **Repo hygiene** — If a hygiene file went stale (README quick-start, CODEOWNERS, `.gitignore`, IDE recommended extensions), update it. See `CONTRIBUTING.md §12`.

> **Rule**: Stale docs break every subsequent session. Treat doc updates as part of the definition of done.
>
> **Sync note**: If you modify `docs/agents/CONVENTIONS.md`, also update the inline summaries in this file's §1, `AGENTS.md`, and `.cursor/rules/{{PROJECT_SLUG}}.mdc`. All agent config files: {{AGENT_CONFIG_FILES_LIST}}.
