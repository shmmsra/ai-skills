# {{PROJECT_NAME}} — Issue Tracker Bridge (JIRA)

> This project uses **JIRA** project [`{{JIRA_PROJECT_KEY}}`]({{JIRA_BASE_URL}}/browse/{{JIRA_PROJECT_KEY}}) as the canonical issue tracker.
>
> This file is the bridge for AI agents — it explains how to interact with JIRA without round-tripping to the web UI for every read.

---

## How agents interact with JIRA

JIRA does not have a first-party CLI as polished as `gh`. The two practical options:

1. **`jira-cli`** (community, written in Go) — install via `brew install ankitpokhrel/jira-cli/jira-cli` or download from [github.com/ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli). Auth once via `jira init`.
2. **REST API via `curl`** — for one-off reads, hit `{{JIRA_BASE_URL}}/rest/api/3/...` with a personal access token from `~/.netrc` or `$JIRA_TOKEN`.

Pick one and document the choice here once the human installs the tooling.

### Read open issues (jira-cli)

```bash
jira issue list --project {{JIRA_PROJECT_KEY}} --status "To Do"
jira issue list --project {{JIRA_PROJECT_KEY}} --status "In Progress" --assignee $(whoami)
jira issue list --project {{JIRA_PROJECT_KEY}} --jql 'priority = High AND status != Done'
```

### View one issue

```bash
jira issue view {{JIRA_PROJECT_KEY}}-42
```

### Pick the next ticket

```bash
jira issue list --project {{JIRA_PROJECT_KEY}} --status "To Do" --priority High
```

### Move through states

```bash
jira issue move {{JIRA_PROJECT_KEY}}-42 "In Progress"
jira issue move {{JIRA_PROJECT_KEY}}-42 "Done"
```

### Close on commit

Reference the JIRA key in the commit message — most JIRA + Git integrations auto-link:

```
feat(scope): {{JIRA_PROJECT_KEY}}-42 add retry logic for upstream timeouts
```

Some teams configure smart commits — `{{JIRA_PROJECT_KEY}}-42 #close` — but this depends on the JIRA-VCS integration. Confirm with the team before relying on it.

---

## Ticket conventions

- **Key format**: `{{JIRA_PROJECT_KEY}}-NNN` (e.g. `{{JIRA_PROJECT_KEY}}-001`, `{{JIRA_PROJECT_KEY}}-002`).
- **Type**: Story / Bug / Task / Spike — match the team's existing taxonomy.
- **Priority**: Highest / High / Medium / Low / Lowest (JIRA's defaults; project may have customised these).
- **Acceptance criteria**: in the issue description, as a checkbox list. Every box must be ticked before transition to Done.
- **Commit reference**: include the full key (`{{JIRA_PROJECT_KEY}}-NNN`) in the commit message — JIRA picks it up via webhook or polling.

---

## What to mirror in this file

JIRA is the source of truth. This file mirrors only:

### Current focus

| Key | Title | Priority | Status |
|-----|-------|----------|--------|
| — | *(none yet)* | — | — |

### Blocked

| Key | Title | Blocker |
|-----|-------|---------|
| — | *(none)* | — |

### Recently closed

| Date | Key | Title | Commit |
|------|-----|-------|--------|
| {{TODAY}} | — | ai-sdlc-bootstrap scaffold | pending |

---

## Credentials

Never commit JIRA credentials. Use one of:

- `~/.config/.jira/.config.yml` (jira-cli's default location after `jira init`)
- `$JIRA_API_TOKEN` env var sourced from `.envrc` (with `direnv`) — `.envrc` itself goes in `.gitignore`
- macOS Keychain / system credential store via the tooling

If an agent ever needs to ask for a JIRA token, **stop and ask the human** — don't read it from the environment without confirming the value isn't in a shell history.
