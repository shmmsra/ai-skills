#!/usr/bin/env bash
#
# Install the pre-commit hook that runs `make check` before every commit.
# Run once after cloning the repo:  make setup-hooks
#
# The hook can be bypassed with `git commit --no-verify`, but per CONTRIBUTING.md
# §2, that's only allowed for docs-only / repo-housekeeping commits with zero
# code changes. Bypassing on code changes is a violation.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "${REPO_ROOT}" ]; then
  echo "error: not inside a git repository" >&2
  exit 1
fi

HOOK_PATH="${REPO_ROOT}/.git/hooks/pre-commit"

cat > "${HOOK_PATH}" <<'HOOK'
#!/usr/bin/env bash
#
# Pre-commit hook installed by `make setup-hooks`.
# Aborts the commit if `make check` fails.
#
# To bypass (docs-only commits with no code changes), use:
#   git commit --no-verify
# Otherwise, fix what's failing and commit again.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

echo "→ Running make check (pre-commit)..."
if ! make check; then
  echo
  echo "✗ make check failed — commit aborted."
  echo "  Fix the failures and run 'git commit' again."
  echo "  To bypass for docs-only commits: git commit --no-verify"
  exit 1
fi

echo "✓ make check passed"
HOOK

chmod +x "${HOOK_PATH}"

echo "✓ Installed pre-commit hook at ${HOOK_PATH}"
echo "  It will run 'make check' before every commit."
echo "  Test it now with: make check"
