#!/usr/bin/env bash
#
# ai-sdlc-bootstrap multi-repo engine v2.3
#
# Resolves project.deps.yaml (raw, hand-authored) into .project.lock.yaml
# (gitignored, fully resolved — the source of truth agents should read).
# Covers macOS and Linux. See scripts/update-project-lock.ps1 for Windows.
# Full design: reference/multi-repo.md in the ai-sdlc-bootstrap skill.
#
# Both in-repo and external entries are graph nodes in the same recursive
# walk: an in-repo sub-project's own project.deps.yaml (if it has one) is
# walked exactly like an external dependency's, at any depth, in any mix.
#
# Usage:
#   scripts/update-project-lock.sh [options]
#
# Options:
#   --set NAME=PATH   Pre-supply a local path for an external dependency
#                      (repeatable). Always wins over the lock file or the
#                      sibling-path guess. Not applicable to in-repo entries
#                      (their path is always relative to a known checkout).
#   --yes, -y          Auto-accept clone offers using the conventional sibling path.
#   --no-clone         Never offer/perform a clone; list what's missing instead.
#   --check            Verify only — no prompting, no mutation. Exit non-zero if
#                      anything required is unresolved or missing on disk.
#   --porcelain        Combine with --check: also emit one `DECISION ...` line
#                      per entry needing a human decision, on stdout (machine-
#                      parseable, in addition to the existing stderr text).
#                      Requires --check.
#   --require-decisions
#                      Combine with a real (mutating) run: fail non-zero if any
#                      optional dependency would be silently skipped instead of
#                      resolved — use after every decision has been supplied
#                      via --set, as a safety net against a decision surfacing
#                      after --check was last run.
#   -h, --help         Show this help.
#
# Non-interactive (agent) usage: never invoke this bare and expect it to prompt —
# there is no TTY in a tool-call shell. Ask the human for any missing path first,
# then re-run with --set name=path for each. See CONTRIBUTING.md for the full
# two-mode contract.
#
# Bash-3.2 compatible on purpose (macOS ships bash 3.2 as /bin/bash by default —
# no associative arrays, no negative array indices). Uses parallel indexed
# arrays + linear-scan lookups instead. Dependency counts are always small, so
# the O(n) lookups are not a real cost.

set -eo pipefail
# Deliberately no `-u`: bash 3.2 (macOS's default /bin/bash) treats expanding
# an empty array with ${arr[@]} as an unbound-variable error under `set -u` —
# fixed in later bash, but this script targets 3.2 too. See reference/multi-repo.md.

CHECK_ONLY=0
AUTO_YES=0
NO_CLONE=0
PORCELAIN=0
REQUIRE_DECISIONS=0
DECISIONS_NEEDED=0
PRESET_NAMES=()
PRESET_VALUES=()

usage() {
  sed -n '2,41p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --set)
      [ $# -ge 2 ] || { echo "error: --set requires NAME=PATH" >&2; exit 64; }
      PRESET_NAMES+=("${2%%=*}")
      PRESET_VALUES+=("${2#*=}")
      shift 2
      ;;
    --yes|-y) AUTO_YES=1; shift ;;
    --no-clone) NO_CLONE=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    --porcelain) PORCELAIN=1; shift ;;
    --require-decisions) REQUIRE_DECISIONS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument '$1'" >&2; usage; exit 64 ;;
  esac
done

if [ "${PORCELAIN}" -eq 1 ] && [ "${CHECK_ONLY}" -eq 0 ]; then
  echo "error: --porcelain requires --check" >&2
  exit 64
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "${REPO_ROOT}" ]; then
  echo "error: not inside a git repository" >&2
  exit 1
fi
cd "${REPO_ROOT}"

MANIFEST="${REPO_ROOT}/project.deps.yaml"
LOCK_FILE="${REPO_ROOT}/.project.lock.yaml"

if [ ! -f "${MANIFEST}" ]; then
  echo "no project.deps.yaml found — nothing to resolve"
  exit 0
fi

# ─── parallel-array map helpers (bash-3.2 safe) ─────────────────────────────

