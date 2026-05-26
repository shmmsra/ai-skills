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



### AISKL-003 · P1 · OPEN · Feature
**Add per-skill versioning via a `VERSION` file — install becomes a no-op when version matches**

Each skill should carry its own version number so install scripts can detect whether the consumer's copy is already up-to-date and skip the install silently. If the installed version matches the source, the install is a no-op unless `--update` / `UPDATE_MODE=1` is explicitly requested.

**Recommended approach**: a plain `VERSION` file at the root of each skill directory containing a single semver string (e.g. `1.0.0`). Trivially readable by humans (`cat .claude/skills/ai-sdlc-bootstrap/VERSION`) and by shell scripts without any parser (`jq`, frontmatter parsers, etc.). Bump rules:

- `MAJOR` — breaking change to `SKILL.md` interface or template structure (existing consumers may need to re-read the skill)
- `MINOR` — new templates, references, or capabilities added; backwards compatible
- `PATCH` — bug fixes, typo corrections, no behaviour change

**Acceptance criteria**:
- [ ] `VERSION` file added to every skill directory (start at `1.0.0` for all existing skills)
- [ ] `scripts/install.sh`: on install, read `VERSION` from the source skill; if the destination already has an identical `VERSION` file, print `"<skill> v1.0.0 already installed — skipping (pass --update to force)"` and skip
- [ ] `scripts/install.ps1`: same logic as above
- [ ] `--update` / `UPDATE_MODE=1` flag overrides the version check and always writes the latest files (existing behaviour unchanged)
- [ ] On successful install or update, the `VERSION` file is written to the destination alongside the skill files
- [ ] README updated: mention that re-running the installer is safe and version-gated; update the `--update` / force-update documentation
- [ ] `docs/manual-testing.md`: add a test scenario covering same-version no-op, version-mismatch update prompt, and `--update` force-override
- [ ] `make check` passes

**Notes**: Depends on AISKL-002 (skills move to `skills/` directory) — implement the `VERSION` file at the final path (`skills/<name>/VERSION`) rather than the current root-level path, to avoid a second move. If AISKL-002 is not done yet, add the `VERSION` files at the root and adjust paths when AISKL-002 lands. A `skill.json` metadata file was considered but rejected — JSON parsing in bash requires `jq` (not universally available) and the version is the only field needed right now; a plain file is simpler and more portable. If richer metadata is needed in future, revisit in a new ADR.

---

*Add new tickets below this line. Use the same format: heading with ID · priority · status · brief category; then bold one-line title; then acceptance criteria as checkboxes; then notes.*

---

## Recently closed

| Date | Ticket | Title | Commit |
|------|--------|-------|--------|
| 2026-05-26 | AISKL-002 | Move skills to skills/ + skills-dist CI branch | 24bda6c |
| 2026-05-26 | AISKL-001 | Scaffold placeholder — superseded by AISKL-002 and AISKL-003 | REJECTED |
| 2026-05-26 | — | ai-sdlc-bootstrap scaffold | 8cd82a8 |

*When a ticket is closed: move it to this table, set the commit hash, and remove it from the Open section. Keep the last ~20 closures here; archive older ones to `docs/CHANGELOG.md`.*
