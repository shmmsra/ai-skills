---
name: ai-sdlc-bootstrap
description: Bootstraps an AI-driven Software Development Lifecycle on any git repository (new or existing). Sets up multi-agent config (Claude/Codex/Cursor/Gemini), in-repo ticket tracking (or GitHub/JIRA bridge), strict TDD + manual-test workflow, ADR template, pre-commit gate, and documentation-as-part-of-done discipline. Use when the user says "set up AI SDLC", "bootstrap agent workflow", "scaffold this project for agents", "set up Claude Code on this repo", or asks how to make a project agent-friendly.
---

# AI-Driven SDLC Bootstrap

You are about to set up a complete AI-driven software development lifecycle on a git repository. The output is a self-contained set of files that:

- Make the repo legible to any AI agent (Claude, Codex, Cursor, Gemini) without external context
- Force a **Plan → Approve → Implement → Test → Diff → Commit-approval** workflow
- Track tickets in-repo (or bridge to GitHub Issues / JIRA), so agents never need API access for status
- Enforce TDD via a pre-commit gate (`make check`) that mirrors CI
- Treat documentation updates as part of "done" for every feature
- Record architectural decisions in ADRs so future agents understand *why*, not just *what*

## When to use this skill

Invoke when the user asks any of:
- "Set up AI SDLC on this project"
- "Bootstrap agent workflow"
- "Scaffold this repo for Claude / Codex / Cursor"
- "Make this project agent-friendly"
- "How do I run multiple AI agents on this codebase"

If the repo already has the full `docs/agents/` triad plus matching agent-config files (`CLAUDE.md`, `AGENTS.md`, etc.) all pointing at it, do **not** re-scaffold — tell the user the setup is already in place and ask whether they want to update specific files instead.

---

## The flow (4 phases — never skip)

### Phase 1: ASSESS (always first, no questions yet)

Run these commands in the target repo to classify it before asking anything:

```bash
git rev-list --count HEAD 2>/dev/null || echo 0    # commit count
find . -type f -not -path './node_modules/*' -not -path './.git/*' -not -path './dist/*' -not -path './build/*' -not -path './target/*' -not -path './.venv/*' | wc -l   # source-ish file count
ls -la                                              # top-level layout
[ -f package.json ] && cat package.json | head -30  # detect Node/TS
[ -f pyproject.toml ] && head -40 pyproject.toml    # detect Python
[ -f go.mod ] && head -10 go.mod                    # detect Go
[ -f Cargo.toml ] && head -10 Cargo.toml            # detect Rust
[ -f CMakeLists.txt ] && head -10 CMakeLists.txt    # detect C++
ls docs/ 2>/dev/null                                # existing docs to preserve
ls -A | grep -iE '^(claude\.md|agents\.md|gemini\.md|contributing\.md|\.cursor)' # existing agent configs
[ -f Makefile ] && grep -E '^(check|test|setup-hooks):' Makefile  # existing Makefile gates
ls .github/workflows/ 2>/dev/null                    # existing CI
```

Then read **`reference/assessment.md`** for the classification heuristics and what to preserve for each category (new / early / mature). Do not skip this read — it determines the rest of the flow.

State your classification to the user in one short paragraph: *"This is an N-commit Python project with pytest already configured, an existing CONTRIBUTING.md, no docs/agents/, no CI. I'll treat it as **early** — preserve pytest and CONTRIBUTING, fill in the agent-config layer and docs triad."*

### Phase 2: INTERVIEW (ask, then stop)

Read **`reference/questionnaire.md`** for the full branching question bank.

