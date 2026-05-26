# `.claude/memory/` — Claude Code Persistent Memory

> This directory holds Claude Code's persistent memory for {{PROJECT_NAME}}. Other agents (Codex, Cursor, Gemini) ignore it.
>
> **Use it for**: per-user preferences, validated working style, feedback Claude should remember across sessions.
> **Don't use it for**: project-wide rules (those go in `docs/agents/CONVENTIONS.md` where every agent sees them).

---

## Initial setup

When this scaffold ran, three files were created:

- `MEMORY.md` — the index file Claude reads first
- `feedback_docs_as_part_of_done.md` — reminds Claude that docs update with every feature
- `feedback_no_auto_push.md` — reminds Claude never to `git push` autonomously

You can add more files as you work with Claude. They follow this format:

```markdown
---
name: short-kebab-slug
description: One-line summary used to decide relevance in future conversations
metadata:
  type: feedback | user | project | reference
---

Body of the memory.

**Why**: <the reason — often a past incident or strong preference>
**How to apply**: <when/where this guidance kicks in>
```

Then add an entry to `MEMORY.md`:

```
- [Title](file.md) — one-line hook
```

---

## Initial `MEMORY.md`

```markdown
# Memory Index

- [feedback: docs as part of done](feedback_docs_as_part_of_done.md) — docs update with every feature
- [feedback: agent never pushes](feedback_no_auto_push.md) — `git push` is always manual
```

---

## Initial `feedback_docs_as_part_of_done.md`

```markdown
---
name: docs-as-part-of-done
description: Every feature/fix must update STATUS, CHANGELOG, requirements, issues, and (if runtime-affecting) manual-testing in the same commit
metadata:
  type: feedback
---

A feature or fix is not done until the documentation updates land in the same commit.

**Why**: This project is built by humans + multiple AI agents across many sessions. Without doc updates at commit time, the next agent reads stale state and makes wrong decisions. This is the SDLC's load-bearing rule.

**How to apply**: Before showing the commit diff, verify these files have been updated for the work in this session:
- `docs/agents/STATUS.md`
- `docs/CHANGELOG.md`
- `docs/requirements.md`
- `docs/issues.md`
- `docs/manual-testing.md` (if runtime behaviour changed)
- `docs/decisions/NNNN-*.md` (if an architectural decision was made)

If any is missing, fix it before requesting commit approval.
```

---

## Initial `feedback_no_auto_push.md`

```markdown
---
name: no-auto-push
description: AI agents must never run `git push` — pushing is a one-way externally visible action that's always the human's call
metadata:
  type: feedback
---

Never run `git push` autonomously. Pushing is one-way, externally visible, and undoes are expensive.

**Why**: Local commits are reversible. Pushed commits ripple to anyone watching the remote (CI, teammates, deploys). The human always makes the call.

**How to apply**:
- Even when the human says "merge it" or "land it" — that means commit + merge locally, not push.
- Even when all checks pass and the diff is approved.
- If the human explicitly types `git push` or says "push to remote", run it. Otherwise, stop after the local commit and report the SHA.
- Never offer to push or ask "should I push?".
```

---

## Commit / gitignore decision

By default `.claude/memory/` is **committed** for solo / small-team repos — it gives every Claude session a stable starting point. For larger teams where preferences diverge per person, add this to `.gitignore`:

```
.claude/memory/
```

Confirm with the team before deciding.
