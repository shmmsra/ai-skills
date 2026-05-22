# Project Assessment

Classify the target repo before asking any interview question. The classification decides what to preserve, what to scaffold from scratch, and which questions to skip.

## Classification matrix

| Signal | New | Early | Mature |
|--------|-----|-------|--------|
| Commit count | ≤ 5 | 6–50 | > 50 |
| Source file count (excl. vendored) | ≤ 10 | 11–100 | > 100 |
| Existing CI workflow | none | maybe | yes |
| Existing test suite | none | partial | established |
| Existing `CONTRIBUTING.md` | no | maybe | usually |
| Existing `docs/` directory | no | basic | rich |

Edge cases:
- A fresh fork with thousands of commits but no recent activity is **mature** — the codebase is established.
- A repo with one giant initial commit dumping a generated project is **new** — no real history to learn from.
- A repo with extensive docs but zero tests is still **mature for docs purposes** — preserve them — but **new for testing purposes** — write the gate from scratch.

When in doubt: ask the user. *"This looks like an early-stage repo to me — is that right? Or have I missed something?"*

## What to preserve, per category

### NEW (no real prior art)
- Scaffold everything from templates verbatim.
- Pick sensible defaults: Conventional Commits, GitHub Actions, in-repo `docs/issues.md`, language detection by first lockfile created.
- Write a starter failing test if the user opts in (default: yes).
- Initial ADR is `0001-adopt-ai-sdlc.md`.

### EARLY (5–50 commits, some scaffolding)
- **Preserve**: any existing `CONTRIBUTING.md`, `README.md`, test framework, Makefile/script entry points, CI workflow.
- **Augment**: append an `## AI Agent Workflow` section to existing `CONTRIBUTING.md` pointing at `docs/agents/`. Don't overwrite.
- **Detect**: existing scope conventions in commit messages — `git log --pretty=format:"%s" | grep -oE '^[a-z]+\([^)]+\)' | sort | uniq -c` — and feed them into the Conventional Commits section instead of imposing new scopes.
- **Skip**: writing starter tests if a framework is already configured. The user's existing tests are the source of truth.
- **Backfill**: walk `git log` for the last ~10 commits; ask the user if any of them deserve being recorded in `docs/CHANGELOG.md` as the seed history.

### MATURE (50+ commits, established infra)
- **Preserve everything by default.** The goal here is to add the agent-config layer without disrupting human contributors.
- **Most likely outputs**:
  - `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/*.mdc` — all new
  - `docs/agents/OVERVIEW.md`, `CONVENTIONS.md`, `STATUS.md` — all new
  - `docs/decisions/` — new if absent; otherwise leave alone
  - `docs/issues.md` — only if the user wants in-repo tracking; many mature projects already use GitHub/JIRA, so just write the bridge variant
  - Existing `CONTRIBUTING.md` — append, don't replace
- **Skip by default**:
  - Makefile changes (they have one)
  - CI changes (they have one)
  - Starter tests (they have a suite)
  - Conventional Commits enforcement (might disrupt existing style — ask before adding)
- **Read first**:
  - `README.md` — figure out what the project actually does, so `docs/agents/OVERVIEW.md` doesn't lie
  - Any existing `ARCHITECTURE.md`, `docs/architecture.md` — link from `OVERVIEW.md`, don't duplicate
  - Top 5 directories — for the "Tech stack" table in `OVERVIEW.md`

## Detection commands

Run these once during ASSESS, and feed results into the interview phase.

```bash
# Commit history
git rev-list --count HEAD 2>/dev/null || echo 0
git log --pretty=format:"%s" -n 20         # recent commits — also reveals their commit style

# File count (excluding common vendored / generated dirs)
find . -type f \
  -not -path './.git/*' -not -path './node_modules/*' \
  -not -path './dist/*' -not -path './build/*' -not -path './target/*' \
  -not -path './.venv/*' -not -path './venv/*' -not -path './__pycache__/*' \
  -not -path './vendor/*' | wc -l

# Language detection (presence of lockfiles + build configs)
ls package.json package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null      # Node/TS
ls pyproject.toml setup.py requirements.txt poetry.lock Pipfile 2>/dev/null # Python
ls go.mod go.sum 2>/dev/null                                                # Go
ls Cargo.toml Cargo.lock 2>/dev/null                                        # Rust
ls CMakeLists.txt 2>/dev/null                                               # C++
ls pom.xml build.gradle build.gradle.kts 2>/dev/null                        # Java/Kotlin
ls Gemfile Gemfile.lock 2>/dev/null                                         # Ruby
ls mix.exs 2>/dev/null                                                      # Elixir
ls deno.json deno.jsonc 2>/dev/null                                         # Deno

# Existing test framework
grep -l 'vitest\|jest\|mocha\|jasmine' package.json 2>/dev/null
grep -l 'pytest\|unittest\|nose' pyproject.toml setup.py 2>/dev/null
[ -d tests/ ] || [ -d test/ ] || [ -d __tests__/ ]    # test dirs

# Existing docs structure
ls docs/ 2>/dev/null
ls docs/decisions/ docs/adr/ docs/architecture/ 2>/dev/null  # existing ADR conventions

# Existing agent configs
ls CLAUDE.md AGENTS.md GEMINI.md .cursor/ .codex/ .github/copilot-instructions.md 2>/dev/null

# Existing build entry point
[ -f Makefile ] && grep -E '^(check|test|build|lint):' Makefile
[ -f justfile ] && cat justfile | head -30
[ -f package.json ] && grep -A 20 '"scripts"' package.json | head -30

# Existing CI
ls .github/workflows/ .gitlab-ci.yml .circleci/ azure-pipelines.yml 2>/dev/null
```

## Reporting the classification

After running the commands, give the user one short paragraph and stop:

> *"This is an **early-stage** TypeScript repo (24 commits, Vitest already configured, no `CONTRIBUTING.md`, no `docs/`, GitHub Actions CI in place). I'll preserve Vitest and the CI, scaffold the full docs/agents triad, write a new `CONTRIBUTING.md`, and add agent configs for Claude, Codex, and Cursor. I won't touch your existing CI workflow or `package.json` scripts. Ready to ask the interview questions?"*

Wait for confirmation before moving to Phase 2.
