# ai-skills — Changelog

> Chronological log of what changed in this repo and *why*. The "why" matters more than the "what" — the diff already shows the what.
>
> Update at the end of every session. Newest entries at the top.

---

## 2026-05-26 — ai-sdlc-bootstrap scaffold

**What changed**: Bootstrapped the AI-driven SDLC workflow on this repo via the `ai-sdlc-bootstrap` skill. Added agent-config layer (CLAUDE.md, AGENTS.md, GEMINI.md), `docs/agents/` triad, `CONTRIBUTING.md`, `docs/issues.md`, ADR template, and pre-commit gate (`make check`).

**Why**: This project will be developed by humans + multiple AI agents across many sessions. Without the agent-config layer and a strict plan/test/commit workflow, every session starts from zero. The scaffold installs the contract.

**What was rejected**: *(none — first scaffold)*

**What's next**: Begin Phase 1 work as tracked in `docs/issues.md`.

---

*Add new entries above this line. Format: `## YYYY-MM-DD — Short title`, followed by `What / Why / Rejected / Next` sub-headings.*
