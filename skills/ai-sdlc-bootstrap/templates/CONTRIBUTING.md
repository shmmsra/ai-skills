# Contributing to {{PROJECT_NAME}}

> **AI agents read this first.** This file defines the non-negotiable process for making changes to {{PROJECT_NAME}}. Treat every rule here as a hard constraint, not a suggestion.

---

## Rule 0 — Plan first, wait for approval, then implement

This rule exists before all others. Before writing a single line of implementation code for any non-trivial change ({{NONTRIVIAL_DEFINITION}}):

1. Write out the plan: every file you will create or modify, and why.
2. State what you will **not** do.
3. **Stop. Post the plan. Wait.**
4. Do not proceed until the human responds with explicit approval ("lgtm", "go ahead", "approved", or equivalent).

**"implement X" is not pre-approval of your plan.** It is a task assignment. You must still surface the plan and wait for the human to sign off on your specific approach.

**Silence is not approval.** If the human does not respond, do not proceed.

After implementing:

1. **Write out the manual test plan** (see §3 for the required format) — exact command(s), what to observe, pass/fail criteria.
2. **Post the test plan. Wait.** The human runs the test. Do not proceed until they explicitly confirm ("tested, looks good", "manual test passed", or equivalent). **Silence is not confirmation.**
3. **Show the diff.** Summarise every file modified and why.
4. **Wait for commit approval.** Do not run `git commit` until the human says "lgtm", "commit it", or equivalent.

These four steps are sequential. Posting the diff before the human has confirmed the manual test is a violation of this rule — even if `{{CHECK_COMMAND}}` is green.

---

## Rule 1 — All tests and checks must pass before any commit lands. No exceptions.

This is not a style preference. A commit that breaks `{{CHECK_COMMAND}}` breaks the contract this repository runs on. The regression gates exist precisely because a human (or agent) will not always be watching.

---

## 1. Test-Driven Development (TDD)

### The workflow

1. **Write the failing test first** — or alongside the code if the feature is exploratory, but no later than the same commit.
2. **Run the full suite** (`{{CHECK_COMMAND}}`) — the new test must fail before implementation.
3. **Implement** — minimal code to make the test pass.
4. **Confirm green** — `{{CHECK_COMMAND}}` passes with the new test included.
5. **Commit** — only now.

### What must have tests

Every public function, exported module, CLI command, HTTP route, IPC handler, and external integration. Bug fixes must include a regression test that **reproduces the bug** before the fix.

If you can't write a test for a bug, describe why in the commit message. This is not optional — bugs without tests come back.

### Test framework

This project uses **{{TEST_FRAMEWORK}}**. Run with `{{TEST_COMMAND}}`.

### Naming

- Tests live in `{{TEST_DIRECTORY}}` (see `docs/agents/OVERVIEW.md` for the exact path).
- Test names should describe the invariant in plain English: *"returns null when the input is missing a required field"*, not *"test null case"*.

---

## 2. Pre-commit gate (`{{CHECK_COMMAND}}`)

Before every commit, run:

```bash
{{CHECK_COMMAND}}
```

This runs typecheck (if applicable), linter, and the full test suite.

**Set up the automated git hook once** (after cloning):

```bash
make setup-hooks
```

This installs a `.git/hooks/pre-commit` that runs `{{CHECK_COMMAND}}` automatically on every `git commit`. If any check fails, the commit is aborted. Fix the failure, then commit again.

### Hook bypass policy

`--no-verify` is **forbidden** unless the commit is a docs-only or repo-housekeeping change with zero code modifications. If a hook is failing on legitimate code, fix the code — do not skip the hook.

---

## 3. Manual testing before commit ({{MANUAL_TEST_REQUIRED_TEXT}})

Automated tests verify correctness at the unit and integration level. Manual testing verifies the feature works end-to-end in the actual runtime environment. {{MANUAL_TEST_REQUIRED_TEXT_LONG}}

> **[`docs/manual-testing.md`](docs/manual-testing.md)** is the canonical runbook. It lists exact commands for every feature area. **When you add a new feature, CLI flag, UI element, or API route, update that file in the same commit.**

