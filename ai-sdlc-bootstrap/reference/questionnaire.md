# Interview Questionnaire

Goal: gather enough information to fill every `{{TOKEN}}` in the templates without asking more than necessary. Branch based on the assessment phase result.

## Tool

Use `AskUserQuestion` — it allows up to 4 questions per call and supports single-select / multi-select. Send up to two rounds (≤ 8 questions total). Don't make this an interrogation.

## Round 1 (always asked)

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

## Round 2 (asked after Round 1 answers known)

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

## Round 3 (optional — only if user said "yes, ask more" or if domain rules emerged from the README)

**Question 9: Domain hard constraints**
- *"Are there any architectural or domain rules that must never be violated? Examples: 'no network calls from the rendering engine', 'no PII in logs', 'all SQL goes through the ORM'. Up to three."*
- Free-text, 0–3 entries. Each becomes a `{{DOMAIN_RULE_N}}` in `docs/agents/CONVENTIONS.md`.

**Question 10: Manual testing requirement**
- *"For runtime-affecting changes, does the agent need to write a manual test plan and wait for you to run it before committing? (Recommended: yes.)"*
- Yes / No. If no, the `Manual testing before commit` section in `CONTRIBUTING.md` is reduced to a recommendation rather than a gate.

## Tokens populated by interview

After Round 2 (and 3 if asked), you should have values for:

- `{{PROJECT_NAME}}`
- `{{PROJECT_SLUG}}`
- `{{PROJECT_DESCRIPTION}}`
- `{{TICKET_PREFIX}}`
- `{{TICKET_SOURCE}}` — one of `inrepo` / `github` / `jira`
- `{{GITHUB_OWNER_REPO}}` — only if `{{TICKET_SOURCE}} == github`
- `{{JIRA_PROJECT_KEY}}` and `{{JIRA_BASE_URL}}` — only if `{{TICKET_SOURCE}} == jira`
- `{{AGENT_TARGETS}}` — comma list, e.g. `claude,codex,cursor,gemini`
- `{{BUILD_ENTRY_POINT}}` — `make` / `npm` / `just` / etc.
- `{{LANGUAGE}}` — primary, e.g. `typescript`
- `{{LANGUAGES_LIST}}` — comma list
- `{{TEST_FRAMEWORK}}` — e.g. `vitest`
- `{{TEST_COMMAND}}` — exact command, e.g. `npm test`
- `{{TYPECHECK_COMMAND}}` — exact command, e.g. `npm run typecheck` (empty for dynamically-typed langs that don't use one)
- `{{CHECK_COMMAND}}` — the body of `make check`, derived from the above
- `{{STARTER_TEST}}` — `yes` / `no`
- `{{NONTRIVIAL_DEFINITION}}` — one of three preset blocks
- `{{APPROVAL_GATES}}` — list of selected gates
- `{{DOMAIN_RULES}}` — list of free-text rules
- `{{MANUAL_TEST_REQUIRED}}` — `yes` / `no`
- `{{TODAY}}` — `YYYY-MM-DD` of the scaffold run

If any token is missing after Round 2, ask in Round 3 — don't guess and don't leave `{{TOKENS}}` in the written files.

## Summarize and confirm

Before moving to Phase 3 (plan), echo the answers back as a bulleted list and ask: *"Anything wrong with this picture?"* This gives the user a chance to correct mishears before you commit the answers to templates.
