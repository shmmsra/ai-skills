---
name: ai-sdlc-bootstrap
description: Bootstraps an AI-driven Software Development Lifecycle on any git repository (new or existing). Sets up multi-agent config (Claude/Codex/Cursor/Gemini), in-repo ticket tracking (or GitHub/JIRA bridge), strict TDD + manual-test workflow, ADR template, pre/post-commit gates, manual-vs-agent commit tracking, merge-policy selection, repo-hygiene files (README/LICENSE/CODEOWNERS/.gitignore/IDE configs), and a dev-setup doc. Use when the user says "set up AI SDLC", "bootstrap agent workflow", "scaffold this project for agents", "set up Claude Code on this repo", or asks how to make a project agent-friendly.
---

# AI-Driven SDLC Bootstrap

You are about to set up a complete AI-driven software development lifecycle on a git repository. The output is a self-contained set of files that:

- Make the repo legible to any AI agent (Claude, Codex, Cursor, Gemini) without external context
- Force a **Plan → Approve → Implement → Test → Diff → Commit-approval** workflow
- Track tickets in-repo (or bridge to GitHub Issues / JIRA), so agents never need API access for status
- Enforce TDD via a pre-commit gate (`make check`) that mirrors CI
- Track *every* commit's author kind (human vs agent) via trailer + post-commit hook + audit log
- Encode the team's merge policy (direct-to-main vs PR-required) and require the agent to follow it
- Scaffold missing repo-hygiene files (README, LICENSE, CODEOWNERS, .gitignore, IDE configs, dev-setup doc) — only the ones the user asks for
- Treat documentation updates as part of "done" for every feature
- Record architectural decisions in ADRs so future agents understand *why*, not just *what*

## When to use this skill

Invoke when the user asks any of:
- "Set up AI SDLC on this project"
- "Bootstrap agent workflow"
- "Scaffold this repo for Claude / Codex / Cursor"
- "Make this project agent-friendly"
- "How do I run multiple AI agents on this codebase"

If the repo already has the full `docs/agents/` triad plus matching agent-config files (`CLAUDE.md`, `AGENTS.md`, etc.) all pointing at it, do **not** re-scaffold everything from scratch. Then:

- **General re-invocation** ("set up AI SDLC" again, no specifics): tell the user setup is already in place and ask which specific area they want to add or update (hygiene files, ticket source, merge policy, related projects/multi-repo, etc.).
- **Targeted request** (the user already named a specific area — e.g. "add project dependencies," "add multi-repo support," "set up a JIRA bridge," "add the CODEOWNERS file"): don't stop at a generic "already set up" message. Re-run Phase 1 (ASSESS) to refresh detection for that area — for related projects specifically, this means checking for `project.deps.yaml` per `reference/assessment.md` — then jump straight to the relevant part of Phase 2 (e.g. Round 6 for related projects, Round 4 for hygiene files) and proceed through Phases 3–4 for just that piece. A named request is enough signal to act on directly; don't make the user repeat themselves through a generic menu first.

---

## The flow (5 phases — never skip)

### Phase 1: ASSESS (always first, no questions yet)

Run the assessment commands in `reference/assessment.md` to classify the target repo before asking anything. The reference covers:

- Commit history, file count, language detection (existing)
- Test framework + CI presence (existing)
- **Repository hygiene inventory** (new) — README, LICENSE, CODEOWNERS, .gitignore, IDE configs, dev-setup doc
- **Multi-repo signal** — presence of `project.deps.yaml` (see `reference/multi-repo.md`); if present, Round 6 of the interview skips its yes/no and goes straight to add/edit/remove

State your classification to the user in one short paragraph, including which hygiene files are present vs missing.

### Phase 1.5: DISCOVER external context (new)

Before the interview, read **`reference/discovery.md`** and ask the user for any external docs / wikis / design docs that help understand the project. Read them. Feed insights into:

- Interview defaults (especially Q16 domain rules — pre-fill from what you found rather than asking blind)
- The `OVERVIEW.md` "Further reading" section (`{{EXTERNAL_DOCS_LIST}}`)
- Seeded `.claude/memory/reference_*.md` entries for external systems referenced

If the user has nothing to share, record `{{EXTERNAL_DOCS_LIST}}` as `*(none)*` and proceed.

### Phase 2: INTERVIEW (ask, then stop)

Read **`reference/questionnaire.md`** for the full branching question bank, now spanning 5 rounds:

