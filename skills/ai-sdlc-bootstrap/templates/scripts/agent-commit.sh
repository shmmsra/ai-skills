#!/usr/bin/env bash
#
# scripts/agent-commit.sh
#
# AI agents commit through this wrapper instead of plain `git commit`.
# It adds the configured Co-Authored-By trailer (or [agent] subject tag if
# co-author is disabled) so the post-commit hook can recognise this commit as
# agent-authored when logging to docs/commit-log.md.
#
# Usage:
#   scripts/agent-commit.sh "<commit message>"
#   scripts/agent-commit.sh -F path/to/message.txt
#
# Notes:
#   - This wrapper does NOT bypass the pre-commit hook. `make check` still
#     runs. If you need to bypass for a docs-only commit, pass --no-verify
#     after the message (e.g. `scripts/agent-commit.sh "docs: typo" --no-verify`).
#   - Plain `git commit` continues to work — those commits will be logged as
#     `manual` by the post-commit hook, per CONTRIBUTING.md §10.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# Co-author setup is decided at scaffold time.
COAUTHOR_AGENT="{{COAUTHOR_AGENT}}"          # yes / no
COAUTHOR_LINE='{{COAUTHOR_LINE}}'             # e.g. "Co-Authored-By: Claude <noreply@anthropic.com>"

if [ "$#" -lt 1 ]; then
  echo "usage: scripts/agent-commit.sh \"<commit message>\" [extra git-commit flags]" >&2
  echo "       scripts/agent-commit.sh -F path/to/message.txt [extra git-commit flags]" >&2
  exit 64
fi

# Build the commit message in a tmp file so we can safely add trailers and the
# subject tag without shell-quoting heartburn.
TMP_MSG="$(mktemp)"
trap 'rm -f "${TMP_MSG}"' EXIT

if [ "$1" = "-F" ]; then
  [ "$#" -ge 2 ] || { echo "error: -F requires a file path" >&2; exit 64; }
  cp "$2" "${TMP_MSG}"
  shift 2
else
  printf '%s\n' "$1" > "${TMP_MSG}"
  shift
fi

# If co-author is disabled, tag the subject line with [agent] so the
# post-commit hook still recognises the author kind. (Tag is a no-op if
# already present.)
if [ "${COAUTHOR_AGENT}" != "yes" ]; then
  if ! head -n 1 "${TMP_MSG}" | grep -q '^\[agent\]'; then
    SUBJECT="$(head -n 1 "${TMP_MSG}")"
    REST="$(tail -n +2 "${TMP_MSG}")"
    {
      printf '[agent] %s\n' "${SUBJECT}"
      printf '%s\n' "${REST}"
    } > "${TMP_MSG}.new"
    mv "${TMP_MSG}.new" "${TMP_MSG}"
  fi
fi

# Append Co-Authored-By trailer if enabled and not already present.
if [ "${COAUTHOR_AGENT}" = "yes" ] && [ -n "${COAUTHOR_LINE}" ]; then
  if ! grep -q -F "${COAUTHOR_LINE}" "${TMP_MSG}"; then
    # Ensure blank line before trailers (Conventional Commits / Git trailer rules).
    if [ -s "${TMP_MSG}" ]; then
      LAST="$(tail -c 1 "${TMP_MSG}" || printf '')"
      [ "${LAST}" = "" ] || printf '\n' >> "${TMP_MSG}"
    fi
    # Ensure exactly one blank line separator before trailer block.
    printf '\n%s\n' "${COAUTHOR_LINE}" >> "${TMP_MSG}"
  fi
fi

# Hand off to git commit. Any remaining args (e.g. --no-verify, --amend, -s)
# are passed through.
exec git commit -F "${TMP_MSG}" "$@"
