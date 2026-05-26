# Contributing to ai-skills

> **AI agents read this first.** This file defines the non-negotiable process for making changes to ai-skills. Treat every rule here as a hard constraint, not a suggestion.

---

## Rule 0 — Plan first, wait for approval, then implement

This rule exists before all others. Before writing a single line of implementation code for any non-trivial change (any new file, OR more than one file modified, OR any change touching architecture/API/IPC boundaries):

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

These four steps are sequential. Posting the diff before the human has confirmed the manual test is a violation of this rule — even if `make check` is green.

---

## Rule 1 — All checks must pass before any commit lands. No exceptions.

This is not a style preference. A commit that breaks `make check` breaks the contract this repository runs on.

---

## 1. Pre-commit gate (`make check`)

Before every commit, run:

```bash
make check
```

This runs a shell-script syntax check across all `.sh` files.

**Set up the automated git hook once** (after cloning):

```bash
make setup-hooks
```

This installs a `.git/hooks/pre-commit` that runs `make check` automatically on every `git commit`. If any check fails, the commit is aborted. Fix the failure, then commit again.

### Hook bypass policy

`--no-verify` is **forbidden** unless the commit is a docs-only or repo-housekeeping change with zero code modifications. If a hook is failing on legitimate code, fix the code — do not skip the hook.

---

## 2. TDD

This repo contains scripts and templates, not traditional application code. For any new shell script or installer logic:

1. Write the test scenario in `docs/manual-testing.md` first (what command to run, what to observe, pass criteria).
2. Implement.
3. Run the manual test and confirm it passes.
4. Run `make check` (syntax validation).
5. Commit only then.

---

## 3. Manual testing before commit (required for runtime-affecting changes)

Automated checks verify syntax. Manual testing verifies the feature works end-to-end in the actual runtime environment. For any change that affects how a script runs, how an install flow works, or how a skill behaves when invoked, the agent must write an explicit manual test plan and wait for the human to run it before proceeding to the commit step.

> **[`docs/manual-testing.md`](docs/manual-testing.md)** is the canonical runbook. **When you add a new feature, CLI flag, or install behaviour, update that file in the same commit.**

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
  <concrete, observable — not "it should work" but "CLI prints Y", "log contains Z">

**Fail indicators**:
  <symptoms that mean the feature is broken or another feature has regressed>
```

The human runs the test (or confirms it was run). Only after an explicit confirmation does the commit proceed.

---

## 4. Architecture constraints

*(no project-specific domain constraints defined — add them here as the project matures)*

---

## 5. Documentation as part of done

A feature or fix is **not done** until these files are updated in the same commit (or a follow-up commit):

1. **`docs/agents/STATUS.md`** — update phase table, test counts, "What's next" if anything changed.
2. **`docs/CHANGELOG.md`** — add an entry: what changed, why, what was rejected, what's next.
3. **`docs/requirements.md`** — tick completed items, add new planned items.
4. **`docs/issues.md`** — mark the issue `DONE`, add a row to the **Recently closed** table with the commit hash.
5. **`docs/manual-testing.md`** — add test steps for every new feature, CLI flag, or install behaviour introduced.
6. **`docs/decisions/`** — if an architectural decision was made, create an ADR.

This is not optional cleanup. The next agent to pick up this repo reads these files first. Stale docs make every subsequent session less accurate.

---

## 6. Branch and merge strategy

**Keep history linear.** This repo uses a strict linear history — no merge commits.

### Code-review and merge policy

Code review is done locally:
1. The agent writes the implementation, posts the diff, and waits for explicit human approval ("lgtm", "commit it").
2. Once approved, the agent commits locally. The human pushes when ready.
3. **No feature branches required.** All work commits directly to `main` after local review.
4. If a branch is opened for experimentation, it must be rebased (not merged with `--no-ff`) before landing.

### When merging a feature branch

Use **rebase or cherry-pick**, never `git merge --no-ff`. If `git merge --ff-only` fails, the branch needs to be rebased first.

### `git push` is always manual — no exceptions

**AI agents must never run `git push`.** Pushing is a one-way, externally visible action. It is the human's responsibility.

This rule holds even when the human says "merge it" or "land it" (means commit + merge locally, not push). If the human explicitly types `git push` or says "push to remote", run it. Otherwise, stop after the local commit and report the final commit SHA.

---

## 7. Commit message format

```
<type>(<scope>): <short imperative summary>

<body — what changed and why, not a diff summary>
```

**Types**: `feat`, `fix`, `test`, `docs`, `refactor`, `ci`, `chore`, `perf`
**Scopes**: pick a logical module name (e.g. `install`, `ai-sdlc-bootstrap`, `book-companion`, `docs`).

If the change closes a ticket: include the ticket ID — e.g. `feat(install): aiskl-042 add --dry-run flag`.

Examples:
- `feat(ai-sdlc-bootstrap): add discovery phase reference doc`
- `fix(install): handle repos with no .gitattributes`
- `docs(contributing): add commit message examples`

---

## 8. Approval-gated operations

*(no approval-gated operations defined for this project — all operations use the standard plan + commit workflow)*

If you are uncertain whether an operation requires extra approval, ask. The cost of asking is low.

---

## 9. Commit conventions

No agent/human distinction is tracked in this repo — commits are just commits. Use plain `git commit` with the message format from §7. No special wrapper scripts or trailers required.

---

## 10. Repository hygiene files — keep them updated

The following files are part of the project's contract with both humans and agents. **Treat them as code**: when a change makes them stale, update them in the same commit.

| File | When to update |
|------|----------------|
| `README.md` | New skill added, install behaviour change, public-facing description change. |
| `LICENSE` | Only if changing license. Document the change in an ADR. |
| `.gitignore` | When adding a new artefact / cache dir that should not be committed. Append, never wholesale-rewrite. |
| `docs/decisions/` | When making an architectural decision another agent might wonder about. See ADR template. |

Stale hygiene files are a documented failure mode of multi-agent SDLCs. Don't let them rot.

---

## 11. Dev environment setup

New contributors (human or agent) bootstrap their environment:

```bash
git clone https://github.com/shmmsra/ai-skills.git
cd ai-skills
make setup-hooks   # installs pre-commit hook
make check         # verify baseline passes
```

No language toolchains or package managers required — the repo is pure Markdown and shell scripts.
