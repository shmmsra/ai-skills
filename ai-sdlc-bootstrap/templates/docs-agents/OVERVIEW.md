# {{PROJECT_NAME}} — Project Overview

> Canonical reference for project context, architecture, tech stack, and build commands.
> Read before asking architecture questions or evaluating new libraries/frameworks.

---

## What is this project?

**{{PROJECT_NAME}}** — {{PROJECT_DESCRIPTION}}

**Owner**: {{PROJECT_OWNER}}
**AI-first SDLC**: Designed to be built by humans and multiple AI agents across many sessions. Every significant decision and status change is committed to this repo so agents never need manual context transfer.

---

## Architecture in 30 seconds

> *Replace this section with a 5-line ASCII diagram or short prose of how the major components fit together. Keep it tight — the goal is to orient an agent in 10 seconds.*

```
[your-architecture-here]
```

For the full architecture see [`docs/architecture.md`](../architecture.md) (create if non-trivial).

---

## Related projects

This repo declares relationships with other projects — in-repo sub-projects and/or external repo
dependencies. **`.project.lock.yaml`** (gitignored) is the source of truth to read: it holds every
related project, in-repo or external, fully resolved and flattened (including transitive ones —
a related project's own further dependencies are walked too), each with its `kind`, resolved
`local_path`, and its `notes` (what it holds, acronyms, when to check it). **`project.deps.yaml`**
(committed) is the raw input you hand-edit to add/remove/change a relationship — it is not
guaranteed current on its own; if `.project.lock.yaml` is missing or looks stale relative to it,
run `scripts/update-project-lock.sh` (macOS/Linux) or `scripts/update-project-lock.ps1` (Windows)
first — or `make update-project-lock` if this project uses a Makefile; the scripts always work
regardless of build tooling, `make` is only ever a convenience wrapper around them.

**Never summarize the specific current entries here** (e.g. "this repo's related projects are X, Y, Z, addressing paths under W") — reference these two files generically only. That duplicates data that goes stale the instant an entry changes.

**Read `.project.lock.yaml` before starting any task, not only once you already suspect it's relevant** — its `notes` field on each entry is the *only* way to learn a related project exists and might overlap with what you're doing, precisely because nothing is summarized here. Skipping this means you can silently miss a relevant related project.

**Before working on anything that touches a related project's domain** (per its `notes` in the
lock), read that project's own agent docs first — even if your tool doesn't auto-load them. Use
`<local_path>` directly, **except** for an external entry whose lock record has a non-empty
`path` (it addresses one package inside a monorepo dependency) — there, join `local_path` and
`path` first; that joined directory is where the addressed package's own docs and code actually
live, not the bare `local_path` (the whole monorepo's checkout root):

1. `<local_path>/docs/agents/OVERVIEW.md` (plus `CONVENTIONS.md`, `STATUS.md`) — if it was bootstrapped with ai-sdlc-bootstrap
2. `<local_path>/AGENTS.md` or `<local_path>/CLAUDE.md`
3. `<local_path>/README.md`
4. None found — proceed on judgment, and say so explicitly

---

## Key decisions (quick reference)

Full ADRs in [`docs/decisions/`](../decisions/). Read the ADR before changing anything related to that decision.

| # | Decision | Short rationale |
|---|----------|-----------------|
| [ADR-001](../decisions/0001-adopt-ai-sdlc.md) | Adopt the ai-sdlc-bootstrap workflow | Plan-first, TDD-enforced, docs-as-done, multi-agent compatible |

*Add new rows as ADRs accumulate.*

---

## Tech stack

| Layer | Tech | Key files |
|-------|------|-----------|
| Language(s) | {{LANGUAGES_LIST}} | — |
| Testing | {{TEST_FRAMEWORK}} | `{{TEST_DIRECTORY}}/` |
| CI | {{CI_HOST}} | `.github/workflows/ci.yml` |
| Build | {{BUILD_ENTRY_POINT}} | `Makefile` (or equivalent) |

*Add rows for: framework(s), databases, external services, third-party API integrations, deploy target.*

---

## Build and run

```bash
{{CHECK_COMMAND}}   # pre-commit gate — run before every commit
make setup-hooks    # one-time: installs pre-commit + post-commit hooks
```

**First-time setup**: see [`docs/dev-setup.md`](../dev-setup.md) for the full bootstrap (dependencies, tools, MCP servers, skills, language toolchains, environment variables). The dev-setup doc is the single source of truth for onboarding — if it's out of date, fix it in the same commit as whatever broke it.

Credentials (if any): see `.env.example` for the required variables. **Never** commit `.env`.

---

## Repository layout

```
.
├── README.md               # Project description + dev-setup pointer
├── LICENSE                 # {{LICENSE_SPDX}}
├── CODEOWNERS              # Default ownership
├── .gitignore              # Language-aware ignores
├── docs/                   # All project documentation
│   ├── agents/             # AGENT-CRITICAL: OVERVIEW.md, CONVENTIONS.md, STATUS.md
│   ├── decisions/          # ADRs
│   ├── CHANGELOG.md
│   ├── requirements.md
│   ├── issues.md
│   ├── manual-testing.md
│   ├── dev-setup.md        # Onboarding: deps, tools, MCP, skills, hooks
│   └── commit-log.md       # Append-only audit log: agent vs manual commits
├── project.deps.yaml       # Related projects (in-repo + external) — see § above
├── .project.lock.yaml      # Resolved local paths for external projects (gitignored)
├── scripts/
│   ├── setup-hooks.sh      # Installs pre-commit + post-commit
│   ├── agent-commit.sh     # Wrapper that adds the agent Co-Authored-By trailer
│   └── update-project-lock.sh / .ps1   # Refreshes .project.lock.yaml
├── CLAUDE.md / AGENTS.md / GEMINI.md / .cursor/rules/   # Agent entry points
├── CONTRIBUTING.md         # Workflow + merge policy + commit tracking + hygiene
├── Makefile                # `make check`, `make setup-hooks`
├── .github/workflows/ci.yml
└── src/ (or equivalent)
```

*Update this tree as the project grows. Agents read it to navigate.*

---

## Further reading

External docs / wikis that were used to inform this scaffold (read these for deeper context):

{{EXTERNAL_DOCS_LIST}}
