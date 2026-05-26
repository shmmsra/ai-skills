# {{PROJECT_NAME}} — Changelog

> Chronological log of what changed in this repo and *why*. The "why" matters more than the "what" — the diff already shows the what.
>
> Update at the end of every session. Newest entries at the top.

---

## {{TODAY}} — ai-sdlc-bootstrap scaffold

**What changed**: Bootstrapped the AI-driven SDLC workflow on this repo via the `ai-sdlc-bootstrap` skill. Added agent-config layer ({{AGENT_CONFIG_FILES_LIST}}), `docs/agents/` triad, `CONTRIBUTING.md`, `docs/issues.md`, ADR template, pre-commit gate ({{CHECK_COMMAND}}), and CI workflow.

**Why**: This project will be developed by humans + multiple AI agents across many sessions. Without the agent-config layer and a strict plan/test/commit workflow, every session would start from zero. The scaffold installs the contract.

**What was rejected**: *(none — first scaffold)*

**What's next**: Begin Phase 1 work as tracked in `docs/issues.md`.

---

*Add new entries above this line. Format: `## YYYY-MM-DD — Short title`, followed by `What / Why / Rejected / Next` sub-headings.*
