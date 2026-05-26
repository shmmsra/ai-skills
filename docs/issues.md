# ai-skills — Feature & Issue Tracker

> **Single source of truth for all planned, in-progress, and recently completed work.**
>
> This file lives in the repo so AI agents can read it without any external system access,
> and every status change is committed alongside the code that caused it.

---

## How to use this file

**Human**: Add new issues at the bottom of the Open section. Set priority, write acceptance criteria. No need to assign — just set status to `IN PROGRESS` when a session starts on it.

**AI Agent**: Before starting a session, scan this file for the highest-priority `OPEN` issue that matches the session goal. Update the status to `IN PROGRESS` (with the session date) when you begin. Mark `DONE` and move to "Recently closed" when complete. Add any new issues you discover (bugs, missing tests, follow-up work) during the session.

---

## Status legend

| Status | Meaning |
|--------|---------|
| `OPEN` | Ready to work on, not yet started |
| `IN PROGRESS` | Actively being worked on — note session date |
| `BLOCKED` | Cannot proceed — reason and blocker recorded |
| `DONE` | Complete and committed — note commit hash |
| `REJECTED` | Will not implement — reason recorded |

## Priority legend

| Priority | Meaning |
|----------|---------|
| **P0** | Blocking — nothing else should be worked on until resolved |
| **P1** | High — next logical thing to do in the current phase |
| **P2** | Medium — important but not urgent; can wait one session |
| **P3** | Low — nice to have; do it when there's slack |

---

## Ticket ID convention

Tickets use the prefix `AISKL-NNN`, numbered sequentially (e.g. `AISKL-001`, `AISKL-002`). When closing, reference the ticket ID in the commit message: `feat(scope): aiskl-042 add retry logic`.

---

## Open Issues

### AISKL-004 · P2 · OPEN · Enhancement
**Scope `linguist-vendored` per-skill instead of broad globs (Claude + Cursor)**

`scripts/install.sh` and `scripts/install.ps1` write two broad patterns to `.gitattributes`:

- `.claude/skills/** linguist-vendored`
- `.cursor/rules/*.mdc linguist-vendored`

These over-claim: they mark *every* file in those folders as vendored, including skills the consumer authored themselves. "Vendored" should mean "third-party files we installed, not yours."

**Approach** (non-destructive): emit one entry per installed skill, scoped to the exact path. Do **not** rewrite existing `.gitattributes` to remove old broad patterns — risky, could clobber unrelated edits. Document the manual cleanup instead.

- Claude: `.claude/skills/<skill>/** linguist-vendored`
- Cursor: `.cursor/rules/<skill>.mdc linguist-vendored`

**Acceptance criteria**:
- [ ] `install.sh` writes `.claude/skills/<skill>/** linguist-vendored` per skill (project scope only)
- [ ] `install.sh` writes `.cursor/rules/<skill>.mdc linguist-vendored` per skill
- [ ] `install.ps1` mirrors both behaviours
- [ ] Existing `add_gitattribute` dedup logic prevents duplicates on re-install
- [ ] README adds a short note about manual cleanup of old broad patterns
- [ ] `docs/manual-testing.md`: add scenarios for per-skill entries, user-authored skill untouched, and no-duplicate re-install
- [ ] `make check` passes

**Notes**: Linguist handles overlapping `linguist-vendored` patterns without issue — more-specific patterns coexist fine with broader ones. Slightly noisier `.gitattributes` (N lines vs 1) but with ~2 skills today and a ceiling of ~10, this is acceptable.

---

*Add new tickets below this line. Use the same format: heading with ID · priority · status · brief category; then bold one-line title; then acceptance criteria as checkboxes; then notes.*

---

## Recently closed

| Date | Ticket | Title | Commit |
|------|--------|-------|--------|
| 2026-05-26 | AISKL-003 | Add per-skill VERSION file + README; install no-op when version matches | 6ad9563 |
| 2026-05-26 | AISKL-002 | Move skills to skills/ + skills-dist CI branch | 24bda6c |
| 2026-05-26 | AISKL-001 | Scaffold placeholder — superseded by AISKL-002 and AISKL-003 | REJECTED |
| 2026-05-26 | — | ai-sdlc-bootstrap scaffold | 8cd82a8 |

*When a ticket is closed: move it to this table, set the commit hash, and remove it from the Open section. Keep the last ~20 closures here; archive older ones to `docs/CHANGELOG.md`.*
