# Related projects (multi-repo / monorepo support)

Fully optional. Most repos should never see `project.deps.yaml` — only write it when the
interview (Round 6, see `questionnaire.md`) confirms the repo actually has related projects
an agent should be aware of.

## Why this exists

The point of this feature is **agent awareness**, not build orchestration. If repo A depends
on (or contains) repo/project B, an agent working in A should know that a task touching B's
domain requires reading B's own agent docs first — because B may define constraints A's docs
don't know about. Everything below exists to make that pointer reliable and low-maintenance.

## Prior art (read before assuming this is novel)

- **AGENTS.md nested-file convention** — the closest real standard for the in-repo case.
  Nearest `AGENTS.md` to the file being touched wins; root sets defaults, subdirectories
  override. Several tools (Claude Code's `CLAUDE.md`, Codex, Copilot CLI, OpenCode) implement
  or are actively building support for this. We align with it: for in-repo entries, the skill
  offers to scaffold a nested `AGENTS.md` / `docs/agents/` triad at the declared path — that's
  the actual discovery mechanism. `project.deps.yaml` is just the index, not a replacement.
- **Claude Code's own nested `CLAUDE.md` discovery** is narrower than full recursion — it loads
  root + the directory a session started from, not automatically every nested file as the
  agent touches other subtrees. Don't rely on implicit discovery alone; the explicit "Related
  projects" table in `OVERVIEW.md` is there because agent behavior here is inconsistent across
  tools.
- **Cross-repo dependency resolution** has no single broadly-adopted standard across languages
  (closest analogs: Google's `repo` tool, Zephyr's `west`, ROS's `vcstool` — all
  ecosystem-specific). `project.deps.yaml` doesn't try to be one; it's deliberately minimal.

## Schema

One file, `project.deps.yaml`, committed at repo root. One list, `projects:`. The presence of
`repo:` on an entry is the only discriminator between the two kinds:

```yaml
name: my-repo

projects:
  # In-repo project — no `repo:`. `path` is relative to THIS repo's root.
  # No lock entry, no resolution — the path is always valid in the checked-out tree.
  - name: pricing-engine
    path: packages/pricing-engine
    notes: "Owns checkout pricing (aka 'PE'). Has its own AGENTS.md."

  # External project — `repo:` present. `path` is relative to THAT repo's root
  # (addresses a specific package inside a monorepo dependency; omit if the
  # whole repo is the target). Resolved to a local machine path in
  # .project.lock.yaml, which is never committed.
  - name: widgets-core
    repo: git@github.com:acme/widgets-core.git
    path: packages/core
    notes: "Upstream rules feed for the pricing engine."
    required: true
```

Fields: `name` (required, unique), `path` (required), `repo` (optional — presence = external),
`notes` (free text — what it holds, acronyms, when to reference it), `required` (optional,
default `true` — if `false`, resolution failures are warnings, not hard errors).

**Deliberately not supported**: git ref/branch/commit pinning, SHA drift detection. Entries are
purely path-based — whatever is checked out locally is trusted as-is.

### Restricted YAML — why, and what "restricted" means

The manifest and lock file are YAML-*compatible* syntax, but the shape is deliberately narrow
so a hand-rolled parser (no third-party dependency, works identically in POSIX shell and
PowerShell) can read it reliably:

- Exactly one list (`projects:`) with entries at 2-space indent (`  - key: value`).
- Continuation fields at 4-space indent (`    key: value`).
- Flat scalars only — no nested lists, no multi-line strings, no anchors/aliases.
- A line with no leading whitespace ends the list.

Don't hand-author anything outside this shape — a real YAML parser would accept it, our
scripts won't.

## Lock file

`.project.lock.yaml`, gitignored, entirely script-generated (never hand-edit; never let an
agent hand-write it — always go through the script, even for the initial write, so the file's
shape has exactly one source of truth). Only external (`repo:`-bearing) entries appear in it —
in-repo entries have nothing to resolve.

```yaml
resolved_at: 2026-08-26T10:00:00Z
root: my-repo
projects:
  - name: widgets-core
    repo: git@github.com:acme/widgets-core.git
    path: packages/core
    local_path: /Users/jane/dev/widgets-core
    parent: root
    depth: 1
```

`parent` and `depth` describe the resolved dependency tree (root repo → widgets-core → its own
further dependencies, if it declares any).

## Resolution algorithm

Depth-first traversal starting from the root repo's `projects:` list, restricted to
`repo:`-bearing entries (in-repo entries are validated for path existence and otherwise
skipped — they never enter the graph).

**Node identity**: `(normalized_repo, path)` — never the local filesystem path, since two
different local checkouts of the same remote must collapse to one node. Normalization is
best-effort string surgery (strip `.git` suffix, strip `git@`/`ssh://`/`https://`/`http://`/
`git://` prefixes, turn `host:path` scp-syntax into `host/path`). This will not dedupe an
`ssh://` and `https://` URL for the same repo if they don't happen to normalize to the same
string — a known, accepted limitation given there's no ref-pinning or registry to lean on.

**Traversal**:
1. For each entry in the current manifest, resolve its local path (see below).
2. If resolved and the node is not already visited: mark it "on stack," recurse into its own
   `project.deps.yaml` if one exists at the resolved path (only its `repo:`-bearing entries),
   then mark it "done" and pop it off the stack.
3. **Cycle**: revisiting a node already "on stack" → abort immediately, print the full chain
   (`A -> B -> C -> A`), non-zero exit. No escape hatch — a cycle here is a modeling bug, not a
   legitimate use case.
4. **Diamond dependency**: revisiting a node already "done" (not on the current stack) → reuse
   the cached resolution, don't recurse into it again. This is fine and expected.

**Local-path resolution priority** for each entry (first match wins):
1. `--set NAME=PATH` passed to the script (always wins — explicit override).
2. An existing `.project.lock.yaml` entry for that name whose `local_path` still has a `.git`
   directory.
3. The conventional sibling path `../<name>` next to the repo root, if it exists and has a
   `.git` directory (a lightweight convention-over-configuration fallback, not a formal rule).
4. If `--check` was passed: stop here — no prompting, no mutation, just report.
5. If stdin/stdout are a real TTY: prompt for a path interactively.
6. If still unresolved and `--no-clone` was not passed: offer to clone (or auto-accept under
   `--yes`) into the conventional sibling path.
7. Otherwise: unresolved. Hard error if `required: true`, warning if `false`.

## Script invocation modes — this matters for agents specifically

The script must never block on stdin when an agent invokes it through a non-interactive shell
tool call — there is no TTY to prompt against, so it would hang.

- **A human running it directly** in a real terminal: no flags needed, it prompts.
- **An agent running it on the human's behalf**: never invoke it bare and hope. First ask the
  human (a direct question) for the local path of any dependency the script will report as
  missing, then re-invoke with `--set name=path` for each. Use `--yes` to accept clone
  defaults non-interactively, `--no-clone` to get a fail-list instead of a clone offer, and
  `--check` for a side-effect-free verification pass (e.g. before touching a related project's
  code, confirm it's actually resolved).

## Agent-doc fallback chain

When an agent determines a task touches a related project's domain (per that entry's `notes`),
read, in order, the first that exists at the resolved path:

1. `<path>/docs/agents/OVERVIEW.md` (plus `CONVENTIONS.md`, `STATUS.md`) — if that project was
   itself bootstrapped with ai-sdlc-bootstrap.
2. `<path>/AGENTS.md` or `<path>/CLAUDE.md`.
3. `<path>/README.md`.
4. None found — proceed on judgment, and say so explicitly rather than silently guessing.

For external entries, `<path>` is the `local_path` from `.project.lock.yaml`. For in-repo
entries, `<path>` is simply `path` relative to this repo's root.

## Platform notes

Two engines, not three — POSIX shell (`scripts/update-project-lock.sh`) covers **macOS and
Linux**; PowerShell (`scripts/update-project-lock.ps1`) covers **Windows**. They implement the
same logic independently (no shared engine file, no interpreter dependency imposed on the
target repo) — that's a deliberate simplicity/portability tradeoff over a single Python/Node
engine, accepted at the cost of having to keep both scripts in lockstep on any future fix.

Watch for BSD-vs-GNU differences between macOS and Linux shells specifically:
- No `readlink -f` (BSD `readlink` doesn't support it) — use `(cd "$dir" && pwd -P)` instead.
- `sed -E` (not `-r`) works on both BSD and GNU sed — stick to `-E`.
- `date -u +%FORMAT` works on both; don't reach for GNU-only `date -d`.

## Rerunning the bootstrap skill

A rerun of `ai-sdlc-bootstrap` on a repo that already has `project.deps.yaml`:
1. Detects it in Phase 1 (ASSESS) — treat presence as the signal that this repo is already
   multi-repo/monorepo-aware, skip the initial yes/no, go straight to "add/remove/edit?".
2. Rewrites `project.deps.yaml` per the (possibly edited) answers — show the diff, standard
   existing-file rules apply.
3. **Always rewrites both script files from the current template**, regardless of whether the
   manifest changed, so engine bugfixes/features propagate. Both scripts carry a version
   comment header (`# ai-sdlc-bootstrap multi-repo engine vX.Y`) so staleness is visible even
   without a full rerun.