# map_get <needle> <keys-array-name> <values-array-name>
# Prints the matching value, or nothing (and returns 1) if not found.
map_get() {
  local needle="$1" keys_name="$2" vals_name="$3"
  local -a keys vals
  eval "keys=(\"\${${keys_name}[@]}\")"
  eval "vals=(\"\${${vals_name}[@]}\")"
  local i=0
  for k in "${keys[@]:-}"; do
    if [ "${k}" = "${needle}" ]; then
      printf '%s' "${vals[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

# map_set <key> <value> <keys-array-name> <values-array-name>
# Updates in place if the key exists, else appends.
map_set() {
  local key="$1" val="$2" keys_name="$3" vals_name="$4"
  local -a keys
  eval "keys=(\"\${${keys_name}[@]}\")"
  local i=0
  for k in "${keys[@]:-}"; do
    if [ "${k}" = "${key}" ]; then
      eval "${vals_name}[${i}]=\"\${val}\""
      return 0
    fi
    i=$((i + 1))
  done
  eval "${keys_name}+=(\"\${key}\")"
  eval "${vals_name}+=(\"\${val}\")"
}

# ─── restricted-YAML parser ────────────────────────────────────────────────
#
# Emits one \x1e-terminated record per entry under `projects:`, fields joined
# by \x1f, in the fixed order: name path repo notes required local_path
# parent depth kind. Handles both the manifest (name/path/repo/notes/required)
# and the lock file (name/kind/path/repo/local_path/notes/parent/depth) —
# unknown/absent fields stay empty. \x1e (not \n) terminates each record
# because a field's value — notes, once multi-line — may itself contain real
# newlines.
#
# Supports YAML's literal block scalar (`key: |`) for any field, most useful
# for multi-line `notes`: content lines must be indented >= 6 spaces (more
# than the normal 4-space continuation-field indent, regardless of whether
# the field appeared on the list-item's own line or a continuation line);
# blank lines are part of the block; the block ends at the first non-blank
# line indented less than that. Folded scalars (`>`) are not supported.

parse_project_list() {
  local file="$1"
  local in_list=0 have_record=0
  local f_name="" f_path="" f_repo="" f_notes="" f_required="true" f_local_path="" f_parent="" f_depth="" f_kind=""
  local in_block=0 block_key="" block_strip=-1
  local -a block_lines=()

  # Records are terminated with \x1e (not \n): a field's value — notes, once
  # multi-line — may itself contain real newlines, so \n can't double as the
  # record separator without splitting one record into several wherever a
  # value happens to wrap. Every consumer reads with `read -d $'\x1e'`.
  emit_record() {
    if [ "${have_record}" -eq 1 ]; then
      printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1e' \
        "${f_name}" "${f_path}" "${f_repo}" "${f_notes}" "${f_required}" \
        "${f_local_path}" "${f_parent}" "${f_depth}" "${f_kind}"
    fi
  }

  set_field() {
    local key="$1" val="$2"
    val="${val%\"}"; val="${val#\"}"
    case "${key}" in
      name) f_name="${val}" ;;
      path) f_path="${val}" ;;
      repo) f_repo="${val}" ;;
      notes) f_notes="${val}" ;;
      required) f_required="${val}" ;;
      local_path) f_local_path="${val}" ;;
      parent) f_parent="${val}" ;;
      depth) f_depth="${val}" ;;
      kind) f_kind="${val}" ;;
    esac
  }

  # Finalizes an in-progress block scalar into its field (YAML "clip"
  # chomping — trailing blank lines are dropped), then clears block state.
  finish_block() {
    [ "${in_block}" -eq 1 ] || return 0
    local n=${#block_lines[@]}
    while [ "${n}" -gt 0 ] && [ -z "${block_lines[$((n - 1))]}" ]; do
      n=$((n - 1))
    done
    local joined="" i
    for ((i = 0; i < n; i++)); do
      if [ "${i}" -eq 0 ]; then
        joined="${block_lines[$i]}"
      else
        joined="${joined}"$'\n'"${block_lines[$i]}"
      fi
    done
    set_field "${block_key}" "${joined}"
    in_block=0
    block_key=""
    block_strip=-1
    block_lines=()
  }

  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line%$'\r'}"

    if [ "${in_block}" -eq 1 ]; then
      if [ -z "${line}" ]; then
        block_lines+=("")
        continue
      fi
      local leading=0
      [[ "${line}" =~ ^([[:space:]]*) ]] && leading=${#BASH_REMATCH[1]}
      if [ "${leading}" -ge 6 ]; then
        [ "${block_strip}" -lt 0 ] && block_strip="${leading}"
        local strip_n="${block_strip}"
        [ "${leading}" -lt "${strip_n}" ] && strip_n="${leading}"
        block_lines+=("${line:${strip_n}}")
        continue
      fi
      finish_block
      # not part of the block — fall through and reprocess this line below
    fi

    if [[ "${line}" =~ ^projects:[[:space:]]*$ ]]; then
      in_list=1
      continue
    fi
    [ "${in_list}" -eq 0 ] && continue
    if [[ "${line}" =~ ^[[:space:]]{2}-[[:space:]]+([a-zA-Z_]+):[[:space:]]*(.*)$ ]]; then
      local rec_key="${BASH_REMATCH[1]}" rec_val="${BASH_REMATCH[2]}"
      emit_record
      f_name="" f_path="" f_repo="" f_notes="" f_required="true" f_local_path="" f_parent="" f_depth="" f_kind=""
      have_record=1
      if [[ "${rec_val}" =~ ^\|[+-]?[0-9]*[[:space:]]*$ ]]; then
        in_block=1; block_key="${rec_key}"; block_strip=-1; block_lines=()
      else
        set_field "${rec_key}" "${rec_val}"
      fi
      continue
    fi
    if [[ "${line}" =~ ^[[:space:]]{4,}([a-zA-Z_]+):[[:space:]]*(.*)$ ]]; then
      local cont_key="${BASH_REMATCH[1]}" cont_val="${BASH_REMATCH[2]}"
      if [[ "${cont_val}" =~ ^\|[+-]?[0-9]*[[:space:]]*$ ]]; then
        in_block=1; block_key="${cont_key}"; block_strip=-1; block_lines=()
      else
        set_field "${cont_key}" "${cont_val}"
      fi
      continue
    fi
    if [[ "${line}" =~ ^[^[:space:]] ]]; then
      in_list=0
    fi
  done < "${file}"
  finish_block
  emit_record
}

