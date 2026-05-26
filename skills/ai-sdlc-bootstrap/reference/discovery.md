# Phase 1.5 — Discover external context

The scaffold writes `docs/agents/OVERVIEW.md`, which becomes the canonical entry point for every future agent session. If that file lies (or omits the real "why"), every subsequent session starts from a misunderstanding. Discovery is the cheapest way to prevent that.

**Goal**: before the interview, ask the user for anything they've already written down about this project. Read it. Use it to inform interview defaults, the architecture summary in `OVERVIEW.md`, the seeded ADRs, and the domain rules in `CONVENTIONS.md`.

---

## When to run

Right after **Phase 1 (ASSESS)** and right before **Phase 2 (INTERVIEW)**. Run it once per scaffold. Don't repeat it later — if new docs surface during the interview, the user will mention them.

For **new** projects with no real prior art, this phase may be a no-op — the user just says "nothing yet". That's fine — record `{{EXTERNAL_DOCS_LIST}}` as `*(none — green-field project)*` and move on.

For **mature** projects, this phase is load-bearing. The project almost certainly has a wiki page, design doc, README section, ADR archive, or onboarding doc you can read.

---

## Ask the user

Use a single open-ended prompt — this is not a multi-choice question. Default ask:

> *"Before I write the interview questions, is there any existing documentation I should read to understand this project better? Examples:*
> - *Existing README or `ARCHITECTURE.md` in this repo*
> - *Confluence / Notion / internal wiki pages*
> - *Design docs (Google Doc, Figma, etc.)*
> - *Onboarding guides for new engineers*
> - *Existing ADRs or RFCs (in this repo or elsewhere)*
> - *A separate runbook, dashboard, or playbook the team relies on*
>
> *Paste links or file paths. If there's nothing — just say 'nothing' and we'll move on."*

Don't list every category every time — pick 3–4 most likely for the project's stage.

---

## What to do with the answers

For each link/path the user provides:

1. **If it's a file path inside the repo**: read it with `Read`.
2. **If it's a URL**: use `WebFetch` (if available) to ingest it. If it's behind auth (Confluence, internal wiki, JIRA), tell the user *"I can't access this — could you paste the key sections?"* and wait.
3. **If it's a file path outside the repo**: ask the user whether they're okay with you reading it.

For each successfully read doc:

- Record one line in `{{EXTERNAL_DOCS_LIST}}` for the final `OVERVIEW.md` "Further reading" section:
  ```
  - [<title or short label>](<url or path>) — <one-line purpose>
  ```
- Extract: tech stack hints, architecture diagrams, domain constraints, team conventions, external systems referenced.
- Note any domain rules that should be proposed in interview Q16 (so you can pre-fill instead of asking blind).
- Note any external systems worth seeding as `.claude/memory/reference_*.md` entries (see `reference/memory-and-context.md`).

---

## Update the assessment summary

After Discover finishes, refresh the one-paragraph summary you produced at the end of `assessment.md` with what you learned:

> *"Read your `docs/architecture.md` and the Confluence page on the payment-flow rewrite. Key things I noted: (1) the project uses an event-bus boundary that's already documented as a hard constraint — I'll seed that as a domain rule, (2) you have an ADR archive in `docs/decisions/` — I'll preserve it and number the new ADR-001 as ADR-005 to slot in, (3) Confluence has a runbook for prod incidents — I'll add a `reference_*.md` memory pointer for Claude. Ready to start the interview?"*

Wait for confirmation, then move to Phase 2.

---

## Safe defaults

- **Never read a doc the user didn't share.** If you see a `docs/ARCHITECTURE.md` in the repo and the user didn't list it, ask: *"I noticed `docs/ARCHITECTURE.md` — should I read that too?"*
- **Never overwrite anything in this phase.** Discovery is read-only.
- **Cap reading at ~10 docs.** If the user pastes a wiki dump, ask which 3–5 are most important. Don't drown.
- **Quote, don't paraphrase**, when something will end up in `OVERVIEW.md` or `CONVENTIONS.md`. Misquoted architecture rules are worse than no rules.
