# {{PROJECT_NAME}} — Dev Environment Setup

> Canonical onboarding guide for {{PROJECT_NAME}}. Follow this top-to-bottom on a fresh clone.
>
> **If you add a new dependency, tool, MCP server, or agent skill while working in this repo, update this file in the same commit.** Onboarding the next agent on a fresh clone is the regression test.

---

## 1. Prerequisites — language toolchains

Install only the toolchain(s) that match `{{LANGUAGES_LIST}}`.

| Language | Required version | How to install |
|----------|------------------|----------------|
| {{LANGUAGE}} | *fill in min version* | *fill in install command — e.g. `brew install node@20`, `pyenv install 3.12`, `rustup default stable`, `go install`* |

*Add a row per language detected in the project. Keep version pins here in sync with whatever the build expects (`package.json` engines, `pyproject.toml`, `go.mod`, `rust-toolchain`).*

---

## 2. Clone and install dependencies

```bash
git clone <repo-url>
cd {{PROJECT_SLUG}}

# Install dependencies — pick the line that matches your language:
# Node / TypeScript:  npm ci         (or pnpm install / yarn install --frozen-lockfile)
# Python:             pip install -e '.[dev]'  (or poetry install)
# Go:                 go mod download
# Rust:               cargo fetch
# C++:                cmake -B build && cmake --build build --parallel
```

*Replace the comment block with the exact command(s) for this project.*

---

## 3. Required external tools / CLIs

| Tool | Purpose | Install |
|------|---------|---------|
| `git` | Version control | Pre-installed on macOS/Linux |
| `make` | Build entry point | `brew install make` / `apt install make` |

*Add rows for project-specific tools — e.g. `gh` CLI, `terraform`, `docker`, `kubectl`, `psql`, language-specific formatters/linters not bundled with the toolchain.*

---

## 4. Agent skills and MCP servers

This project integrates with the following agent skills / MCP servers. Install / authorise them in your local Claude Code / Codex / Cursor / Gemini setup before working in this repo.

| Skill / MCP | Purpose | How to install |
|-------------|---------|----------------|
| `ai-sdlc-bootstrap` | The skill that scaffolded this workflow (already applied) | n/a |

*Add rows when you integrate new skills or MCP servers. Include the install command + any auth steps. If a skill is required for an end-to-end test path, note that here.*

---

## 5. Install the git hooks (one-time)

```bash
make setup-hooks
```

This installs:

- **pre-commit** — runs `{{CHECK_COMMAND}}` before every commit. Aborts if anything fails.
- **post-commit** — appends a row to `docs/commit-log.md` tagging the commit as `agent` or `manual`. (Skipped if `MANUAL_COMMIT_REVIEW = convention-only`.)

You only need to run `make setup-hooks` once per clone. Re-run it if you delete `.git/hooks/`.

---

## 6. Run the baseline check

```bash
{{CHECK_COMMAND}}
```

Expected outcome on a fresh clone: all tests pass, types clean, lint clean. If anything fails on a clean clone, fix `docs/dev-setup.md` first — the install instructions above are wrong.

---

## 7. Editor / IDE setup

The repo carries workspace settings for the IDEs the team uses. Open the repo in your editor of choice and accept the recommended extensions when prompted.

- **VS Code**: `.vscode/extensions.json` lists recommended extensions; settings in `.vscode/settings.json`.
- **Cursor**: `.cursor/rules/{{PROJECT_SLUG}}.mdc` configures the project rules. Cursor reads it automatically.
- **JetBrains / Zed / other**: see project-specific notes if present.

*Remove entries for IDEs the project doesn't ship configs for. Add entries if you add IDE configs later.*

---

## 8. Environment variables / secrets

If the project needs secrets:

1. Copy `.env.example` to `.env`.
2. Fill in the required values (ask the project owner for any internal ones).
3. **Never commit `.env`.** It's in `.gitignore`.

*Remove this section if the project has no secrets.*

---

## 9. Verify the agent workflow

To prove your environment can drive the agent-SDLC contract end-to-end:

1. Read `CLAUDE.md` (or `AGENTS.md` for non-Claude agents) and `docs/agents/CONVENTIONS.md`.
2. Make a trivial change (e.g. add a comment).
3. Try to commit via `scripts/agent-commit.sh "test: verify hook installation"`.
4. Verify `docs/commit-log.md` now has a row tagged `agent`.
5. Revert the commit (`git reset --hard HEAD~1` and remove the log row).

If any of those steps fails, the local hooks are not installed correctly — re-run `make setup-hooks`.

---

## 10. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `make check` fails on a fresh clone | This file is stale | Update the install steps above and re-run |
| `docs/commit-log.md` not getting new rows | Post-commit hook not installed | `make setup-hooks` |
| `git commit` succeeds but isn't tagged as `agent` | You ran `git commit` directly | Use `scripts/agent-commit.sh` instead — see `CONTRIBUTING.md §10` |
| Pre-commit hook blocks a manual commit | `MANUAL_COMMIT_REVIEW = pre-commit-block` is enforced | Add `Manual-Review: <reason>` to the commit message, or set `AGENT_REVIEWED=1` |

*Add new rows as the team discovers recurring setup gotchas.*
