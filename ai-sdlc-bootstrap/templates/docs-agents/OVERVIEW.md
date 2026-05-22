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
make setup-hooks    # one-time: installs pre-commit hook
```

**First-time setup**:
1. Clone the repo.
2. Install dependencies (project-specific — document the command here).
3. Run `make setup-hooks` to install the pre-commit gate.
4. Run `{{CHECK_COMMAND}}` to verify the baseline.

Credentials (if any): see `.env.example` for the required variables. **Never** commit `.env`.

---

## Repository layout

```
.
├── docs/                   # All project documentation
│   ├── agents/             # AGENT-CRITICAL: OVERVIEW.md, CONVENTIONS.md, STATUS.md
│   ├── decisions/          # ADRs
│   ├── CHANGELOG.md
│   ├── requirements.md
│   ├── issues.md
│   └── manual-testing.md
├── CLAUDE.md / AGENTS.md / GEMINI.md / .cursor/rules/   # Agent entry points
├── CONTRIBUTING.md         # Workflow + non-negotiable rules
├── Makefile                # `make check`, `make setup-hooks`
├── .github/workflows/ci.yml
└── src/ (or equivalent)
```

*Update this tree as the project grows. Agents read it to navigate.*
