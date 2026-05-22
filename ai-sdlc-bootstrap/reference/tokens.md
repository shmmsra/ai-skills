# Template Token Reference

Exhaustive list of every `{{TOKEN}}` used across the templates. When scaffolding, every token in a written file must be substituted — search the written output for `{{` after each write; if any remain, you missed one.

## Identity tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{PROJECT_NAME}}` | Interview Q1 | `Acme` |
| `{{PROJECT_SLUG}}` | Derived from name (kebab-case lower) | `acme` |
| `{{PROJECT_DESCRIPTION}}` | Interview Q1 | `Order management service for the widget catalog` |
| `{{PROJECT_OWNER}}` | Interview Q1 (or `git config user.name`) | `Jane Doe` |
| `{{TODAY}}` | `date +%Y-%m-%d` at scaffold time | `2026-05-21` |

## Ticket tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{TICKET_PREFIX}}` | Interview Q1 (uppercase) | `ACME` |
| `{{TICKET_PREFIX_LOWER}}` | Derived (lowercase) | `acme` |
| `{{TICKET_SOURCE}}` | Interview Q3 | `inrepo` / `github` / `jira` |
| `{{TICKET_SOURCE_DESCRIPTION}}` | Derived from Q3 | `in-repo docs/issues.md` / `GitHub Issues at owner/repo` / `JIRA project KEY` |
| `{{GITHUB_OWNER_REPO}}` | Interview Q3 (GitHub branch only) | `acme/widgets` |
| `{{JIRA_PROJECT_KEY}}` | Interview Q3 (JIRA branch only) | `ACME` |
| `{{JIRA_BASE_URL}}` | Interview Q3 (JIRA branch only) | `https://example.atlassian.net` |

## Agent-target tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{AGENT_TARGETS}}` | Interview Q2 (comma list) | `claude,codex,cursor,gemini` |
| `{{AGENT_CONFIG_FILES_LIST}}` | Derived from Q2 | `CLAUDE.md, AGENTS.md, GEMINI.md, .cursor/rules/acme.mdc` |

## Language / build tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{LANGUAGE}}` | Assessment (primary) | `typescript` |
| `{{LANGUAGES_LIST}}` | Assessment (all detected) | `TypeScript, C++` |
| `{{TEST_FRAMEWORK}}` | Interview Q5 (autodetect + confirm) | `Vitest + Catch2` |
| `{{TEST_COMMAND}}` | Derived from Q5 | `npm test` |
| `{{TEST_DIRECTORY}}` | Assessment | `src/__tests__/` |
| `{{TYPECHECK_COMMAND}}` | Derived from Q5 | `npm run typecheck` (or empty) |
| `{{CHECK_COMMAND}}` | Derived from build choice | `make check` (default) / `npm run check` / `just check` |
| `{{BUILD_ENTRY_POINT}}` | Interview Q4 | `make` / `npm` / `just` |
| `{{CI_HOST}}` | Interview | `GitHub Actions` |

## Makefile / CI block tokens

Used only inside `templates/Makefile` and `templates/ci-github-actions.yml`. Fill in language-specific commands from `reference/language-presets.md`:

| Token | Example |
|-------|---------|
| `{{CHECK_TARGETS}}` | `typecheck lint test` (TS) / `vet test` (Go) |
| `{{LANGUAGE_TARGETS_BLOCK}}` | Full block of `typecheck:`, `test:`, `lint:` rules with their commands |
| `{{CLEAN_COMMANDS}}` | `\trm -rf dist/ node_modules/.cache/` |
| `{{CI_SETUP_BLOCK}}` | YAML setup actions block (setup-node, setup-python, etc.) |

## Workflow tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{NONTRIVIAL_DEFINITION}}` | Interview Q7 (one of 3 presets) | `new file, OR > 1 file modified, OR touches architecture/API/IPC boundaries` |
| `{{NONTRIVIAL_DEFINITION_BLOCK}}` | Derived from Q7 (full bulleted block for CONVENTIONS.md) | (multi-line) |
| `{{MANUAL_TEST_REQUIRED_TEXT}}` | Interview Q10 | `required for runtime-affecting changes` / `recommended` |
| `{{MANUAL_TEST_REQUIRED_TEXT_LONG}}` | Derived from Q10 | (long-form sentence stating gate vs recommendation) |

## Rules tokens

| Token | Source | Example |
|-------|--------|---------|
| `{{DOMAIN_RULES_BLOCK}}` | Interview Q9 (free-text list) | Bulleted list of project-specific hard constraints |
| `{{APPROVAL_GATES_LIST}}` | Interview Q8 (comma-joined short form) | `production deploys, database migrations, payment code` |
| `{{APPROVAL_GATES_BLOCK}}` | Derived from Q8 (bulleted with explanations) | Multi-line block with each gate + why |

## Substitution algorithm

```
for each template file to write:
  content = read(template)
  for each token in known_token_list:
    content = content.replace(token, resolved_value[token])
  write(target_path, content)
  if '{{' in content:
    raise "unsubstituted token in {target_path}"
```

If a template uses a token you don't have a value for, **stop and ask** rather than writing the file with the token still present. Better to ask one more question than to ship `{{DOMAIN_RULES_BLOCK}}` literally into the user's repo.

## What if a token doesn't apply?

For optional tokens (e.g. `{{TYPECHECK_COMMAND}}` for a dynamically-typed language), resolve to one of:
- An empty string → if the surrounding text reads naturally without it
- A literal `n/a` → if the empty version reads awkwardly
- Remove the surrounding sentence entirely → if it only made sense with a value

Never leave the bare token in output.
