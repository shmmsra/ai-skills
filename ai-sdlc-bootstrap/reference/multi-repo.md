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
  projects" section in `OVERVIEW.md` is there because agent behavior here is inconsistent across
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
- Flat scalars, or literal block scalars (`key: |` — see below) for multi-line values. No
  nested lists, no folded scalars (`>`), no anchors/aliases.
- A line with no leading whitespace ends the list.

Don't hand-author anything outside this shape — a real YAML parser would accept it, our
scripts won't.

#### Multi-line values (`key: |`)

Any field — most usefully `notes` — can span multiple lines using YAML's literal block scalar:

```yaml
  - name: pricing-engine
    path: packages/pricing-engine
    notes: |
      Owns checkout pricing (aka 'PE'). Has its own AGENTS.md.

      Second paragraph after a blank line — blank lines are part of the block.
        This line is indented one level further and keeps that extra indent.
    required: true
```

Rules: content lines must be indented **at least 6 spaces** — more than the normal 4-space
continuation-field indent — regardless of whether `key: |` appeared on the list-item's own line
(2-space indent) or a continuation line (4-space indent); this is a fixed convention, not
YAML's usual auto-detect-from-first-line indentation rule, kept simple on purpose. Blank lines
are part of the block. The block ends at the first non-blank line indented less than that (a
new field, a new list item, or a dedent out of the list). Trailing blank lines are dropped
(YAML's default "clip" chomping). Any indentation beyond the 6-space minimum is preserved
literally in the value. **Folded scalars (`>`) are not supported** — only literal (`|`).

This round-trips through `.project.lock.yaml`: the writer detects a value containing an
embedded newline and emits it back out as a block scalar, so a multi-line `notes` written in
`project.deps.yaml` survives being carried into the lock and re-read on a later run.

## Lock file

`.project.lock.yaml`, gitignored, entirely script-generated (never hand-edit; never let an
agent hand-write it — always go through the script, even for the initial write, so the file's
shape has exactly one source of truth). **This is the file agents should read** — `project.deps.yaml`
is only the raw input. Both in-repo and external entries appear here, fully resolved and
flattened, including transitive ones — a related project's own further dependencies (in-repo or
external) are walked too, at any depth, in any mix:

```yaml
resolved_at: 2026-08-26T10:00:00Z
root: my-repo
projects:
  - name: pricing-engine
    kind: in-repo
    repo:
    path: packages/pricing-engine
    local_path: /Users/jane/dev/my-repo/packages/pricing-engine
    notes: "Owns checkout pricing (aka 'PE'). Has its own AGENTS.md."
    parent: root
    depth: 1
  - name: widgets-core
    kind: external
    repo: git@github.com:acme/widgets-core.git
    path: packages/core
    local_path: /Users/jane/dev/widgets-core
    notes: "Upstream rules feed for the pricing engine."
    parent: root
    depth: 1
```

**`local_path` for an external entry is always the git checkout root**, never joined with `path` —
that's deliberate: it's what the reuse-on-rerun check validates (`local_path/.git` must exist),
and joining would silently break that check on every subsequent run for any entry addressing a
subpath of a monorepo dependency. When `path` is non-empty (addressing a specific package inside
a monorepo dependency), **the actual project directory is `local_path` joined with `path`** —
that's what recursion into the addressed package's own `project.deps.yaml` uses, and what an
agent should treat as "where this project's code and docs actually live," not the bare
`local_path`. For in-repo entries there's no such split: `local_path` is already the fully
joined, ready-to-use directory.

`kind` (`in-repo` / `external`) and `notes` are carried straight through from the manifest —
`notes` is why the lock is agent-sufficient on its own, without needing to also open
`project.deps.yaml`. `parent` and `depth` describe the resolved dependency tree (root repo →
widgets-core → its own further dependencies, if it declares any, in-repo or external).

For in-repo entries, `local_path` is always the absolute path (repo-root-relative `path` joined
against whichever checkout declared it) — it isn't "resolved" the way an external entry is, but
it's still machine-specific in absolute form, which is exactly why it belongs in the gitignored
lock rather than the committed manifest.

## Resolution algorithm

Depth-first traversal starting from the root repo's `projects:` list. **Both entry kinds are
graph nodes in the same walk** — an in-repo sub-project's own `project.deps.yaml` (if it has
one) is walked exactly like an external dependency's, recursively, regardless of how many hops
of either kind are mixed together.

**Node identity**:
- External: `(normalized_repo, path)` — never the local filesystem path, since two different
  local checkouts of the same remote must collapse to one node. Normalization is best-effort
  string surgery (strip `.git` suffix, strip `git@`/`ssh://`/`https://`/`http://`/`git://`
  prefixes, turn `host:path` scp-syntax into `host/path`). This will not dedupe an `ssh://` and
  `https://` URL for the same repo if they don't happen to normalize to the same string — a
  known, accepted limitation given there's no ref-pinning or registry to lean on.
