# {{PROJECT_NAME}} — Engineering Conventions

> Hard constraints and contribution rules for all agents working in this repository.
> These apply to every session, every agent, every change — no exceptions.

---

## 1. Contribution workflow

### What counts as non-trivial (requires a written plan + explicit human approval before coding)

{{NONTRIVIAL_DEFINITION_BLOCK}}

### Exempt from the planning step (implement directly)

- Single-file bug fixes of 1–3 lines
- Pure documentation updates
- Adding tests for an interface that is already fully designed and approved
- Dependency version bumps

### Exempt from manual testing (may commit after `{{CHECK_COMMAND}}` + diff approval)

- Pure documentation updates with zero code changes
- Test-only additions with no logic change
- Dependency version bumps with no behavioural change
- Pure internal refactors where the public API and observable output are provably unchanged

---

## 2. Implementation rules

1. **TDD is mandatory** — write the test before (or alongside) any logic change, in the same commit.
2. **`{{CHECK_COMMAND}}` must pass** before every commit.
3. **No `--no-verify`** except for docs/housekeeping commits with zero code changes.
4. **Documentation is part of done** — see `CONTRIBUTING.md §5` for the full list of docs to update per session.
5. **Read before you edit; check callers before you change a signature** — Read a file before your first edit to it in a session, and re-read it if it may have changed since (e.g. after a pull, another agent's commit, or a generated/build step) — don't edit from a stale mental model. Before changing a function/method signature, exported symbol, or public API, search the codebase for every call site and update them in the same change.

---

## 3. Hard constraints

**Universal rules**:

- **No credentials in code**: API keys go in `.env` only (git-ignored). Secrets in code are a hard failure.
- **All decisions get an ADR**: If you're about to change something another agent might wonder about, write an ADR. Template in `docs/decisions/README.md`.
- **Linear history**: No `git merge --no-ff`. Use rebase or `git merge --ff-only`. Agents never run `git push`.

**Project-specific domain rules**:

{{DOMAIN_RULES_BLOCK}}

### Related-project awareness

- Before making a change that touches a related project's domain (see `docs/agents/OVERVIEW.md` § Related projects), read that project's own agent docs first — don't assume behavior you haven't verified.

---

## 4. Approval-gated operations

The following operations **always** require explicit human approval before execution, beyond the standard plan + commit approval:

{{APPROVAL_GATES_BLOCK}}

If you are uncertain whether an operation falls under one of these categories, ask. The cost of asking is low; the cost of an unwanted change in any of these areas is high.

---

## 5. Code-review and merge policy

This project's policy: **`{{MERGE_POLICY}}`**.

{{MERGE_POLICY_BLOCK}}

Full detail in `CONTRIBUTING.md §6`.

---

## 6. Commit attribution and tracking

This repo tracks **author kind** for every commit (`agent` vs `manual`). The mechanism: `{{MANUAL_COMMIT_REVIEW}}`.

- Agents commit via `scripts/agent-commit.sh` — adds the trailer `{{COAUTHOR_LINE}}`, post-commit hook logs `agent` in `docs/commit-log.md`.
- Humans commit with plain `git commit` — no trailer, logged as `manual`.
- Before any push / merge to `main`, the agent must audit every `manual` commit in the range against this file. See `CONTRIBUTING.md §10`.

Violating this audit step is treated as a Rule 0 violation — same severity as skipping the plan step.

---

## 7. Repository hygiene files

These files are project artefacts, not metadata. **Keep them current.** Updating them is part of "done" for any change that affects them.

| File | What changes it |
|------|-----------------|
| `README.md` | New install/quick-start step, public-facing description change |
| `LICENSE` | Change in license (requires ADR) |
| `CODEOWNERS` | Module / directory ownership change |
| `.gitignore` | New build artefact, cache dir, IDE config, or secret pattern |
| `.vscode/`, `.zed/`, IDE configs | New recommended extension or workspace setting |
| `docs/dev-setup.md` | **New dependency, MCP, skill, language toolchain, or required tool** — onboarding will break otherwise |
| `docs/decisions/` | Architectural choice another agent might wonder about |
| `project.deps.yaml` | Adding, removing, or renaming a related project. Run `make update-project-lock` after editing. |

See `CONTRIBUTING.md §12` for the full policy.
