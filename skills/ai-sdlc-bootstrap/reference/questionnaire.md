# Interview Questionnaire

Goal: gather enough information to fill every `{{TOKEN}}` in the templates without asking more than necessary. Branch based on the assessment phase result.

## Tool

Use `AskUserQuestion` — it allows up to 4 questions per call and supports single-select / multi-select. Send up to four rounds (≤ 16 questions total, but ideally fewer — skip rounds when the answers can be inferred from assessment).

Don't make this an interrogation. If the project is **mature** and most defaults are obvious, collapse Rounds 1–4 into the fewest necessary single-select prompts.

---

## Round 1 (always asked) — identity, agents, tickets, build

**Question 1: Project identity**
- *"What's the project called, and what's a short one-line description?"*
- Free-text. Derive `{{PROJECT_NAME}}`, `{{PROJECT_SLUG}}` (kebab-case lowercase), `{{PROJECT_DESCRIPTION}}` from the answer.
- Also ask: *"What ticket ID prefix should we use?"* (e.g. `ACME`, `FOO`, `PROJ`). Derive `{{TICKET_PREFIX}}`. Default: first 2–4 letters of the project name, uppercased.

**Question 2: Agent targets** (multi-select)
- Default checked: all four — Claude Code, Codex/AGENTS.md, Cursor, Gemini.
- Let them uncheck any they don't use.

**Question 3: Ticket source** (single-select)
- `In-repo docs/issues.md` (recommended for solo devs / private repos / no external ticket system)
- `GitHub Issues` (recommended if the project is on GitHub and the team already uses Issues)
- `JIRA` (recommended for enterprise / cross-team workflows)
- If GitHub Issues: ask for the repo (`owner/name`). If JIRA: ask for the project key + base URL.

**Question 4: Build entry point** (single-select)
- `Makefile (make check, make setup-hooks)` — universal, recommended
- `Language-native (npm/poetry/cargo/go run scripts)` — for teams allergic to `make`
- `Just (justfile)` — modern alternative
- Derive `{{CHECK_COMMAND}}` accordingly.

---

## Round 2 — tests, plan threshold, approval gates

**Question 5: Test framework** (autodetect, confirm)
- Pre-fill the answer with what assessment found. Options:
  - Vitest / Jest / Mocha (TS/JS)
  - pytest / unittest (Python)
  - go test (Go) — built-in
  - cargo test (Rust) — built-in
  - Catch2 / GoogleTest (C++)
  - JUnit (Java)
  - Existing — keep what's there
- If "Existing — keep what's there", do not write any test config.

**Question 6: Starter failing test?**
- For **NEW** projects: default yes — write one failing test in the chosen framework as the seed for TDD.
- For **EARLY/MATURE**: default no — don't disturb the existing suite.

**Question 7: Non-trivial threshold** (single-select)
- *"What should trigger the mandatory plan-before-code step?"*
- Options:
  - `Standard defaults` — any new file, OR > 1 file modified, OR touches architecture/API/IPC boundaries
  - `Stricter` — any change to source code (only docs/typos skip the plan)
  - `Looser` — only multi-module / architectural changes
- Default: Standard defaults.

**Question 8: Approval gates** (multi-select)
- *"Which operations should always require explicit human approval, beyond plan + commit?"*
- Pre-built options (multi-select, all unchecked by default):
  - Production deployments
  - Database migrations / schema changes
  - Payment / billing code
  - Credential rotation / IAM changes
  - Deletion of user data
  - Anything that costs money to run
  - Cross-region or cross-org changes
- Plus free-text "Other".
- Each selection becomes an `{{APPROVAL_GATE_N}}` line in `docs/agents/CONVENTIONS.md`.

---

## Round 3 — collaboration policy (commits, reviews, merges)

These four questions encode the team's *human–agent collaboration contract*. They drive `CONTRIBUTING.md` §6/§10/§11 and the agent-config notes.

