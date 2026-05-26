# {{PROJECT_NAME}} — Issue Tracker Bridge (GitHub Issues)

> This project uses **GitHub Issues** at [{{GITHUB_OWNER_REPO}}](https://github.com/{{GITHUB_OWNER_REPO}}/issues) as the canonical issue tracker.
>
> This file is the bridge for AI agents — it explains how to interact with GitHub Issues from the CLI without requiring API access tokens beyond the `gh` CLI's own auth.

---

## How agents interact with GitHub Issues

Use the `gh` CLI for all issue operations. It uses the human's GitHub credentials (already authenticated via `gh auth login`).

### Read open issues

```bash
gh issue list --state open --limit 30
gh issue list --state open --label bug
gh issue list --state open --search "priority:p1"
```

### View one issue (acceptance criteria, comments)

```bash
gh issue view <NUMBER>
gh issue view <NUMBER> --comments
```

### Pick the next ticket to work on

At the start of a session:

```bash
gh issue list --state open --label "priority:p1" --limit 5
gh issue view <NUMBER>
```

Then mark it in progress by adding a label or assigning yourself:

```bash
gh issue edit <NUMBER> --add-label "in-progress"
```

### Close an issue when done

Reference the issue in the commit message — GitHub will auto-close when the commit lands on the default branch:

```
feat(scope): #42 add retry logic for upstream timeouts

Closes #42.
```

Or close manually after merge:

```bash
gh issue close <NUMBER> --comment "Closed by commit <SHA>"
```

---

## Ticket conventions

- **Title**: imperative, concise (`Add retry logic for upstream timeouts`, not `Bug: timeouts`).
- **Labels**: at minimum `priority:p0`/`p1`/`p2`/`p3`, and one of `bug`/`feat`/`refactor`/`docs`.
- **Acceptance criteria**: written as a checkbox list in the issue body. Every box must be ticked before close.
- **Commit reference**: include `#NNN` in the commit message to link issue ↔ commit.

---

## What to mirror in this file

This file does **not** duplicate ticket content (that lives on GitHub). Instead, mirror only:

- **Current sprint focus** — which issue numbers are P0/P1 this week
- **Blocked items** — issues where the blocker is in this repo (so agents see them when reading docs)
- **Recently closed** — the last 10 closures, for fast scan without `gh` calls

### Current focus

| Issue | Title | Priority | Status |
|-------|-------|----------|--------|
| — | *(none yet)* | — | — |

### Blocked

*(none)*

### Recently closed

| Date | Issue | Title | Commit |
|------|-------|-------|--------|
| {{TODAY}} | — | ai-sdlc-bootstrap scaffold | pending |
