# {{PROJECT_NAME}} — Manual Testing Runbook

> Canonical runbook for manual verification before commit. Automated tests prove correctness; manual tests prove the feature works end-to-end.
>
> **When you add a new feature, CLI flag, UI element, or API route, add a section here in the same commit.**

---

## How to use this file

For every feature area, this file lists:

1. **The exact command(s)** to run
2. **The setup** (env vars, fixtures, preconditions)
3. **What to observe** (log lines, UI state, output fields)
4. **Pass criteria** (concrete, observable conditions)
5. **Fail indicators** (symptoms that mean the feature is broken or a regression has occurred)

The agent writes these for every new runtime-affecting change. The human runs them before commit approval.

---

## Test template (copy this when adding a new section)

```markdown
### <feature name>

**Test command(s)**:
  <exact shell command(s) to run>

**Setup** (if any):
  <env vars, flags, or preconditions>

**What to observe**:
  <exact log lines, UI state, CLI output, or JSON fields to inspect>

**Pass criteria**:
  <concrete, observable — not "it should work" but "CLI prints X", "UI shows Y", "log contains Z">

**Fail indicators**:
  <symptoms that mean the feature is broken or another feature has regressed>
```

---

## Bootstrap sanity check

**Test command(s)**:
```bash
{{CHECK_COMMAND}}
```

**Setup**: Fresh clone; dependencies installed; `make setup-hooks` has been run once.

**What to observe**: Full output of the check pipeline.

**Pass criteria**:
- Exit code 0
- All tests pass (or "no tests yet" if the project hasn't written any)
- No type errors
- No lint errors

**Fail indicators**:
- Exit code non-zero
- Any test failure
- Any uncaught type or lint violation
- Pre-commit hook missing or not executable (`.git/hooks/pre-commit` should exist after `make setup-hooks`)

---

*Add new sections below this line as features land. Group by feature area (e.g. CLI, API, UI, integrations).*