- **Round 1** — identity, agent targets, ticket source, build entry point
- **Round 2** — test framework, plan threshold, approval gates
- **Round 3 (new)** — collaboration contract: co-author trailers, manual-commit review policy, merge policy (direct vs PR), manual-test requirement
- **Round 4 (new)** — repo hygiene: README / LICENSE / CODEOWNERS / .gitignore / dev-setup / IDE configs (only ask about the ones missing)
- **Round 5 (optional)** — domain hard constraints (skip if Discover surfaced them already)
- **Round 6 (optional, new)** — related projects (multi-repo/monorepo): default No, skip entirely unless the user opts in or `project.deps.yaml` already exists

Use `AskUserQuestion` (≤ 4 questions per call). Skip rounds whose answers are obvious from assessment or discovery. Don't make this an interrogation.

After collecting answers, summarize them back and ask: *"Anything wrong with this picture? If not, I'll write the plan."*

### Phase 3: PLAN (write it, post it, wait for `lgtm`)

This skill teaches the Plan→Approve workflow. **Practice it now.** Before writing any file in the target repo:

1. List every file you will create or modify in the target repo, with a one-line "why" for each.
2. State what you will **not** do (e.g. "will not touch existing tests", "will not overwrite CONTRIBUTING.md — will append a `## AI Agent Workflow` section instead").
3. **Proactive improvements need explicit consent.** If you noticed an existing agent-config file, CONTRIBUTING section, or doc that you'd strongly recommend improving — call it out as a separate item, explain why, and let the user accept/reject *per file*. Do not bundle improvements with required additions.
4. Post the plan. **Stop.** Wait for the human to reply with `lgtm` / `approved` / `go ahead`.

Silence is not approval. If the human edits or pushes back, regenerate the plan.

### Phase 4: SCAFFOLD (write files, run checks, report)

When approved:

1. Read the relevant template files from `templates/` and fill in the `{{TOKENS}}` from interview answers. See `reference/tokens.md` for the exhaustive list, including new tokens added in this version:
   - **Collaboration contract**: `{{COAUTHOR_AGENT}}`, `{{COAUTHOR_NAME}}`, `{{COAUTHOR_EMAIL}}`, `{{COAUTHOR_LINE}}`, `{{MANUAL_COMMIT_REVIEW}}`, `{{MERGE_POLICY}}`, `{{MERGE_POLICY_BLOCK}}`
   - **Hygiene**: `{{SCAFFOLD_HYGIENE_FILES}}`, `{{LICENSE_SPDX}}`, `{{LICENSE_HOLDER}}`, `{{LICENSE_YEAR}}`, `{{IDE_TARGETS}}`
   - **Discovery**: `{{EXTERNAL_DOCS_LIST}}`
   - **Related projects**: `{{MULTI_REPO_ENABLED}}`

2. **Order of writes** (do not parallelize — later files reference earlier ones):
   1. `docs/agents/{OVERVIEW,CONVENTIONS,STATUS}.md` (canonical rules — everything points here)
   2. `CONTRIBUTING.md`
   3. `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/{{PROJECT_SLUG}}.mdc` (only the ones selected)
   4. `docs/CHANGELOG.md`, `docs/requirements.md`, `docs/manual-testing.md`
   5. `docs/issues.md` (the appropriate variant: inrepo / github / jira)
   6. `docs/decisions/README.md` (ADR template) and `docs/decisions/0001-adopt-ai-sdlc.md` (first ADR)
   7. **`docs/dev-setup.md`** (if selected) — dependencies / tools / MCP / skills / repo setup commands
   8. **`docs/commit-log.md`** (always, if `MANUAL_COMMIT_REVIEW != convention-only`) — append-only audit log of commits with author kind
   9. `Makefile` (only if user accepted; otherwise emit `scripts/check.sh`)
   10. `scripts/setup-hooks.sh` (now installs **both** pre-commit and post-commit hooks)
   11. **`scripts/agent-commit.sh`** (if `{{COAUTHOR_AGENT}} == yes`) — helper that adds the agent's Co-Authored-By trailer
   12. **`project.deps.yaml` + `scripts/update-project-lock.sh` + `scripts/update-project-lock.ps1`** (only if `{{MULTI_REPO_ENABLED}} == yes`) — written from the Round 6 answers; the initial `.project.lock.yaml` is produced afterward by invoking the script (see step 4 below), never hand-written. When writing `CONTRIBUTING.md` §14 and `OVERVIEW.md`'s Related-projects section in the steps above, don't summarize *which* projects were just declared — see non-negotiable rule 10.
   13. `.github/workflows/ci.yml` (only if user picked GitHub Actions)
   14. **Hygiene files** (only those selected in Q13):
       - `README.md` (new or appended)
       - `LICENSE` (resolved from `{{LICENSE_SPDX}}`: `templates/LICENSE-MIT.txt`, `templates/LICENSE-APACHE-2.0.txt`, or proprietary stub)
       - `CODEOWNERS`
       - `.gitignore` (new or merged — see `reference/language-presets.md` for per-language blocks)
       - `.editorconfig`
       - `.vscode/settings.json` + `.vscode/extensions.json` (if VS Code in `{{IDE_TARGETS}}`)
       - `.zed/settings.json` (if Zed in `{{IDE_TARGETS}}`)
   15. `.claude/memory/MEMORY.md` (Claude-only; seed with user role + project goal placeholders, plus any reference memories drafted from Discover)

