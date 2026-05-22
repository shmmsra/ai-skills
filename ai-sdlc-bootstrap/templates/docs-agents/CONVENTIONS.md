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

---

## 3. Hard constraints

**Universal rules**:

- **No credentials in code**: API keys go in `.env` only (git-ignored). Secrets in code are a hard failure.
- **All decisions get an ADR**: If you're about to change something another agent might wonder about, write an ADR. Template in `docs/decisions/README.md`.
- **Linear history**: No `git merge --no-ff`. Use rebase or `git merge --ff-only`. Agents never run `git push`.

**Project-specific domain rules**:

{{DOMAIN_RULES_BLOCK}}

---

## 4. Approval-gated operations

The following operations **always** require explicit human approval before execution, beyond the standard plan + commit approval:

{{APPROVAL_GATES_BLOCK}}

If you are uncertain whether an operation falls under one of these categories, ask. The cost of asking is low; the cost of an unwanted change in any of these areas is high.