ROOT_NAME="$(sed -nE 's/^name:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' "${MANIFEST}" | head -n1)"

# ─── load existing lock (best-effort local-path reuse for external entries) ─

EXISTING_NAMES=()
EXISTING_PATHS=()
if [ -f "${LOCK_FILE}" ]; then
  while IFS=$'\x1f' read -r -d $'\x1e' name path repo notes required local_path parent depth kind; do
    if [ -n "${name}" ]; then
      EXISTING_NAMES+=("${name}")
      EXISTING_PATHS+=("${local_path}")
    fi
  done < <(parse_project_list "${LOCK_FILE}")
fi

# ─── local-path resolution (external entries only) ──────────────────────────

resolve_local_path() {
  local name="$1" repo="$2"
  local candidate="" existing=""
  local sibling
  sibling="$(cd "${REPO_ROOT}/.." 2>/dev/null && pwd -P)/${name}"

  local preset=""
  if preset="$(map_get "${name}" PRESET_NAMES PRESET_VALUES)"; then
    candidate="${preset}"
  elif existing="$(map_get "${name}" EXISTING_NAMES EXISTING_PATHS)" && [ -d "${existing}/.git" ]; then
    candidate="${existing}"
  elif [ -d "${sibling}/.git" ]; then
    candidate="${sibling}"
  elif [ "${CHECK_ONLY}" -eq 1 ]; then
    printf ''
    return 0
  elif [ -t 0 ] && [ -t 1 ]; then
    read -r -p "Local path for '${name}' (${repo})? [blank = offer to clone] " candidate
  fi

  if [ -z "${candidate}" ]; then
    if [ "${NO_CLONE}" -eq 1 ]; then
      printf ''
      return 0
    fi
    local do_clone="${AUTO_YES}"
    if [ "${do_clone}" -ne 1 ] && [ -t 0 ] && [ -t 1 ]; then
      local ans=""
      read -r -p "Clone '${repo}' into '${sibling}'? [y/N] " ans
      case "${ans}" in y|Y|yes|YES) do_clone=1 ;; esac
    fi
    if [ "${do_clone}" -eq 1 ]; then
      echo "Cloning ${repo} into ${sibling} ..." >&2
      git clone "${repo}" "${sibling}" >&2
      candidate="$(cd "${sibling}" && pwd -P)"
    else
      printf ''
      return 0
    fi
  else
    if [ ! -d "${candidate}/.git" ]; then
      echo "warning: '${candidate}' does not look like a git checkout (no .git)" >&2
    fi
    candidate="$(cd "${candidate}" && pwd -P)"
  fi

  printf '%s' "${candidate}"
}

