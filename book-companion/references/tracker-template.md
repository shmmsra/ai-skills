# Tracker Template

The tracker is a single markdown file per book. It's the user's source of truth for progress and the first thing read on every resume. Read this file the first time you create a tracker in a session.

## Why markdown

- Human-editable in any text editor.
- Portable across Claude Code, claude.ai, and any other agent / IDE.
- Diffs cleanly in git if the user wants to version their study notes.

## File naming

`<book-slug>-tracker.md` where `<book-slug>` is the book title kebab-cased.

Examples:
- `designing-data-intensive-applications-tracker.md`
- `crafting-interpreters-tracker.md`
- `the-pragmatic-engineer-tracker.md`

## Structure

The file has five sections in this order. Don't reorder them — the "Resume here" pointer needs to be near the top so the next session finds it instantly.

````markdown
# <Book Title> — Study Tracker

**Author**: <author>
**Started**: <YYYY-MM-DD>
**Goal**: <user's stated reason for reading this book>
**Adjacent knowledge**: <topics user already knows well — anchors for analogies>
**Session length**: <typical session, e.g. 30–45 min>

---

## Resume here

**Next**: Chapter <N>, Section <N.M> — "<section title>"

---

## Progress

### Chapter 1 — <Title>

- [x] 1.1 <Section name> — `taught` — closures + lexical scope; solid on application
- [x] 1.2 <Section name> — `skipped-known` — already deep from work
- [ ] 1.3 <Section name> — `unread`

### Chapter 2 — <Title>

- [~] 2.1 <Section name> — `needs-review` — monad bind clicked, but State monad example unclear
- [ ] 2.2 <Section name> — `unread`

(continue per chapter — only fill in chapters as you reach them or skip them)

---

## Open threads

- 2.1: revisit State monad with a concrete example from agent orchestrator context
- 3.4 (preview): book asserts X but sounds counterintuitive — sanity check against another source

---

## Session log

- 2026-05-20: covered 1.1 (taught), 1.2 (skipped-known), started 2.1
- 2026-05-19: calibration; agreed reading order: 1 → 2 → skip 3 → 4
````

## Status codes

| Code | Meaning |
|------|---------|
| `unread` | Haven't reached it yet. Default for everything when the tracker is first created. |
| `skipped-known` | Probe showed mastery; skipped entirely. Optional note on any novel angle the book brings. |
| `recapped` | Light pass; user knew most of it; new angles mentioned in the note. |
| `taught` | Full teach cycle completed; user is at working understanding. |
| `needs-review` | Taught but a specific gap remains. Note must name *what's* unclear, not just "fuzzy". |
| `mastered` | Taught + tested clean on an application question. |

Checkbox state mirrors status roughly: `[ ]` for `unread`, `[~]` for `needs-review`, `[x]` for everything else (taught, skipped, recapped, mastered).

## Update rules

- Update **after every subsection** — never batch. A session can be interrupted at any moment; the tracker must always reflect the truth.
- Update the section's status line first, then update "Resume here" *last*. That way "Resume here" is the single source of truth even if the rest of the file is mid-edit.
- Open threads is for things the user explicitly wanted to revisit OR you flagged as worth revisiting. Don't dump every section note here — that defeats the point.
- Session log is one line per session. What was covered, big calibration decisions, any reordering choices.
- Notes on each section are concise — one phrase, not a paragraph. The section in the book is the long form; the tracker just indexes the user's relationship to it.

## What good notes look like

| Bad note | Better note |
|----------|-------------|
| `taught — went well` | `taught — closures via env-capture analogy; solid` |
| `needs-review — confused` | `needs-review — confused on why bind unwraps but join doesn't` |
| `skipped-known` | `skipped-known — daily-use territory from agent orchestrator work` |

The "better" notes are useful months later when the user comes back. The "bad" notes aren't.

## When to also save derived artifacts

Sometimes a section produces something worth keeping separately — a diagram, a cheatsheet, a worked example. Don't bury these in the tracker. Save as sibling files (`<book-slug>-ch2-monads-diagram.svg`, `<book-slug>-cheatsheet.md`) and link to them from the relevant section note:

```
- [x] 2.3 Monads — `taught` — see ./crafting-interpreters-ch2-monads-diagram.svg
```
