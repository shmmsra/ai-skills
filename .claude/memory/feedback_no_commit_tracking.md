---
name: no-commit-tracking
description: This repo does not track agent vs human commit attribution — no trailers, no commit log, no agent-commit.sh wrapper
metadata:
  type: feedback
---

Do not add Co-Authored-By trailers to commit messages, do not use `scripts/agent-commit.sh`, and do not reference `docs/commit-log.md` — none of these exist in this repo.

**Why**: The owner explicitly chose not to differentiate between agent and human commits. Commits are just commits — use plain `git commit` with the message format from CONTRIBUTING.md §7.

**How to apply**:
- Use `git commit -m "<message>"` directly. No wrapper scripts.
- Do not add any `Co-Authored-By:` or agent attribution trailers.
- Do not mention commit-log.md or suggest auditing commits by author kind.