- In-repo: the resolved absolute `local_path` — computed by joining the declared `path` against
  the *base directory of whichever manifest declared it* (the repo root at depth 1, or a
  previously-resolved node's own checkout at deeper levels), not always the original repo root.

**Traversal**:
1. For each entry, compute its identity key and resolve its local path (external: see priority
   list below; in-repo: join `path` onto the current base directory — nothing can fail here,
   the path is either there or it isn't).
2. If not already visited: mark it "on stack," record it in the lock, recurse into its own
   `project.deps.yaml` if one exists at the resolved path (passing that path down as the base
   directory for any in-repo children it declares), then mark it "done" and pop it off the stack.
   An in-repo entry whose declared path doesn't exist still gets recorded (with a warning) rather
   than dropped — there's no "unresolved" state to represent for something the wrong side of a
   typo, not a missing local checkout.
3. **Cycle**: revisiting a node already "on stack" → abort immediately, print the full chain
   (`A -> B -> C -> A`), non-zero exit. No escape hatch — a cycle here is a modeling bug, not a
   legitimate use case. This applies across kinds too (an in-repo entry pointing, transitively,
   back to something already on the stack is still a cycle).
4. **Diamond dependency**: revisiting a node already "done" (not on the current stack) → reuse
   the cached resolution, don't recurse into it again. This is fine and expected.

**Local-path resolution priority for external entries** (first match wins):
1. `--set NAME=PATH` passed to the script (always wins — explicit override).
2. An existing `.project.lock.yaml` entry for that name whose `local_path` still has a `.git`
   directory (this repo's own previous resolution).
3. A **transitive lock preset** (see below) — a matching entry found in a related project's own
   `.project.lock.yaml`, whose `local_path` still has a `.git` directory.
4. The conventional sibling path `../<name>` next to the repo root, if it exists and has a
   `.git` directory (a lightweight convention-over-configuration fallback, not a formal rule).
5. If `--check` was passed: stop here — no prompting, no mutation, just report.
6. If stdin/stdout are a real TTY: prompt for a path interactively.
7. If still unresolved and `--no-clone` was not passed: offer to clone (or auto-accept under
   `--yes`) into the conventional sibling path.
8. Otherwise: unresolved. Hard error if `required: true`, warning if `false`. (`required` has no
   equivalent effect for in-repo entries — a missing in-repo path is always a warning, never a
   hard failure.)

### Transitive lock presets

If a node being recursed into has its *own* `.project.lock.yaml` already sitting there (it was
independently resolved before, on this machine, outside of this run — e.g. the human already had
a standalone checkout of it and had run the script inside it directly), that lock's already-resolved
external entries are offered as presets before falling back to a fresh sibling-path guess or clone.
This is what makes a chain like `root → ccd-assistant → cloud-shared-components` reuse a
`cloud-shared-components` checkout ccd-assistant already knew about, instead of asking the human
to locate (or re-clone) it from scratch.

An explicit `--set` for that name, or an entry already in *this* repo's own top-level lock, always
outranks a transitive preset and is never overwritten by one.

Behavior differs by invocation mode — this is intentional, matching the confirm-vs-auto-accept
split used for clone offers elsewhere in this script:
- **Interactive** (real TTY): prompts per entry — *"Found '\<name>' already resolved by
  '\<parent>'s own lock at '\<path>' — use it? \[Y/n, or type a different path\]"*. Accepting
  (blank/`y`) uses the discovered path; `n` declines and falls through to normal resolution;
  anything else is treated as an override path.
- **`--check`**: auto-accepted (needed to keep walking the graph for reporting purposes) *and*
  printed as an informational `preset: ...` line — this is how an agent discovers presets without
  mutating anything (see below).
- **Non-interactive, not `--check`** (e.g. a real `--yes` run): auto-accepted silently by default,
  logged the same way. This is a script-level baseline for whoever runs it non-interactively
  without an agent in the loop (a human via `--yes`, or CI) — it is **not** how an agent should
  rely on this working; see the next section.

## Script invocation modes — this matters for agents specifically

The script must never block on stdin when an agent invokes it through a non-interactive shell
tool call — there is no TTY to prompt against, so it would hang.

- **A human running it directly** in a real terminal: no flags needed, it prompts (including for
  transitive lock presets, per above).
- **An agent running it on the human's behalf**: never invoke it bare and hope, and never let a
  real (`--yes`) run silently auto-accept a transitive lock preset on the human's behalf — that
  skips the accept/override choice they're entitled to. Instead:
  1. Run `scripts/update-project-lock.sh --check` (or `.ps1`) first. Its output reports, without
     mutating anything, both `error: required project '<name>' ... could not be resolved` lines
     (needs a fresh local path) and `preset: '<name>' already resolved by '<parent>'s own lock at
     <path>` lines (a transitive default is available).
  2. For every `preset:` line, ask the human whether to accept the discovered path or override it
     — present the discovered path as the default, same as the script's own interactive prompt
     would.
  3. For every unresolved-required line, ask the human for a path (or whether to clone it), as
     already established.
  4. Re-invoke the script for real with `--set name=path` for **every** entry from both steps —
     whether the human accepted the default or overrode it — plus `--yes` for any clone offers
     they approved and `--no-clone` otherwise. Everything the human already decided on arrives as
     an explicit `--set`; nothing is left for the script's own non-interactive auto-accept
     fallback to silently decide.

## Agent-doc fallback chain

When an agent determines a task touches a related project's domain (per that entry's `notes`),
read, in order, the first that exists at the resolved path:

1. `<path>/docs/agents/OVERVIEW.md` (plus `CONVENTIONS.md`, `STATUS.md`) — if that project was
   itself bootstrapped with ai-sdlc-bootstrap.
2. `<path>/AGENTS.md` or `<path>/CLAUDE.md`.
3. `<path>/README.md`.
4. None found — proceed on judgment, and say so explicitly rather than silently guessing.

`<path>` is the `local_path` from `.project.lock.yaml` — for both kinds now, since in-repo
entries carry a resolved absolute `local_path` there too, not just external ones.

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