# ─── unified DFS resolution (in-repo + external) with cycle detection ───────

NODE_KEYS=()
NODE_STATES=()
CYCLE_CHAIN=()
LOCK_KEYS=()
LOCK_NAMES=()
LOCK_KINDS=()
LOCK_REPOS=()
LOCK_PATHS=()
LOCK_LOCALPATHS=()
LOCK_NOTES=()
LOCK_PARENTS=()
LOCK_DEPTHS=()

normalize_repo() {
  local r="$1"
  r="${r%.git}"
  r="${r#git@}"
  r="${r#ssh://}"
  r="${r#https://}"
  r="${r#http://}"
  r="${r#git://}"
  r="${r/://}"
  printf '%s' "${r}"
}

FAILED=0

# resolve_node <name> <repo> <path> <notes> <required> <parent> <depth> <base_dir>
#
# <repo> empty  → in-repo entry. <path> is resolved relative to <base_dir>
#                 (the local_path of whichever manifest declared it — the
#                 repo root at depth 1, or a previously-resolved node's
#                 checkout at deeper levels). No resolution is possible to
#                 fail — the path is either there or it isn't.
# <repo> set    → external entry. Resolved via resolve_local_path exactly as
#                 before; <base_dir> is irrelevant for it.
#
# Either kind, once resolved, is recorded in the lock and recursed into if it
# has its own project.deps.yaml — the walk doesn't care which kind a node or
# its children are.
resolve_node() {
  local name="$1" repo="$2" path="$3" notes="$4" required="$5" parent="$6" depth="$7" base_dir="$8"
  local kind key local_path=""

  if [ -z "${repo}" ]; then
    kind="in-repo"
    local joined="${base_dir%/}/${path}"
    if [ -d "${joined}" ]; then
      local_path="$(cd "${joined}" && pwd -P)"
    else
      local_path="${joined}"
      echo "warning: in-repo project '${name}' declares path '${path}' which does not exist (looked under ${base_dir})" >&2
    fi
    key="inrepo|${local_path}"
  else
    kind="external"
    local repo_norm
    repo_norm="$(normalize_repo "${repo}")"
    key="ext|${repo_norm}|${path}"
  fi

  local state
  if state="$(map_get "${key}" NODE_KEYS NODE_STATES)"; then
    if [ "${state}" = "stack" ]; then
      echo "error: cyclic dependency detected — ${CYCLE_CHAIN[*]} -> ${name}" >&2
      exit 1
    fi
    if [ "${state}" = "done" ]; then
      return 0
    fi
  fi

  map_set "${key}" "stack" NODE_KEYS NODE_STATES
  CYCLE_CHAIN+=("${name}")

  if [ "${kind}" = "external" ]; then
    local_path="$(resolve_local_path "${name}" "${repo}")"
  fi

  if [ "${kind}" = "in-repo" ] || [ -n "${local_path}" ]; then
    LOCK_KEYS+=("${key}")
    LOCK_NAMES+=("${name}")
    LOCK_KINDS+=("${kind}")
    LOCK_REPOS+=("${repo}")
    LOCK_PATHS+=("${path}")
    LOCK_LOCALPATHS+=("${local_path}")
    LOCK_NOTES+=("${notes}")
    LOCK_PARENTS+=("${parent}")
    LOCK_DEPTHS+=("${depth}")

    # For an external entry with a `path` (a subpath into a monorepo
    # dependency), the addressed package's own project.deps.yaml — and
    # anything it declares in-repo — lives under local_path/path, not at
    # local_path (the checkout root). node_dir is that effective directory;
    # it's what recursion and any in-repo children resolve relative to.
    local node_dir="${local_path}"
    if [ "${kind}" = "external" ] && [ -n "${path}" ]; then
      node_dir="${local_path%/}/${path}"
    fi

    # If this node has its own .project.lock.yaml (it was independently
    # resolved before, on this machine, outside of this run), seed its
    # already-resolved external entries into PRESET_NAMES/PRESET_VALUES —
    # the same top-priority mechanism --set uses — so resolving this node's
    # own dependencies below can reuse them instead of asking from scratch.
    # An explicit --set (or an already-known top-level lock entry) always
    # outranks this and is never overwritten.
    local child_lock="${node_dir}/.project.lock.yaml"
    if [ -f "${child_lock}" ]; then
      while IFS=$'\x1f' read -r -d $'\x1e' s_name s_path s_repo s_notes s_required s_localpath s_parent s_depth s_kind; do
        [ -z "${s_name}" ] && continue
        [ "${s_kind}" != "external" ] && continue
        map_get "${s_name}" PRESET_NAMES PRESET_VALUES >/dev/null && continue
        map_get "${s_name}" EXISTING_NAMES EXISTING_PATHS >/dev/null && continue
        [ -d "${s_localpath}/.git" ] || continue

        if [ "${CHECK_ONLY}" -eq 1 ]; then
          echo "preset: '${s_name}' already resolved by '${name}'s own lock at ${s_localpath}" >&2
          if [ "${PORCELAIN}" -eq 1 ]; then
            echo "DECISION name=${s_name} repo=${s_repo} parent=${name} kind=preset preset_path=${s_localpath}"
          fi
          map_set "${s_name}" "${s_localpath}" PRESET_NAMES PRESET_VALUES
        elif [ -t 0 ] && [ -t 1 ]; then
          local p_ans=""
          read -r -p "Found '${s_name}' already resolved by '${name}'s own lock at '${s_localpath}' — use it? [Y/n, or type a different path] " p_ans
          case "${p_ans}" in
            ""|y|Y|yes|YES)
              echo "preset: using '${s_name}' -> ${s_localpath}" >&2
              map_set "${s_name}" "${s_localpath}" PRESET_NAMES PRESET_VALUES
              ;;
            n|N|no|NO) : ;; # declined — fall through to normal resolution for this name
            *)
              if [ ! -d "${p_ans}/.git" ]; then
                echo "warning: '${p_ans}' does not look like a git checkout (no .git)" >&2
              fi
              p_ans="$(cd "${p_ans}" 2>/dev/null && pwd -P || printf '%s' "${p_ans}")"
              echo "preset: using '${s_name}' -> ${p_ans}" >&2
              map_set "${s_name}" "${p_ans}" PRESET_NAMES PRESET_VALUES
              ;;
          esac
        else
          echo "preset: '${s_name}' already resolved by '${name}'s own lock at ${s_localpath} — using it (pass --set ${s_name}=PATH to override)" >&2
          map_set "${s_name}" "${s_localpath}" PRESET_NAMES PRESET_VALUES
        fi
      done < <(parse_project_list "${child_lock}")
    fi

    local child_manifest="${node_dir}/project.deps.yaml"
    if [ -f "${child_manifest}" ]; then
      while IFS=$'\x1f' read -r -d $'\x1e' c_name c_path c_repo c_notes c_required c_lp c_par c_dep c_kind; do
        [ -z "${c_name}" ] && continue
        resolve_node "${c_name}" "${c_repo}" "${c_path}" "${c_notes}" "${c_required}" "${name}" "$((depth + 1))" "${node_dir}"
      done < <(parse_project_list "${child_manifest}")
    fi
  elif [ "${required}" = "true" ]; then
    echo "error: required project '${name}' (${repo}) could not be resolved" >&2
    if [ "${PORCELAIN}" -eq 1 ]; then
      echo "DECISION name=${name} repo=${repo} parent=${parent} kind=unresolved required=true"
    fi
    FAILED=1
  else
    echo "warning: optional project '${name}' (${repo}) not resolved — skipping" >&2
    if [ "${PORCELAIN}" -eq 1 ]; then
      echo "DECISION name=${name} repo=${repo} parent=${parent} kind=unresolved required=false"
    fi
    DECISIONS_NEEDED=$((DECISIONS_NEEDED + 1))
  fi

  map_set "${key}" "done" NODE_KEYS NODE_STATES
  unset "CYCLE_CHAIN[$((${#CYCLE_CHAIN[@]} - 1))]"
}