3. **For existing projects**: never overwrite a file silently.
   - If `CONTRIBUTING.md` exists → propose a merge (append an `## AI Agent Workflow` section pointing to `docs/agents/`). Show the diff before writing.
   - If `Makefile` exists → add only the missing targets.
   - If `README.md` exists → propose appending only a `## AI-Driven SDLC` section linking to CONTRIBUTING and dev-setup. Never rewrite the existing content.
   - If `.gitignore` exists → append only entries not already present (see `reference/language-presets.md`).
   - If an existing agent-config file looks improvable (stale, missing key sections), **you may propose a rewrite** — but only after listing the specific gaps and getting per-file consent in the plan step.
   - If `project.deps.yaml` exists → always rewrite both `scripts/update-project-lock.{sh,ps1}` from the current template (propagates engine fixes) even if the manifest itself doesn't change; show the diff either way. See `reference/multi-repo.md`.

4. After writing, run:
   ```bash
   make setup-hooks   # installs pre-commit + post-commit
   make check         # baseline — may fail; that's the starting test count
   ```
   Report the result. If `make check` fails because there are no tests yet, that's expected for a green-field project — say so.

   If `{{MULTI_REPO_ENABLED}} == yes`, also produce the initial `.project.lock.yaml` now by invoking the script non-interactively with the local paths gathered in Round 6 — e.g. `bash scripts/update-project-lock.sh --set widgets-core=/path/from/interview --yes`. Never hand-write `.project.lock.yaml`; the script is the only thing that writes it, including this first time.

5. **Do not commit.** Per the workflow you just installed, the human approves the commit. Show the diff summary, list files written, and wait.

---

## Detailed references (read on demand)

| Need | Read |
|------|------|
| Classifying new vs existing project, hygiene-file inventory, what to preserve | `reference/assessment.md` |
| External-context discovery (wikis, design docs, etc.) before interview | `reference/discovery.md` |
| Full question bank with branching logic (5 rounds) | `reference/questionnaire.md` |
| Exhaustive token reference for substitution | `reference/tokens.md` |
| How `.claude/memory/` works + recommended seed entries (including memories drafted from Discover) | `reference/memory-and-context.md` |
| Per-language detection, Makefile snippets, sample test stub, `.gitignore` blocks | `reference/language-presets.md` |
| Related-projects design: schema, resolution algorithm, cycle detection, script flags, platform notes | `reference/multi-repo.md` |

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
| `docs/dev-setup.md` | `templates/docs/dev-setup.md` |
| `docs/commit-log.md` | `templates/docs/commit-log.md` |
| `docs/decisions/README.md` | `templates/docs/decisions-README.md` |
| `docs/decisions/0001-adopt-ai-sdlc.md` | `templates/docs/decisions-0001-example.md` |
| `docs/issues.md` (in-repo) | `templates/docs/issues-inrepo.md` |
| `docs/issues.md` (GitHub) | `templates/docs/issues-github.md` |
| `docs/issues.md` (JIRA) | `templates/docs/issues-jira.md` |
| `Makefile` | `templates/Makefile` |
| `scripts/setup-hooks.sh` | `templates/scripts/setup-hooks.sh` |
| `scripts/agent-commit.sh` | `templates/scripts/agent-commit.sh` |
| `.github/workflows/ci.yml` | `templates/ci-github-actions.yml` |
| `.claude/memory/MEMORY.md` (seed) | `templates/claude-memory/README.md` |
| `README.md` (if scaffolded) | `templates/README.md` |
| `LICENSE` (MIT) | `templates/LICENSE-MIT.txt` |
| `LICENSE` (Apache-2.0) | `templates/LICENSE-APACHE-2.0.txt` |
| `CODEOWNERS` | `templates/CODEOWNERS` |
| `.gitignore` | `templates/gitignore.template` (plus per-language blocks from `reference/language-presets.md`) |
| `.vscode/settings.json` | `templates/vscode/settings.json` |
| `.vscode/extensions.json` | `templates/vscode/extensions.json` |
| `project.deps.yaml` (only if `{{MULTI_REPO_ENABLED}} == yes`) | `templates/project.deps.yaml` |
| `scripts/update-project-lock.sh` (only if `{{MULTI_REPO_ENABLED}} == yes`) | `templates/scripts/update-project-lock.sh` |
| `scripts/update-project-lock.ps1` (only if `{{MULTI_REPO_ENABLED}} == yes`) | `templates/scripts/update-project-lock.ps1` |

