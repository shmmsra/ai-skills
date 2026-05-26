# ai-skills — Engineering Conventions

> Hard constraints and contribution rules for all agents working in this repository.
> These apply to every session, every agent, every change — no exceptions.

---

## 1. Contribution workflow

### What counts as non-trivial (requires a written plan + explicit human approval before coding)

A change is **non-trivial** (requires a written plan + explicit human approval before any code is written) if it:

- Creates any new file
- Modifies more than one file
- Changes the public interface of a skill (SKILL.md content, install scripts, template structure)
- Touches the workflow rules in `docs/agents/` or any agent-config file
- Adds, removes, or substantially rewrites a template

These are the cases where "seemed obvious" changes routinely go off the rails in multi-agent workflows.

### Exempt from the planning step (implement directly)

- Single-file bug fixes of 1–3 lines
- Pure documentation updates
- Adding tests for an interface that is already fully designed and approved
- Dependency version bumps

### Exempt from manual testing (may commit after `make check` + diff approval)

- Pure documentation updates with zero code changes
- Test-only additions with no logic change
- Dependency version bumps with no behavioural change
- Pure internal refactors where the public API and observable output are provably unchanged

---

## 2. Implementation rules

1. **`make check` must pass** before every commit.
2. **No `--no-verify`** except for docs/housekeeping commits with zero code changes.
3. **Documentation is part of done** — see `CONTRIBUTING.md §5` for the full list of docs to update per session.

---

## 3. Hard constraints

**Universal rules**:

- **No credentials in code**: API keys go in `.env` only (git-ignored). Secrets in code are a hard failure.
- **All decisions get an ADR**: If you're about to change something another agent might wonder about, write an ADR. Template in `docs/decisions/README.md`.
- **Linear history**: No `git merge --no-ff`. Use rebase or `git merge --ff-only`. Agents never run `git push`.

**Project-specific domain rules**:

*(no project-specific domain constraints defined — add them here as the project matures)*

---

## 4. Approval-gated operations

The following operations **always** require explicit human approval before execution, beyond the standard plan + commit approval:

*(no approval-gated operations defined for this project — all operations use the standard plan + commit workflow)*

If you are uncertain whether an operation falls under a special category, ask. The cost of asking is low.

---

## 5. Code-review and merge policy

This project's policy: **direct merge after local review**.

Code review is done locally:
1. The agent writes the implementation, posts the diff, and waits for explicit human approval ("lgtm", "commit it").
2. Once approved, the agent commits locally. The human pushes when ready.
3. **No feature branches required.** All work commits directly to `main` after local review.
4. If a branch is opened for experimentation, it must be rebased (not merged with `--no-ff`) before landing.

Full detail in `CONTRIBUTING.md §6`.

---

## 6. Commit conventions

No agent/human distinction is tracked in this repo — commits are just commits. Follow the standard format:

```
<type>(<scope>): <short imperative summary>

<body — what changed and why, not a diff summary>
```

**Types**: `feat`, `fix`, `test`, `docs`, `refactor`, `ci`, `chore`, `perf`

If the change closes a ticket: include the ticket ID — e.g. `feat(scope): aiskl-042 add retry logic`.

---

## 7. Repository hygiene files

These files are project artefacts, not metadata. **Keep them current.** Updating them is part of "done" for any change that affects them.

| File | What changes it |
|------|-----------------|
| `README.md` | New install/quick-start step, public-facing description change |
| `LICENSE` | Change in license (requires ADR) |
| `.gitignore` | New build artefact, cache dir, IDE config, or secret pattern |
| `docs/decisions/` | Architectural choice another agent might wonder about |

See `CONTRIBUTING.md §12` for the full policy.