while IFS=$'\x1f' read -r -d $'\x1e' name path repo notes required local_path parent depth kind; do
  [ -z "${name}" ] && continue
  resolve_node "${name}" "${repo}" "${path}" "${notes}" "${required}" "root" 1 "${REPO_ROOT}"
done < <(parse_project_list "${MANIFEST}")

if [ "${FAILED}" -eq 1 ]; then
  exit 1
fi

if [ "${REQUIRE_DECISIONS}" -eq 1 ] && [ "${DECISIONS_NEEDED}" -gt 0 ]; then
  echo "error: ${DECISIONS_NEEDED} project(s) need a human decision before this can complete — run --check first" >&2
  exit 1
fi

# ─── --check: report only, never write ──────────────────────────────────────

if [ "${CHECK_ONLY}" -eq 1 ]; then
  MISSING=0
  i=0
  for key in "${LOCK_KEYS[@]:-}"; do
    if [ ! -d "${LOCK_LOCALPATHS[$i]}" ]; then
      echo "error: '${LOCK_NAMES[$i]}' local path no longer exists: ${LOCK_LOCALPATHS[$i]}" >&2
      MISSING=1
    fi
    i=$((i + 1))
  done
  if [ "${MISSING}" -eq 1 ]; then
    exit 1
  fi
  echo "all related projects resolved"
  exit 0
