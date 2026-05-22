# Memory & Context Management

The scaffolded SDLC has *two* persistence layers, and they serve different purposes. Agents must understand the split.

## Layer 1: `docs/agents/` (committed, shared, cross-agent)

This is the **canonical, authoritative** rule set. Lives in the repo. Every agent (Claude, Codex, Cursor, Gemini, future tools) reads from here.

| File | Purpose |
|------|---------|
| `docs/agents/OVERVIEW.md` | Project context, architecture, tech stack, build commands. Read first by any agent starting work. |
| `docs/agents/CONVENTIONS.md` | All hard constraints — never-break rules. Non-negotiable. |
| `docs/agents/STATUS.md` | Current phase, what's in progress, what's next, test counts. Updated every session. |

**Properties**:
- ✅ Committed to git
- ✅ Visible to all agents
- ✅ Subject to PR review
- ❌ Per-user preferences belong elsewhere
- ❌ Conversation-scratch belongs elsewhere

## Layer 2: `.claude/memory/` (Claude-specific, optionally committed)

This is Claude Code's persistent memory. Used for **per-user preferences and feedback that should persist across Claude sessions but isn't a project rule**.

```
.claude/
└── memory/
    ├── MEMORY.md                          # Index — one line per memory file
    ├── feedback_<topic>.md                # User feedback (corrections + validations)
    ├── user_role.md                       # Who the user is
    ├── project_context.md                 # Non-obvious project facts not in docs/
    └── reference_<external_system>.md     # Pointers to JIRA, dashboards, etc.
```

**Properties**:
- ✅ Persistent across Claude sessions
- ✅ Claude-specific (other agents ignore it)
- ⚠️ Decide whether to commit it: solo dev → commit; team → typically `.gitignore` and rely on `docs/agents/` for shared rules
- ❌ Other agents (Codex, Cursor, Gemini) won't read it — never put project-wide rules here

## Recommended seed `MEMORY.md`

When scaffolding for Claude Code, write this index file as a starting point:

```markdown
# Memory Index

- [user role](user_role.md) — who the user is and how they work
- [feedback: docs as part of done](feedback_docs_as_part_of_done.md) — docs must update with every feature
- [feedback: linear history](feedback_linear_history.md) — no merge commits, ever
- [feedback: agent never pushes](feedback_no_auto_push.md) — `git push` is always manual
- [feedback: architecture principles](feedback_architecture_principles.md) — project-wide boundary rules
```

The first time Claude is asked to work on the repo, it will write the corresponding files based on what the user tells it.

## Rule of thumb for *where* a piece of knowledge goes

| Type of knowledge | Goes in |
|-------------------|---------|
| "We use Vitest for unit tests" | `docs/agents/OVERVIEW.md` (committed, shared) |
| "Never break the network/compute boundary" | `docs/agents/CONVENTIONS.md` (committed, shared, enforced) |
| "The user prefers terse responses with no trailing summaries" | `.claude/memory/feedback_response_style.md` (Claude-only, personal) |
| "Phase 3 is in progress, PROJ-042 is next" | `docs/agents/STATUS.md` (committed, shared) |
| "The user is a solo dev with 10y Go experience" | `.claude/memory/user_role.md` (Claude-only, personal) |
| "Bug tracker is in Linear project INGEST" | `.claude/memory/reference_linear.md` OR `docs/agents/OVERVIEW.md` (shared if all agents need it) |

## When the agent should refuse to write to memory

If a user says *"save that we use snake_case for Python files"* — that's a **project convention**, not a Claude memory. Push back: *"That belongs in `docs/agents/CONVENTIONS.md` so Codex and Cursor see it too. Want me to add it there instead?"*

Memory is for **per-user preferences and validated working style**, not project rules.

## Cross-session continuity contract

After every scaffolded project, the first thing Claude (or any agent) does on a fresh session is:

1. Read `docs/agents/STATUS.md` — what was in progress?
2. Read `docs/agents/CONVENTIONS.md` — what are the hard rules?
3. Read `docs/issues.md` — what are the next priorities?
4. (Claude only) Read `.claude/memory/MEMORY.md` index — any relevant preferences?
5. **Then** ask the user what to work on, with context.

This is the contract the SDLC sells. Scaffold it well.
