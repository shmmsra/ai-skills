# {{PROJECT_NAME}}

> {{PROJECT_DESCRIPTION}}

---

## Status

See [`docs/agents/STATUS.md`](docs/agents/STATUS.md) for current phase, in-progress work, and what's next.

## Getting started

Full setup — language toolchains, dependencies, tools, agent skills, MCP servers, git hooks — is documented in **[`docs/dev-setup.md`](docs/dev-setup.md)**. Read that first on a fresh clone.

Quick start (assumes prerequisites already installed — see dev-setup.md for those):

```bash
git clone <repo-url>
cd {{PROJECT_SLUG}}
# install dependencies — see docs/dev-setup.md §2
make setup-hooks    # one-time: installs pre-commit + post-commit
{{CHECK_COMMAND}}   # verify baseline
```

## Project layout

```
docs/
├── agents/             # AI-agent rules — read FIRST on every session
│   ├── OVERVIEW.md     # Context, architecture, tech stack
│   ├── CONVENTIONS.md  # Hard constraints — non-negotiable
│   └── STATUS.md       # Current state + what's next
├── dev-setup.md        # Onboarding
├── decisions/          # ADRs — read before changing anything covered
├── CHANGELOG.md
├── requirements.md
├── manual-testing.md
├── issues.md           # Ticket tracker ({{TICKET_SOURCE_DESCRIPTION}})
└── commit-log.md       # Audit log: agent vs manual commits
```

## AI-Driven SDLC

This project is built by humans collaborating with multiple AI coding agents (Claude, Codex, Cursor, Gemini) across many sessions. The workflow is documented in **[`CONTRIBUTING.md`](CONTRIBUTING.md)** and is non-optional. Highlights:

- **Plan first** — agents write a plan and wait for explicit human approval before coding.
- **TDD enforced** — `{{CHECK_COMMAND}}` runs before every commit via pre-commit hook.
- **Docs as part of done** — every feature updates `STATUS.md`, `CHANGELOG.md`, `requirements.md`, `issues.md`, and (if dependencies changed) `dev-setup.md`.
- **Commit attribution tracked** — agents commit via `scripts/agent-commit.sh`; the post-commit hook logs every commit's author kind to `docs/commit-log.md`.
- **Merge policy**: `{{MERGE_POLICY}}` (see [`CONTRIBUTING.md §6`](CONTRIBUTING.md)).

If you're a new contributor (human or agent), read in this order: this file → `docs/dev-setup.md` → `docs/agents/OVERVIEW.md` → `CONTRIBUTING.md`.

## License

{{LICENSE_SPDX}} — see [`LICENSE`](LICENSE).

## Owner

{{PROJECT_OWNER}}
