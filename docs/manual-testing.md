# ai-skills — Manual Testing Runbook

> Canonical runbook for manual verification before commit. Automated checks prove syntax; manual tests prove the feature works end-to-end.
>
> **When you add a new feature, CLI flag, or install behaviour, add a section here in the same commit.**

---

## How to use this file

For every feature area, this file lists:

1. **The exact command(s)** to run
2. **The setup** (env vars, fixtures, preconditions)
3. **What to observe** (log lines, output fields)
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
  <exact log lines, CLI output, or fields to inspect>

**Pass criteria**:
  <concrete, observable — not "it should work" but "CLI prints X", "log contains Z">

**Fail indicators**:
  <symptoms that mean the feature is broken or another feature has regressed>
```

---

## Bootstrap sanity check

**Test command(s)**:
```bash
make check
```

**Setup**: Fresh clone; `make setup-hooks` has been run once.

**What to observe**: Full output of the check pipeline.

**Pass criteria**:
- Exit code 0
- All `.sh` files pass syntax check (`bash -n`)
- Pre-commit hook exists at `.git/hooks/pre-commit` and is executable

**Fail indicators**:
- Exit code non-zero
- Any `bash -n` syntax error
- Pre-commit hook missing or not executable

---

## Install script — macOS/Linux

**Test command(s)**:
```bash
# Interactive run (in a test consumer repo)
bash /path/to/ai-skills/scripts/install.sh
```

**Setup**: Run inside a git repo that doesn't already have the skills installed.

**What to observe**: Interactive prompts for skill selection, install level (project/user), and agent targets. Files appear in the expected locations after confirmation.

**Pass criteria**:
- Selected skills appear at `.claude/skills/<name>/` (project-level) or `~/.claude/skills/<name>/` (user-level) — sourced from `skills/<name>/` in the cloned repo
- For Cursor: `.cursor/rules/<name>.mdc` is created
- `.gitattributes` gets `linguist-vendored` entry for `.claude/skills/**`
- Re-running the script detects existing installs and prompts for update
- No `docs/`, `scripts/`, `Makefile`, or other repo meta files are copied to the consumer

**Fail indicators**:
- Script exits early with an error
- Files installed to wrong path
- `linguist-vendored` entry not added to `.gitattributes`
- Repo meta files (non-skill content) copied into `.claude/skills/`

---

## dist branch (git subtree consumers)

**Test command(s)**:
```bash
# In a fresh test repo
git subtree add --prefix=.claude/skills https://github.com/shmmsra/ai-skills dist --squash
ls .claude/skills/
```

**Setup**: Fresh git repo with no existing `.claude/skills/` directory.

**Pass criteria**:
- `.claude/skills/<skill-name>/SKILL.md` exists for each skill
- No `scripts/`, `docs/`, `Makefile`, or other meta files appear under `.claude/skills/`
- `git subtree pull` subsequently fetches updates cleanly

---

*Add new sections below this line as features land. Group by feature area (e.g. install, skill-body, templates).*