fi

# ─── write the lock file ────────────────────────────────────────────────────
#
# write_field emits a flat `key: value` line, unless the value contains an
# embedded newline (e.g. a multi-line `notes`), in which case it emits a
# literal block scalar (`key: |` + 6-space-indented lines) — the exact
# counterpart to parse_project_list's block-scalar reader, so a multi-line
# value carried through from project.deps.yaml round-trips correctly.
write_field() {
  local key="$1" val="$2"
  if [[ "${val}" == *$'\n'* ]]; then
    printf '    %s: |\n' "${key}"
    while IFS= read -r vline || [ -n "${vline}" ]; do
      printf '      %s\n' "${vline}"
    done <<< "${val}"
  else
    printf '    %s: %s\n' "${key}" "${val}"
  fi
}

{
  printf 'resolved_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'root: %s\n' "${ROOT_NAME}"
  printf 'projects:\n'
  i=0
  for key in "${LOCK_KEYS[@]:-}"; do
    printf '  - name: %s\n' "${LOCK_NAMES[$i]}"
    write_field kind "${LOCK_KINDS[$i]}"
    write_field repo "${LOCK_REPOS[$i]}"
    write_field path "${LOCK_PATHS[$i]}"
    write_field local_path "${LOCK_LOCALPATHS[$i]}"
    write_field notes "${LOCK_NOTES[$i]}"
    write_field parent "${LOCK_PARENTS[$i]}"
    write_field depth "${LOCK_DEPTHS[$i]}"
    i=$((i + 1))
  done
} > "${LOCK_FILE}"

echo "wrote ${LOCK_FILE}"
