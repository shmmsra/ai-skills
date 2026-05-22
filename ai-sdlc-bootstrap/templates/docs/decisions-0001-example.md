# ADR-001: Adopt the ai-sdlc-bootstrap workflow

**Date**: {{TODAY}}
**Status**: Accepted
**Decider**: {{PROJECT_OWNER}} + AI agent (session {{TODAY}})

---

## Context

{{PROJECT_NAME}} will be developed by humans collaborating with multiple AI coding agents (Claude, Codex, Cursor, Gemini, future tools) across many sessions over an extended timeline. Without a structured workflow:

- Each new agent session starts from zero context — no shared rules, no shared status, no shared history.
- Agents propose plausible-looking changes that violate unstated constraints (security, architecture, naming).
- "Done" is ambiguous — features ship without tests, docs, or recorded reasoning.
- The next agent has no way to know what was tried, what was rejected, or what's in progress.

The fix is to encode the contract in the repository itself, so it travels with the code and is readable by every agent on first sight.

## Decision

Adopt the **ai-sdlc-bootstrap** workflow:

1. **Agent-config layer**: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/{{PROJECT_SLUG}}.mdc` — all thin adapters pointing to one canonical `docs/agents/` triad. No rule duplication.
2. **Canonical rules in `docs/agents/`**: `OVERVIEW.md` (context), `CONVENTIONS.md` (hard constraints), `STATUS.md` (current state).
3. **Plan-first workflow**: every non-trivial change requires a written plan + explicit human `lgtm` before code is written.
4. **TDD with pre-commit gate**: `{{CHECK_COMMAND}}` runs typecheck + tests; pre-commit hook installed via `make setup-hooks` enforces locally; CI mirrors it.
5. **Documentation as part of done**: STATUS, CHANGELOG, requirements, issues, manual-testing, ADRs all update in the same commit as the feature.
6. **In-repo ticket tracking** ({{TICKET_SOURCE_DESCRIPTION}}) — agents read tickets without external API access.
7. **Linear git history**: rebase or fast-forward only; agents never `git push`.
8. **ADRs**: any architectural decision lands in `docs/decisions/` with Context / Decision / Rationale / Alternatives rejected / Consequences.

## Rationale

- **Cross-agent compatibility**: One canonical rules source means a new agent tool can be added by writing a 30-line adapter, not by reauthoring rules.
- **Plan-first prevents 80% of "agent went off the rails" failures**: the human catches misunderstandings before code is written, when the cost of correction is near zero.
- **TDD gate makes regressions visible immediately**: a broken commit can't land; CI mirrors local, so green local = green CI.
- **Docs-as-done is the only way to keep state legible across sessions**: agents read `STATUS.md` first on every session and pick up exactly where the last agent left off.
- **In-repo tickets** mean no external API access needed for agents — they can read priority order, acceptance criteria, and recent closures from a single markdown file.

## Alternatives rejected

- **No structured workflow, rely on prompt engineering**: each session re-litigates the same rules. Drift is guaranteed.
- **GitHub Copilot / Cursor / Claude rules files only, no canonical source**: every agent has slightly different rules; cross-agent reviews diverge.
- **External wiki for project rules**: requires API access for agents, breaks on outages, drifts from code.
- **Pre-commit hook only, no plan-gate**: catches regressions but not misunderstandings. Plan-gate is upstream of the regression gate and prevents the work from starting wrong.

## Consequences

**Easier**:
- New agents onboard in one read of `docs/agents/OVERVIEW.md` + `CONVENTIONS.md` + `STATUS.md`.
- The next session knows exactly what's in progress and what's next.
- Every architectural choice has a documented rationale that future agents can challenge or extend with new ADRs.
- CI failures become rare because the local gate runs the same checks.

**Harder**:
- Every non-trivial change has a plan-step latency before code starts. Acceptable for the bug-prevention payoff.
- Documentation updates are mandatory at commit time. A feature without a `CHANGELOG` entry isn't done.
- Pushing is always manual — agents stop after local commit. This is by design.

**New commitments**:
- Keep `docs/agents/CONVENTIONS.md` in sync with `CLAUDE.md §1`, `AGENTS.md`, and `.cursor/rules/*.mdc` summaries. (Each has a sync-note pointing this out.)
- Every architectural decision gets an ADR. *"We don't write that much"* — that's the point. ADRs are written when the alternative would be a code comment that nobody finds two years later.