Use the `AskUserQuestion` tool to ask 4 questions at most per round (the tool's limit). The minimum set:

1. **Project identity**: project name, ticket prefix (e.g. `ACME`, `FOO`), short one-line description.
2. **Agent targets**: which of {Claude Code, Codex/AGENTS.md, Cursor, Gemini} to scaffold for (default all four).
3. **Ticket source**: in-repo `docs/issues.md` / GitHub Issues / JIRA.
4. **Test framework + CI**: confirm autodetected framework, choose CI host (GitHub Actions default), decide whether to write a starter failing test (default yes for new projects, no for mature).
5. **Non-trivial threshold**: what counts as "needs a plan" — file count? new file? cross-module? (offer the standard defaults: any new file, OR > 1 file modified, OR touches architecture/API boundaries).
6. **Approval gates**: any operations that should *always* require explicit human approval beyond plan/commit (e.g. database migrations, production deploys, payment code, deletion operations).
7. **Domain rules**: 1–3 hard constraints unique to this project (boundary that must never be crossed, e.g. "no network from pure layer X", "no PII in logs").

After collecting answers, summarize them back and ask: *"Anything wrong with this picture? If not, I'll write the plan."*

### Phase 3: PLAN (write it, post it, wait for `lgtm`)

This skill teaches the Plan→Approve workflow. **Practice it now.** Before writing any file in the target repo:

1. List every file you will create or modify in the target repo, with a one-line "why" for each.
2. State what you will **not** do (e.g. "will not touch existing tests", "will not overwrite CONTRIBUTING.md — will append a `## AI Agent Workflow` section instead").
3. Post the plan. **Stop.** Wait for the human to reply with `lgtm` / `approved` / `go ahead`.

Silence is not approval. If the human edits or pushes back, regenerate the plan.

### Phase 4: SCAFFOLD (write files, run checks, report)

When approved:

1. Read the relevant template files from `templates/` and fill in the `{{TOKENS}}` from interview answers. Token reference:
   - `{{PROJECT_NAME}}` — e.g. `Acme`
   - `{{PROJECT_SLUG}}` — kebab-case, e.g. `acme`
   - `{{PROJECT_DESCRIPTION}}` — one-line description
   - `{{TICKET_PREFIX}}` — e.g. `ACME`
   - `{{TICKET_SOURCE}}` — `inrepo` / `github` / `jira`
   - `{{LANGUAGE}}` — primary language, e.g. `typescript`
   - `{{LANGUAGES_LIST}}` — all detected, comma-separated
   - `{{TEST_FRAMEWORK}}` — e.g. `vitest`, `pytest`, `go test`
   - `{{CHECK_COMMAND}}` — the canonical `make check` body
   - `{{AGENT_TARGETS}}` — comma list of enabled adapters
   - `{{DOMAIN_RULE_1..N}}` — project-specific hard constraints
   - `{{APPROVAL_GATE_1..N}}` — operations requiring explicit human sign-off
   - `{{NONTRIVIAL_DEFINITION}}` — what triggers the plan step
   - `{{TODAY}}` — current date in `YYYY-MM-DD`

2. **Order of writes** (do not parallelize — later files reference earlier ones):
   1. `docs/agents/{OVERVIEW,CONVENTIONS,STATUS}.md` (canonical rules — everything points here)
   2. `CONTRIBUTING.md`
   3. `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/{{PROJECT_SLUG}}.mdc` (only the ones selected)
   4. `docs/CHANGELOG.md`, `docs/requirements.md`, `docs/manual-testing.md`
   5. `docs/issues.md` (the appropriate variant: inrepo / github / jira)
   6. `docs/decisions/README.md` (ADR template) and `docs/decisions/0001-adopt-ai-sdlc.md` (the first ADR records the decision to adopt this workflow)
   7. `Makefile` (only if user accepted; otherwise emit `scripts/check.sh`)
   8. `scripts/setup-hooks.sh`
   9. `.github/workflows/ci.yml` (only if user picked GitHub Actions)
   10. `.claude/memory/MEMORY.md` (Claude-only; seed with user role + project goal placeholders)

3. **For existing projects**: never overwrite a file silently. If `CONTRIBUTING.md` exists, propose a merge (append an `## AI Agent Workflow` section pointing to `docs/agents/`). If `Makefile` exists, add only the missing targets. Show the diff before writing.

4. After writing, run:
   ```bash
   make setup-hooks   # install pre-commit
   make check         # baseline — may fail; that's the starting test count
   ```
   Report the result. If `make check` fails because there are no tests yet, that's expected for a green-field project — say so.

5. **Do not commit.** Per the workflow you just installed, the human approves the commit. Show the diff summary, list files written, and wait.

---

## Detailed references (read on demand)

| Need | Read |
|------|------|
| Classifying new vs existing project, what to preserve | `reference/assessment.md` |
| Full question bank with branching logic | `reference/questionnaire.md` |
| Exhaustive token reference for substitution | `reference/tokens.md` |
| How `.claude/memory/` works + recommended seed entries | `reference/memory-and-context.md` |
| Per-language detection, Makefile snippets, sample test stub | `reference/language-presets.md` |

## Template index

Templates live in `templates/`. Always read the template right before writing the target file — do not embed template contents in your context until you need them.

| Target file | Template |
|-------------|----------|
| `CLAUDE.md` | `templates/CLAUDE.md` |
| `AGENTS.md` | `templates/AGENTS.md` |
| `GEMINI.md` | `templates/GEMINI.md` |
| `.cursor/rules/{{PROJECT_SLUG}}.mdc` | `templates/cursor-rules.mdc` |
| `CONTRIBUTING.md` | `templates/CONTRIBUTING.md` |
| `docs/agents/OVERVIEW.md` | `templates/docs-agents/OVERVIEW.md` |
| `docs/agents/CONVENTIONS.md` | `templates/docs-agents/CONVENTIONS.md` |
| `docs/agents/STATUS.md` | `templates/docs-agents/STATUS.md` |
| `docs/CHANGELOG.md` | `templates/docs/CHANGELOG.md` |
| `docs/requirements.md` | `templates/docs/requirements.md` |
| `docs/manual-testing.md` | `templates/docs/manual-testing.md` |
| `docs/decisions/README.md` | `templates/docs/decisions-README.md` |
| `docs/decisions/0001-adopt-ai-sdlc.md` | `templates/docs/decisions-0001-example.md` |
| `docs/issues.md` (in-repo) | `templates/docs/issues-inrepo.md` |
| `docs/issues.md` (GitHub) | `templates/docs/issues-github.md` |
| `docs/issues.md` (JIRA) | `templates/docs/issues-jira.md` |
| `Makefile` | `templates/Makefile` |
| `scripts/setup-hooks.sh` | `templates/scripts/setup-hooks.sh` |
| `.github/workflows/ci.yml` | `templates/ci-github-actions.yml` |
| `.claude/memory/MEMORY.md` (seed) | `templates/claude-memory/README.md` |

---

## Non-negotiable rules while running this skill

1. **Never run `git push`, `git init`, or `git commit` in the target repo.** This skill installs a workflow that says agents never push. Practice what you preach.
2. **Never overwrite an existing file without showing the diff first** and getting explicit approval. For existing projects, default to *append* or *create-adjacent* rather than overwrite.
3. **Plan-before-write is the workflow you're installing.** Run it on yourself: post the plan, wait for `lgtm`, then write.
4. **Templates have `{{TOKENS}}`** — never write a template to the target with tokens still present. Search the written file for `{{` after each write; if any remain, you missed a substitution.
5. **The skill is agent-agnostic.** Do not encode Claude-specific assumptions into shared templates. Claude-specific bits go only in `CLAUDE.md`, `.claude/memory/`.
6. **The skill is project-agnostic.** Never copy domain-specific terms from any reference project into the target. Every project-specific value comes from the interview, not from templates or examples baked into this skill.

---

## What "good" looks like

After scaffolding, the target repo should have this structure:

```
.
├── CLAUDE.md / AGENTS.md / GEMINI.md / .cursor/rules/*.mdc   # thin adapters → docs/agents/
├── CONTRIBUTING.md                                            # full workflow doctrine
├── docs/
│   ├── agents/{OVERVIEW,CONVENTIONS,STATUS}.md                # canonical rules triad
│   ├── CHANGELOG.md, requirements.md, manual-testing.md
│   ├── issues.md                                              # in-repo / GitHub / JIRA bridge
│   └── decisions/                                             # ADR archive
├── Makefile                                                   # make check + make setup-hooks
└── .github/workflows/ci.yml                                   # mirrors make check
```

The adapter files (`CLAUDE.md` etc.) never duplicate rules — they always point at `docs/agents/`. Any change to a rule is made in one place. That single-source-of-truth property is the load-bearing design choice.