### What the agent must write out

Before showing the diff and requesting commit approval, the agent must produce an explicit manual test plan in this format:

```
**Test command(s)**:
  <exact shell command(s) to run>

**Setup** (if any):
  <env vars, flags, or preconditions>

**What to observe**:
  <exact log lines, UI state, CLI output, or JSON fields to inspect>

**Pass criteria**:
  <concrete, observable — not "it should work" but "UI shows X", "CLI prints Y", "log contains Z">

**Fail indicators**:
  <symptoms that mean the feature is broken or another feature has regressed>
```

The human runs the test (or confirms it was run). Only after an explicit confirmation does the commit proceed.

---

## 4. Architecture constraints

These are load-bearing rules. Violating them silently breaks the system in ways that only appear at runtime.

{{DOMAIN_RULES_BLOCK}}

---

## 5. Documentation as part of done

A feature or fix is **not done** until these files are updated in the same commit (or a follow-up commit in the same PR):

1. **`docs/agents/STATUS.md`** — update phase table, test counts, "What's next" if anything changed.
2. **`docs/CHANGELOG.md`** — add an entry: what changed, why, what was rejected, what's next.
3. **`docs/requirements.md`** — tick completed items, add new planned items.
4. **`docs/issues.md`** — mark the issue `DONE`, add a row to the **Recently closed** table with the commit hash. Use `pending` as the placeholder before committing; immediately after the commit lands, update the row with the real short hash (`git log --oneline -1`). Never leave `pending` in the table.
5. **`docs/manual-testing.md`** — add test steps for every new feature, CLI flag, UI element, or API route introduced.
6. **`docs/decisions/`** — if an architectural decision was made, create an ADR.

This is not optional cleanup. The next agent to pick up this repo reads these files first. Stale docs make every subsequent session less accurate.

---

## 6. Branch and merge strategy

**Keep history linear.** This repo uses a strict linear history — no merge commits.

### Code-review and merge policy

{{MERGE_POLICY_BLOCK}}

### When merging a feature branch (direct-merge mode)

Use **rebase or cherry-pick**, never `git merge --no-ff`. If `git merge --ff-only` fails, the branch needs to be rebased first.

### `git push` is always manual — no exceptions

**AI agents must never run `git push`.** Pushing is a one-way, externally visible action. It is the human's responsibility.

This rule holds even when the human says "merge it" or "land it" (means commit + merge locally, not push). If the human explicitly types `git push` or says "push to remote", run it. Otherwise, stop after the local merge and report the final commit SHA.

**Before any push or merge to `main`**, the agent must verify that every commit in the range has been agent-reviewed (see §10).

---

## 7. Commit message format

```
<type>(<scope>): <short imperative summary>

<body — what changed and why, not a diff summary>

{{COAUTHOR_LINE}}
```

**Types**: `feat`, `fix`, `test`, `docs`, `refactor`, `ci`, `chore`, `perf`
**Scopes**: project-specific — see recent `git log` for established scopes, or pick a logical module name.

If the change closes a ticket: include the ticket ID — e.g. `feat({{TICKET_PREFIX_LOWER}}-042): add retry logic for timeouts`.

Examples:
- `feat(api): add /health route with version metadata`
- `fix({{TICKET_PREFIX_LOWER}}-017): handle empty response from upstream`
- `test(parser): add coverage for malformed input edge cases`

---

## 8. Approval-gated operations

The following operations **always** require explicit human approval, beyond the standard plan + commit approval:

{{APPROVAL_GATES_BLOCK}}

If you are uncertain whether an operation requires approval, ask. The cost of asking is low.

---

## 9. Running individual test suites

```bash
# Full pre-commit gate
{{CHECK_COMMAND}}

# Tests only
{{TEST_COMMAND}}

# Type check only
{{TYPECHECK_COMMAND}}
```

See `docs/agents/OVERVIEW.md` for per-subpackage commands if the project has multiple build targets.

---