**Question 9: Co-authorship in commit messages** (single-select, default yes)
- *"Should AI agents add a `Co-Authored-By:` trailer to commit messages when they author the change? (Lets you see at a glance which commits an agent worked on.)"*
- Options:
  - `Yes — add Co-Authored-By trailer for every agent-authored commit` (Recommended)
  - `No — keep commit messages clean of agent attribution`
- If yes, also ask for the trailer name + email to use. Defaults: `{agent} <noreply@anthropic.com>` for Claude, `<noreply@openai.com>` for Codex, `<noreply@google.com>` for Gemini, or a generic `AI Agent <noreply@example.com>`.
- Sets `{{COAUTHOR_AGENT}}`, `{{COAUTHOR_NAME}}`, `{{COAUTHOR_EMAIL}}`, `{{COAUTHOR_LINE}}`.

**Question 10: Manual-commit review policy** (single-select, default trailer-log)
- *"How should manual (non-agent) commits be tracked and scrutinised?"*
- Options:
  - `Trailer + log + agent-reviews-before-push` (Recommended) — every commit gets a trailer indicating its author kind; a post-commit hook appends to `docs/commit-log.md`. Before any `git push` / merge, the agent must review any commit tagged `[manual]`.
  - `Pre-commit blocks unreviewed manual commits` — stricter. The pre-commit hook refuses a manual commit unless it carries a `Manual-Review: <reason>` trailer or an `AGENT_REVIEWED=1` env var. Human can override but must do so explicitly.
  - `Convention only` — document the trailer convention but don't install any hook. Cheapest, easiest to ignore.
- Sets `{{MANUAL_COMMIT_REVIEW}}`.

**Question 11: Merge policy** (single-select)
- *"How does code reach `main`?"*
- Options:
  - `Direct merge after local review` — agent + human review locally, fast-forward / rebase into `main` directly. Suitable for solo devs and small trusted teams.
  - `PR required via branch` — every change goes via a feature branch and PR. Suitable for teams and any project with external contributors or required GitHub reviews.
- No default — make the user pick. Sets `{{MERGE_POLICY}}` and drives `{{MERGE_POLICY_BLOCK}}` in CONTRIBUTING + agent configs.

**Question 12: Manual testing requirement** (single-select, default yes)
- *"For runtime-affecting changes, does the agent need to write a manual test plan and wait for you to run it before committing? (Recommended: yes.)"*
- Options:
  - `Yes — manual test plan required for runtime-affecting changes` (Recommended)
  - `No — recommended but not gated`
- Sets `{{MANUAL_TEST_REQUIRED}}` and `{{MANUAL_TEST_REQUIRED_TEXT}}` / `{{MANUAL_TEST_REQUIRED_TEXT_LONG}}`.

---

## Round 4 — repository hygiene & dev environment

Skip any question whose file already exists in the repo (assessment recorded this). Only ask about the *missing* hygiene files.

