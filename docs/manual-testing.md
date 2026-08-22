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

---

## Per-skill versioning (AISKL-003)

### Scenario A — same-version no-op

**Test command(s)**:
```bash
# Install the skill once, then run the installer again without --update
bash /path/to/ai-skills/scripts/install.sh
# select the same skill and claude-code agent again when prompted
```

**Setup**: Skill already installed at `.claude/skills/<name>/` with a `VERSION` file matching the source.

**What to observe**: Second run does not overwrite files and prints a skip message.

**Pass criteria**:
- CLI prints `✓  <skill> v1.0.0 already installed — skipping  (pass --update to force)`
- Files in `.claude/skills/<name>/` are unchanged (check mtime or diff)

**Fail indicators**:
- Files are overwritten silently
- Script errors on missing `VERSION` file
- Wrong version string shown

---

### Scenario B — version mismatch (old installed, new source)

**Test command(s)**:
```bash
# Manually edit the installed VERSION to an older value, then re-run
echo "0.9.0" > .claude/skills/<name>/VERSION
bash /path/to/ai-skills/scripts/install.sh
```

**Setup**: Installed `VERSION` contains `0.9.0`; source `VERSION` contains `1.0.0`.

**What to observe**: Installer detects the directory exists and warns, but does not silently overwrite.

**Pass criteria**:
- CLI prints `!  Already present — skipping  (use --update to overwrite)`
- Files are NOT updated until `--update` is passed

**Fail indicators**:
- Files overwritten without `--update`
- No warning shown

---

### Scenario C — `--update` force override

**Test command(s)**:
```bash
bash /path/to/ai-skills/scripts/install.sh --update
# or: UPDATE_MODE=1 bash /path/to/ai-skills/scripts/install.sh
```

**Setup**: Skill already installed at any version.

**What to observe**: Installer overwrites files regardless of version match.

**Pass criteria**:
- Files in `.claude/skills/<name>/` are updated (new `VERSION` matches source)
- CLI prints `✓  Claude Code  →  .claude/skills/<name>/`

**Fail indicators**:
- Skip message shown despite `--update`
- `VERSION` file not updated

---

---

## Per-skill `linguist-vendored` scoping (AISKL-004)

### Scenario A — two skills produce two distinct `.gitattributes` lines

**Test command(s)**:
```bash
# In a clean git repo with no .gitattributes
bash /path/to/ai-skills/scripts/install.sh
# select: ai-sdlc-bootstrap + book-companion, project scope, claude-code + cursor agents
cat .gitattributes
```

**Setup**: Fresh git repo, no prior `.gitattributes`.

**What to observe**: `.gitattributes` contains four lines — two for Claude Code skills, two for Cursor skills — each scoped to a single skill path.

**Pass criteria**: file contains exactly:
```
.claude/skills/ai-sdlc-bootstrap/** linguist-vendored
.cursor/rules/ai-sdlc-bootstrap.mdc linguist-vendored
.claude/skills/book-companion/** linguist-vendored
.cursor/rules/book-companion.mdc linguist-vendored
```
(order may vary depending on selection order)

**Fail indicators**:
- Broad patterns like `.claude/skills/** linguist-vendored` written
- Missing entries for any installed skill
- Duplicate entries on re-install

---

### Scenario B — user-authored skill not marked as vendored

**Test command(s)**:
```bash
mkdir -p .claude/skills/my-custom-skill
echo "# my skill" > .claude/skills/my-custom-skill/SKILL.md
bash /path/to/ai-skills/scripts/install.sh
# select: ai-sdlc-bootstrap only
grep "my-custom-skill" .gitattributes && echo "FAIL" || echo "PASS"
```

**Setup**: User has already authored a skill at `.claude/skills/my-custom-skill/`.

**What to observe**: After installing `ai-sdlc-bootstrap`, `.gitattributes` does NOT contain any line referencing `my-custom-skill`.

**Pass criteria**:
- `grep my-custom-skill .gitattributes` returns nothing (or "PASS" message shown)
- Only the installed skill gets a `linguist-vendored` line

**Fail indicators**:
- `my-custom-skill` appears in `.gitattributes`
- Broad glob pattern installed

---

### Scenario C — re-install does not duplicate entries

**Test command(s)**:
```bash
bash /path/to/ai-skills/scripts/install.sh --update
# select same skills as previous install
grep -c "ai-sdlc-bootstrap" .gitattributes
```

**Setup**: Skill already installed once, `.gitattributes` already has its per-skill line.

**Pass criteria**: `grep -c` shows the same count as before re-install (typically 2: one for Claude Code, one for Cursor) — no duplicates.

**Fail indicators**: count increases on each re-install.

---

---

## vocal-ai skill (AISKL-005)

### Scenario A — first-time setup

**Test command(s)**:
```bash
export VOCALAI_INSTALL_DIR="$HOME/.vocal-ai-test"
curl -fsSL https://raw.githubusercontent.com/shmmsra/vocal-ai/main/scripts/install.sh | bash
```

**Setup**: `$VOCALAI_INSTALL_DIR` does not yet exist.

**What to observe**: Binary and model files are downloaded; `.vocalai_version` and `models/MODELS_VERSION` are written under `$VOCALAI_INSTALL_DIR`.

**Pass criteria**:
- `test -x "$VOCALAI_INSTALL_DIR/vocalai"` succeeds
- `ls "$VOCALAI_INSTALL_DIR/models"` shows the `.onnx` model files
- `"$VOCALAI_INSTALL_DIR/vocalai" --text "test" --out /tmp/vocalai-check.wav --models-dir "$VOCALAI_INSTALL_DIR/models"` produces a non-empty WAV file

**Fail indicators**:
- Binary missing or not executable
- Model directory empty or missing `.onnx` files
- CLI invocation errors out or produces a zero-byte/invalid WAV

---

### Scenario B — re-running install is a no-op when current

**Test command(s)**:
```bash
curl -fsSL https://raw.githubusercontent.com/shmmsra/vocal-ai/main/scripts/install.sh | bash
```

**Setup**: `$VOCALAI_INSTALL_DIR` already has the current binary + models from Scenario A.

**What to observe**: Script detects matching `.vocalai_version` / `MODELS_VERSION` and skips downloading.

**Pass criteria**: No re-download occurs (script reports already up to date); file mtimes under `$VOCALAI_INSTALL_DIR` are unchanged.

**Fail indicators**: Binary/models are re-downloaded despite matching versions.

---

### Scenario C — speech generation

**Test command(s)**:
```bash
"$VOCALAI_INSTALL_DIR/vocalai" --text "Let's walk through the dashboard." \
  --out /tmp/narration-01.wav --models-dir "$VOCALAI_INSTALL_DIR/models"
```

**Setup**: `vocalai` already installed (Scenario A).

**What to observe**: A WAV file is written at the `--out` path.

**Pass criteria**:
- Exit code 0
- `/tmp/narration-01.wav` exists, is non-empty, and plays back as intelligible speech of the given text

**Fail indicators**:
- Non-zero exit code
- Empty or corrupt WAV file
- Audio doesn't match the input text

---

*Add new sections below this line as features land. Group by feature area (e.g. install, skill-body, templates).*