---

## Non-negotiable rules while running this skill

1. **Never run `git push`, `git init`, or `git commit` in the target repo.** This skill installs a workflow that says agents never push. Practice what you preach.
2. **Never overwrite an existing file without showing the diff first** and getting explicit approval. For existing projects, default to *append* or *create-adjacent* rather than overwrite.
3. **Improvement proposals need consent per-file.** If you think an existing CLAUDE.md / CONTRIBUTING.md / agent config is improvable, list it as a separate plan item with a one-line rationale. Don't fold it into the "required additions" bucket.
4. **Plan-before-write is the workflow you're installing.** Run it on yourself: post the plan, wait for `lgtm`, then write.
5. **Templates have `{{TOKENS}}`** — never write a template to the target with tokens still present. Search the written file for `{{` after each write; if any remain, you missed a substitution.
6. **The skill is agent-agnostic.** Do not encode Claude-specific assumptions into shared templates. Claude-specific bits go only in `CLAUDE.md`, `.claude/memory/`.
7. **The skill is project-agnostic.** Never copy domain-specific terms from any reference project into the target. Every project-specific value comes from the interview, not from templates or examples baked into this skill.
8. **The commit-tracking system is opt-in.** If the user picks `convention-only` in Q10, do *not* install the post-commit hook or scaffold `docs/commit-log.md`.
9. **Related-projects support is opt-in.** Never write `project.deps.yaml`, the two lock-resolution scripts, or any of the associated doc sections unless Round 6 was explicitly accepted (or `project.deps.yaml` already existed). Never hand-write `.project.lock.yaml` — only the script writes it, even the first time.
10. **Never summarize the Round 6 answers into `CONTRIBUTING.md` §14, `OVERVIEW.md`, or any other doc.** A sentence like "this repo's related projects are X, Y, Z, addressing paths under W" duplicates data that lives in `project.deps.yaml`/`.project.lock.yaml` and goes stale the moment an entry changes — exactly the drift the manifest/lock split exists to prevent. Reference those files generically; don't restate their contents.

---

## What "good" looks like

After scaffolding, the target repo should have this structure (the new bits are flagged with *new*):

```
.
├── README.md                                                  # new or appended (if selected)
├── LICENSE                                                    # new (if selected)
├── CODEOWNERS                                                 # new (if selected)
├── .gitignore                                                 # new or merged (if selected)
├── .editorconfig                                              # new (if selected)
├── .vscode/, .zed/                                            # new (if selected in IDE_TARGETS)
├── CLAUDE.md / AGENTS.md / GEMINI.md / .cursor/rules/*.mdc   # thin adapters → docs/agents/
├── CONTRIBUTING.md                                            # workflow + merge policy + commit tracking + hygiene rules
├── docs/
│   ├── agents/{OVERVIEW,CONVENTIONS,STATUS}.md                # canonical rules triad
│   ├── CHANGELOG.md, requirements.md, manual-testing.md
│   ├── dev-setup.md                                           # new — installation + tooling + MCP/skills
│   ├── commit-log.md                                          # new — manual vs agent commit audit log
│   ├── issues.md                                              # in-repo / GitHub / JIRA bridge
│   └── decisions/                                             # ADR archive
├── scripts/
│   ├── setup-hooks.sh                                         # installs pre-commit + post-commit
│   ├── agent-commit.sh                                        # new — adds Co-Authored-By trailer
│   └── update-project-lock.sh / .ps1                          # new — only if related projects declared
├── project.deps.yaml                                          # new — only if related projects declared
├── .project.lock.yaml                                         # new, gitignored — only if related projects declared
├── Makefile                                                   # make check + make setup-hooks (+ make update-project-lock)
└── .github/workflows/ci.yml                                   # mirrors make check
```

The adapter files (`CLAUDE.md` etc.) never duplicate rules — they always point at `docs/agents/`. Any change to a rule is made in one place. That single-source-of-truth property is the load-bearing design choice.