**Question 13: Hygiene files to scaffold** (multi-select, pre-checked for what's missing)
- *"Which of these hygiene files should I scaffold? (Pre-checked items are missing from your repo.)"*
- Options (each only checked if missing):
  - `README.md` — project description + dev-setup pointer + AI-SDLC section
  - `LICENSE` — pick SPDX in the next question if checked
  - `CODEOWNERS` — starter file with the project owner as the default
  - `.gitignore` — language-aware (TypeScript/Python/Go/Rust/C++/Java blocks based on detection)
  - `.editorconfig` — minimal editor config (only useful if mixing IDEs)
  - `docs/dev-setup.md` — dependency / tools / MCP / skills installation guide
  - `docs/commit-log.md` — append-only audit log of manual vs agent commits (always recommended if `{{MANUAL_COMMIT_REVIEW}}` is `trailer-log` or `pre-commit-block`)
- Each selection appends to `{{SCAFFOLD_HYGIENE_FILES}}`.

**Question 14: License choice** (single-select; only ask if `LICENSE` was checked in Q13)
- *"Which license?"*
- Options:
  - `MIT` (Recommended for permissive open source)
  - `Apache-2.0` (Recommended for open source where patent grant matters)
  - `Proprietary — All rights reserved` (Recommended for internal / closed-source)
  - `None — leave it out for now`
- If MIT or Apache-2.0: also ask for the copyright holder name (default: `git config user.name`).
- Sets `{{LICENSE_SPDX}}`, `{{LICENSE_HOLDER}}`, `{{LICENSE_YEAR}}` (= `date +%Y`).

**Question 15: IDE targets** (multi-select; only ask if any IDE config is missing)
- *"Which IDE / editor configs should I scaffold? (Each adds workspace settings + recommended extensions.)"*
- Options (pre-checked based on agent targets and detected configs):
  - `VS Code` — `.vscode/settings.json` + `.vscode/extensions.json`
  - `Cursor` — `.cursor/rules/{{PROJECT_SLUG}}.mdc` (already covered if Cursor is in `{{AGENT_TARGETS}}`)
  - `JetBrains` — `.gitignore` entries only; we don't write proprietary IDE configs
  - `Zed` — `.zed/settings.json`
- Sets `{{IDE_TARGETS}}`.

---

## Round 5 (optional) — domain rules

**Question 16: Domain hard constraints** (free-text, 0–3)
- *"Are there any architectural or domain rules that must never be violated? Examples: 'no network calls from the rendering engine', 'no PII in logs', 'all SQL goes through the ORM'. Up to three."*
- Free-text, 0–3 entries. Each becomes a `{{DOMAIN_RULE_N}}` in `docs/agents/CONVENTIONS.md`.

If you collected enough hints during the Discover phase to draft these yourself, propose them back to the user instead of asking blind.

---

## Round 6 (optional) — related projects (multi-repo / monorepo)

Fully optional — most repos skip this entirely. Read `reference/multi-repo.md` for the full design before running this round.

**Gating** (decide before asking anything):
- If assessment found `project.deps.yaml` already present → skip the yes/no. Summarize the existing entries back to the user and ask: *"This repo already declares related projects: `<name>` (in-repo / external), ... Add, remove, or edit any, or keep as-is?"*
- Otherwise, ask a single-select question, **default No**:

**Question 17: Related projects** (single-select, default No)
- *"Does this repo have relationships with other projects that agents should be aware of — either sub-projects inside this repo (monorepo), or external repos you develop against?"*
- Options:
  - `No — this repo is self-contained` (Recommended)
  - `Yes — let's declare them`
- If No: write nothing. `{{MULTI_REPO_ENABLED}} = no`. Skip the rest of this round entirely — no `project.deps.yaml`, no scripts, no OVERVIEW.md section, no CONTRIBUTING §14, no adapter-file lines.

**If Yes**, set `{{MULTI_REPO_ENABLED}} = yes` and, for each related project the user describes, gather:

- **Name** — free text, used as the unique key.
- **Kind** — single-select: `In-repo (sub-project of this monorepo)` or `External (a different git repository)`.
  - If **in-repo**: ask for the `path` (relative to this repo's root). Then ask, per-file consent: *"Should I scaffold a nested `AGENTS.md` at `<path>` now, so agents working there get scoped instructions? (This is the standard nested-AGENTS.md mechanism — the nearest file wins.)"* Default: offer, let the user decline per entry.
  - If **external**: ask for the `repo` (git remote URL) and, optionally, a `path` if the dependency is itself a monorepo and only one package inside it matters here. Then ask for the local path: *"Where is `<name>` checked out locally on this machine? Leave blank if you don't have it yet or want me to clone it."* If blank, ask: *"Clone `<repo>` into the sibling directory `../<name>`?"*
- **Notes** — free text, always ask: *"In a sentence or two, what does `<name>` hold, and when should an agent working here go read its docs? (Any acronyms are worth mentioning here too.)"* This is the field that makes cross-project awareness actually work — don't let the user skip it with something empty.
- **Required** — default `true`; ask only if the user signals a dependency is optional/best-effort.

Repeat for each additional related project (`AskUserQuestion` supports up to 4 per call — batch where sensible, don't turn this into an interrogation for a long list).

After the round: for every external entry where a local path was given or a clone was accepted, note it — Phase 4 (SCAFFOLD) will write `project.deps.yaml` from these answers and then invoke `scripts/update-project-lock.sh --set name=path ... --yes` (never hand-write `.project.lock.yaml` — the script is the only thing that writes it, even for the very first resolution).

---

## Tokens populated by interview

After all rounds, you should have values for:

**Identity / build**
- `{{PROJECT_NAME}}`, `{{PROJECT_SLUG}}`, `{{PROJECT_DESCRIPTION}}`, `{{PROJECT_OWNER}}`, `{{TODAY}}`
- `{{TICKET_PREFIX}}`, `{{TICKET_PREFIX_LOWER}}`, `{{TICKET_SOURCE}}`, `{{TICKET_SOURCE_DESCRIPTION}}`, `{{GITHUB_OWNER_REPO}}` *or* `{{JIRA_PROJECT_KEY}}` + `{{JIRA_BASE_URL}}`
- `{{AGENT_TARGETS}}`, `{{AGENT_CONFIG_FILES_LIST}}`
- `{{BUILD_ENTRY_POINT}}`, `{{LANGUAGE}}`, `{{LANGUAGES_LIST}}`
- `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`, `{{TEST_DIRECTORY}}`, `{{TYPECHECK_COMMAND}}`, `{{CHECK_COMMAND}}`

**Workflow**
- `{{STARTER_TEST}}` — `yes`/`no`
- `{{NONTRIVIAL_DEFINITION}}` + `{{NONTRIVIAL_DEFINITION_BLOCK}}`
- `{{APPROVAL_GATES}}` + `{{APPROVAL_GATES_LIST}}` + `{{APPROVAL_GATES_BLOCK}}`
- `{{DOMAIN_RULES}}` + `{{DOMAIN_RULES_BLOCK}}`
- `{{MANUAL_TEST_REQUIRED}}` + `{{MANUAL_TEST_REQUIRED_TEXT}}` + `{{MANUAL_TEST_REQUIRED_TEXT_LONG}}`

**Collaboration contract (Round 3 — new)**
- `{{COAUTHOR_AGENT}}` — `yes`/`no`
- `{{COAUTHOR_NAME}}`, `{{COAUTHOR_EMAIL}}`, `{{COAUTHOR_LINE}}` — only meaningful if `COAUTHOR_AGENT == yes`
- `{{MANUAL_COMMIT_REVIEW}}` — `trailer-log` / `pre-commit-block` / `convention-only`
- `{{MERGE_POLICY}}` — `direct` / `pr-required`
- `{{MERGE_POLICY_BLOCK}}` — multi-line prose for CONTRIBUTING §6 derived from the choice

**Hygiene (Round 4 — new)**
- `{{SCAFFOLD_HYGIENE_FILES}}` — comma list of selected hygiene files
- `{{LICENSE_SPDX}}` — `MIT` / `Apache-2.0` / `Proprietary` / `None`
- `{{LICENSE_HOLDER}}`, `{{LICENSE_YEAR}}`
- `{{IDE_TARGETS}}` — comma list

**Discovery (Phase 1.5 — new)**
- `{{EXTERNAL_DOCS_LIST}}` — bulleted list of URLs / file paths read during Discover; included in `OVERVIEW.md` "Further reading" section

**Related projects (Round 6 — optional)**
- `{{MULTI_REPO_ENABLED}}` — `yes`/`no`. When `no`, skip `project.deps.yaml`, both scripts, the `OVERVIEW.md` "Related projects" section, `CONTRIBUTING.md §14`, the `CONVENTIONS.md` sub-section, the adapter-file lines, the `Makefile` target, and the `.gitignore` line — none of it is written.

`OVERVIEW.md`'s "Related projects" section is static prose pointing at `.project.lock.yaml` — there's no table to render from the interview answers, since the resolved, agent-facing detail (including `notes`) lives in the lock file, generated by the script, not by this interview.

If any token is missing after the rounds, ask — don't guess and don't leave `{{TOKENS}}` in the written files.

---

## Summarize and confirm

Before moving to Phase 3 (plan), echo the answers back as a bulleted list and ask: *"Anything wrong with this picture?"* This gives the user a chance to correct mishears before you commit the answers to templates.