## 10. Commit attribution and the manual-vs-agent commit log

This repo tracks **who authored each commit**: a human directly, or an AI agent. The mechanism is `{{MANUAL_COMMIT_REVIEW}}`. Two artefacts implement it:

- **`scripts/agent-commit.sh`** — the wrapper that AI agents use instead of `git commit`. It appends the agent's `Co-Authored-By` trailer and tags the commit subject internally.
- **`docs/commit-log.md`** — append-only audit log written by the post-commit hook. Each row: short SHA, author kind (`agent` / `manual`), subject line.

### Author kinds

| Kind | How a commit is classified |
|------|----------------------------|
| `agent` | Commit message contains the configured Co-Authored-By trailer (`{{COAUTHOR_LINE}}`) |
| `manual` | Commit message does **not** contain the agent trailer |

### What the agent must do before any push/merge

Before running any externally visible operation (`git push`, opening a PR, merging into `main`):

1. **Scan `docs/commit-log.md`** for any `manual` row in the range you're about to push/merge.
2. For each manual commit: read the diff (`git show <sha>`), verify it does not violate any rule in `docs/agents/CONVENTIONS.md`, doesn't introduce uncovered behaviour, and doesn't break the architecture boundaries.
3. **If review is clean**: proceed.
4. **If review surfaces concerns**: stop, raise the concerns to the human, and wait for an explicit instruction. Do not push/merge a manual commit you cannot vouch for.

The post-commit hook also flags any commit that lacks both a trailer *and* a recognised manual marker — those need human acknowledgement before the next commit can land.

### When this rule is relaxed

If `{{MANUAL_COMMIT_REVIEW}}` was set to `convention-only` at scaffold time, the hook is not installed and there is no `docs/commit-log.md`. The trailer convention still applies for commit attribution, but the gating is informational only.

---

## 11. Commit co-authorship

This project's policy: `{{COAUTHOR_AGENT}}`.

When **yes**, every agent-authored commit ends with:

```
{{COAUTHOR_LINE}}
```

Agents commit via `scripts/agent-commit.sh "<message>"` which adds this trailer automatically. Manual `git commit` invocations by a human do **not** add the trailer — that's how §10 distinguishes the two kinds.

When **no**, no trailer is added. Author kind is then inferred from a `[manual]` / `[agent]` tag on the subject line, set by `scripts/agent-commit.sh` for agents only.

---

## 12. Repository hygiene files — keep them updated

The following files are part of the project's contract with both humans and agents. **Treat them as code**: when a change makes them stale, update them in the same commit.

| File | When to update |
|------|----------------|
| `README.md` | Project description / install / quick-start changes. Always link to `docs/dev-setup.md` for full setup. |
| `LICENSE` | Only if changing license. Document the change in an ADR. |
| `CODEOWNERS` | When ownership of a directory or module changes. |
| `.gitignore` | When adding a new build artefact / cache dir / IDE config that should not be committed. Append, never wholesale-rewrite. |
| `.vscode/`, `.zed/`, etc. | When adding a recommended extension, snippet, or workspace setting that benefits all contributors. |
| `docs/dev-setup.md` | When adding a new dependency, MCP server, skill, language toolchain, or required tool. The reproducibility of onboarding depends on this. |
| `docs/decisions/` | When making an architectural decision another agent might wonder about. See ADR template. |

Stale hygiene files are a documented failure mode of multi-agent SDLCs. Don't let them rot.

---

## 13. Dev environment setup

New contributors (human or agent) bootstrap their environment by following **[`docs/dev-setup.md`](docs/dev-setup.md)**. That document is the single source of truth for:

- Required language toolchains and versions
- Project dependencies (and how to install them)
- Required external tools / CLIs
- MCP servers / agent skills the project depends on
- The `make setup-hooks` step (installs pre-commit + post-commit)
- The first-time `{{CHECK_COMMAND}}` baseline run

If you add a new dependency or tool while working in this repo, update `docs/dev-setup.md` in the same commit. Onboarding the next agent on a fresh clone is the regression test for this file.
