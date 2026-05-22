#!/usr/bin/env bash
#
# Install the project's git hooks. Run once after cloning:  make setup-hooks
#
# This installs two hooks:
#   - pre-commit: runs `make check` (or `{{CHECK_COMMAND}}`) before every commit
#   - post-commit: appends an audit row to docs/commit-log.md tagging the commit
#                  as `agent` (Co-Authored-By trailer present) or `manual`
#
# The pre-commit hook can be bypassed with `git commit --no-verify`, but per
# CONTRIBUTING.md §2 that's only allowed for docs-only / housekeeping commits
# with zero code changes. Bypassing on code changes is a violation.
#
# Manual-commit policy is set at scaffold time:
#   {{MANUAL_COMMIT_REVIEW}} = trailer-log     → both hooks installed
#                              pre-commit-block → adds a pre-commit gate
#                                                 requiring acknowledgement
#                              convention-only  → only pre-commit (no logging)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "${REPO_ROOT}" ]; then
  echo "error: not inside a git repository" >&2
  exit 1
fi

HOOKS_DIR="${REPO_ROOT}/.git/hooks"
PRE_COMMIT="${HOOKS_DIR}/pre-commit"
POST_COMMIT="${HOOKS_DIR}/post-commit"

# ─── pre-commit ───────────────────────────────────────────────────────────────

cat > "${PRE_COMMIT}" <<'HOOK'
#!/usr/bin/env bash
#
# Pre-commit hook installed by `make setup-hooks`.
# Aborts the commit if `make check` fails.
#
# Additionally, if MANUAL_COMMIT_REVIEW=pre-commit-block, requires either
# (a) the agent's Co-Authored-By trailer in COMMIT_EDITMSG, or
# (b) a `Manual-Review:` trailer / `AGENT_REVIEWED=1` env var
# before letting a manual commit land.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# 1. Run the check pipeline.
echo "→ Running make check (pre-commit)..."
if ! make check; then
  echo
  echo "✗ make check failed — commit aborted."
  echo "  Fix the failures and run 'git commit' again."
  echo "  To bypass for docs-only commits: git commit --no-verify"
  exit 1
fi

echo "✓ make check passed"

# 2. Manual-commit gate (only enforced if MANUAL_COMMIT_REVIEW=pre-commit-block).
MANUAL_COMMIT_REVIEW="{{MANUAL_COMMIT_REVIEW}}"
if [ "${MANUAL_COMMIT_REVIEW}" = "pre-commit-block" ]; then
  MSG_FILE="${REPO_ROOT}/.git/COMMIT_EDITMSG"
  if [ -f "${MSG_FILE}" ]; then
    AGENT_TRAILER='{{COAUTHOR_LINE}}'
    if grep -q -F "${AGENT_TRAILER}" "${MSG_FILE}" 2>/dev/null; then
      : # agent-authored — fine
    elif grep -q -E '^Manual-Review:' "${MSG_FILE}" 2>/dev/null; then
      : # human acknowledged
    elif [ "${AGENT_REVIEWED:-0}" = "1" ]; then
      : # env-var override
    else
      echo
      echo "✗ Manual commit detected without review acknowledgement."
      echo "  Add a 'Manual-Review: <reason>' trailer to the commit message,"
      echo "  or set AGENT_REVIEWED=1 in the environment to acknowledge."
      echo "  See CONTRIBUTING.md §10."
      exit 1
    fi
  fi
fi
HOOK

chmod +x "${PRE_COMMIT}"
echo "✓ Installed pre-commit hook at ${PRE_COMMIT}"

# ─── post-commit ──────────────────────────────────────────────────────────────

MANUAL_COMMIT_REVIEW="{{MANUAL_COMMIT_REVIEW}}"
if [ "${MANUAL_COMMIT_REVIEW}" = "convention-only" ]; then
  echo "ℹ Skipping post-commit hook (MANUAL_COMMIT_REVIEW = convention-only)"
else
  cat > "${POST_COMMIT}" <<'HOOK'
#!/usr/bin/env bash
#
# Post-commit hook installed by `make setup-hooks`.
# Appends an audit row to docs/commit-log.md tagging the commit author kind.
#
# Author kind:
#   - "agent"  if commit message contains the configured Co-Authored-By trailer
#   - "manual" otherwise

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
LOG_FILE="${REPO_ROOT}/docs/commit-log.md"

# Don't fail the commit if the log file is missing — just warn.
if [ ! -f "${LOG_FILE}" ]; then
  echo "⚠ post-commit: docs/commit-log.md not found; skipping audit row" >&2
  exit 0
fi

SHA="$(git rev-parse --short HEAD)"
SUBJECT="$(git log -1 --pretty=%s)"
BODY="$(git log -1 --pretty=%B)"
AUTHOR_NAME="$(git log -1 --pretty=%an)"
DATE="$(git log -1 --pretty=%cs)"

AGENT_TRAILER='{{COAUTHOR_LINE}}'
if echo "${BODY}" | grep -q -F "${AGENT_TRAILER}" 2>/dev/null; then
  KIND="agent"
elif [ -z "${AGENT_TRAILER}" ]; then
  # Co-author is disabled; rely on the agent-commit.sh subject tag instead.
  if echo "${SUBJECT}" | grep -q '^\[agent\]'; then
    KIND="agent"
  else
    KIND="manual"
  fi
else
  KIND="manual"
fi

# Append the row.
{
  printf '| %s | %s | `%s` | %s | %s |\n' \
    "${DATE}" "${KIND}" "${SHA}" "${AUTHOR_NAME}" "${SUBJECT}"
} >> "${LOG_FILE}"

echo "✓ commit-log: recorded ${SHA} as ${KIND}"
HOOK
  chmod +x "${POST_COMMIT}"
  echo "✓ Installed post-commit hook at ${POST_COMMIT}"
fi

echo
echo "Hooks ready. Test the pre-commit gate with: make check"
