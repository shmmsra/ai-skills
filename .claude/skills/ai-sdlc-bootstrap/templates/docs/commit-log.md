# {{PROJECT_NAME}} — Commit Log

> Append-only audit log of every commit, tagged with author kind (`agent` or `manual`). Written by the post-commit hook installed via `make setup-hooks`.
>
> **Do not hand-edit rows.** The post-commit hook owns this file. Hand-editing breaks the audit trail and may be flagged in review.
>
> **Why this file exists**: see `CONTRIBUTING.md §10`. Before pushing or merging into `main`, the agent must read this file and audit every `manual` commit in the push/merge range against `docs/agents/CONVENTIONS.md`.

---

## Author kinds

| Kind | Meaning |
|------|---------|
| `agent` | Commit was authored by an AI agent — the agent ran `scripts/agent-commit.sh`, which added the configured Co-Authored-By trailer (or `[agent]` subject tag if co-author trailers are disabled). |
| `manual` | Commit was authored by a human directly via `git commit`. Requires agent audit before push/merge. |

---

## Log

| Date | Kind | SHA | Author | Subject |
|------|------|-----|--------|---------|
