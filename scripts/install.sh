#!/usr/bin/env bash
# install.sh — Install AI skills from github.com/shmmsra/ai-skills
#
# Usage (piped):
#   curl -fsSL https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.sh | bash
#   curl -fsSL ... | bash -s -- --update     # force-update existing installations
#
# Usage (downloaded):
#   bash install.sh [--update|-u]
#
# Env var:
#   UPDATE_MODE=1 curl -fsSL ... | bash

set -euo pipefail

# ── flags ─────────────────────────────────────────────────────────────
UPDATE_MODE=${UPDATE_MODE:-0}
for _arg in "$@"; do
  case "$_arg" in -u|--update) UPDATE_MODE=1 ;; esac
done

REPO_HTTPS="https://github.com/shmmsra/ai-skills"

# ── colors ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; DIM=''; NC=''
fi

log()     { printf "${BLUE}→${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}✓${NC}  %s\n" "$*"; }
warn()    { printf "${YELLOW}!${NC}  %s\n" "$*"; }
die()     { printf "${RED}✗${NC}  %s\n" "$*" >&2; exit 1; }
heading() { printf "\n${BOLD}%s${NC}\n" "$*"; }
dim()     { printf "${DIM}%s${NC}\n" "$*"; }

# ── prereqs ───────────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1 || die "Required tool not found: $1"; }
need git
need curl

# ── clone repo to temp dir ────────────────────────────────────────────
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

log "Fetching skills repository (shallow clone)…"
git clone --depth=1 --quiet "$REPO_HTTPS" "$WORKDIR/repo" \
  || die "Failed to clone $REPO_HTTPS"

# ── discover skills ───────────────────────────────────────────────────
ALL_SKILLS=()
for _d in "$WORKDIR/repo"/skills/*/; do
  [ -f "${_d}SKILL.md" ] && ALL_SKILLS+=("$(basename "$_d")")
done

IFS=$'\n' ALL_SKILLS=($(printf '%s\n' "${ALL_SKILLS[@]}" | sort))
unset IFS

[ "${#ALL_SKILLS[@]}" -gt 0 ] || die "No skills found in repository."

# ── helper: strip YAML frontmatter, return body ───────────────────────
skill_body() {
  awk 'BEGIN{n=0} /^---$/{n++;next} n>=2{print}' "$1"
}

# ── helper: first line of description field ───────────────────────────
skill_desc() {
  awk '
    /^description:/{
      if ($0 !~ /\|$/) { sub(/^description:[[:space:]]*/,""); print; exit }
      found=1; next
    }
    found && /^[[:space:]]/ { sub(/^[[:space:]]*/,""); print; exit }
    found && !/^[[:space:]]/ { exit }
  ' "$1" | cut -c1-120
}

# ── helper: remove a skill block from an instruction file ─────────────
# Strips everything from <!-- skill:NAME --> through <!-- /skill:NAME -->
remove_skill_block() {
  local file="$1" skill="$2"
  [ -f "$file" ] || return 0
  local tmp om cm
  tmp=$(mktemp)
  om="<!-- skill:${skill} -->"
  cm="<!-- /skill:${skill} -->"
  awk -v om="$om" -v cm="$cm" '
    {gsub(/\r/,"")}
    $0==om{skip=1;next}
    skip&&$0==cm{skip=0;next}
    !skip{print}
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# ── helper: insert or update a skill block ────────────────────────────
# Skips if already present and UPDATE_MODE=0; replaces if UPDATE_MODE=1.
guarded_upsert() {
  local file="$1" skill="$2" content="$3"
  local exists=0
  [ -f "$file" ] && grep -q "<!-- skill:${skill} -->" "$file" 2>/dev/null && exists=1

  if [ "$exists" -eq 1 ]; then
    if [ "$UPDATE_MODE" -eq 1 ]; then
      remove_skill_block "$file" "$skill"
      printf '%s\n' "$content" >> "$file"
      ok "    updated in $file"
    else
      warn "    Already present in $file — skipping  (use --update to overwrite)"
    fi
  else
    printf '%s\n' "$content" >> "$file"
  fi
}

# ── helper: add a pattern to .gitattributes at the git root ──────────
add_gitattribute() {
  local pattern="$1"
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  local attrs="$git_root/.gitattributes"
  if ! grep -qF "$pattern" "$attrs" 2>/dev/null; then
    printf '%s\n' "$pattern" >> "$attrs"
    ok "    .gitattributes  →  added '$pattern'"
  fi
}


# ── multi-select prompt ───────────────────────────────────────────────
# Sets global REPLY_INDICES array.
ask_multiselect() {
  local prompt="$1"; shift
  local items=("$@")
  heading "$prompt"
  local i
  for i in $(seq 0 $((${#items[@]} - 1))); do
    printf "  %2d.  %s\n" "$((i+1))" "${items[$i]}"
  done
  printf "   a.  All\n\n"
  local raw
  read -rp "  Select (e.g. 1,2 or a): " raw < /dev/tty
  REPLY_INDICES=()
  case "$raw" in
    a|A|all|ALL)
      for i in $(seq 0 $((${#items[@]} - 1))); do REPLY_INDICES+=("$i"); done
      return 0
      ;;
  esac
  IFS=',' read -ra _parts <<< "$raw"
  local _p _n
  for _p in "${_parts[@]}"; do
    _n=$(echo "$_p" | tr -d ' ')
    if echo "$_n" | grep -qE '^[0-9]+$' && [ "$_n" -ge 1 ] && [ "$_n" -le "${#items[@]}" ]; then
      REPLY_INDICES+=("$((_n-1))")
    else
      warn "    Skipping unrecognised input: $_p"
    fi
  done
  [ "${#REPLY_INDICES[@]}" -gt 0 ] || die "No valid selections made."
}

# ────────────────────────────────────────────────────────────────────
# Interactive flow
# ────────────────────────────────────────────────────────────────────

# ── 1. Skill selection ────────────────────────────────────────────────
ask_multiselect "Which skills would you like to install?" "${ALL_SKILLS[@]}"
CHOSEN_SKILLS=()
for _idx in "${REPLY_INDICES[@]}"; do CHOSEN_SKILLS+=("${ALL_SKILLS[$_idx]}"); done

# ── 2. Scope ──────────────────────────────────────────────────────────
heading "Install scope"
printf "  1.  Project  — installs into the current working directory\n"
printf "  2.  User     — installs globally (~/.claude, ~/.gemini, ~/.windsurfrules)\n\n"
dim "  Note: user-level is supported by Claude Code, Gemini CLI, and Windsurf."
dim "        Other agents fall back to project-level automatically."
printf "\n"
read -rp "  Scope [1/2, default 1]: " SCOPE_INPUT < /dev/tty
SCOPE="project"
[ "$SCOPE_INPUT" = "2" ] && SCOPE="user"

# ── 3. Agent selection ────────────────────────────────────────────────
AGENT_KEYS=(claude-code cursor copilot gemini windsurf aider)
AGENT_LABELS=(
  "Claude Code     →  .claude/skills/<name>/"
  "Cursor          →  .cursor/rules/<name>.mdc"
  "GitHub Copilot  →  .github/copilot-instructions.md"
  "Gemini CLI      →  GEMINI.md"
  "Windsurf        →  .windsurfrules"
  "Aider           →  CONVENTIONS.md"
)

ask_multiselect "Which agents to install for?" "${AGENT_LABELS[@]}"
CHOSEN_AGENTS=()
for _idx in "${REPLY_INDICES[@]}"; do CHOSEN_AGENTS+=("${AGENT_KEYS[$_idx]}"); done

# ── 4. Pre-install scan ───────────────────────────────────────────────
# Detect any skills already installed and offer update mode.
EXISTING_FOUND=0
_check_file=""

for _skill in "${CHOSEN_SKILLS[@]}"; do
  for _agent in "${CHOSEN_AGENTS[@]}"; do
    case "$_agent" in
      claude-code)
        [ "$SCOPE" = "user" ] && _check_file="$HOME/.claude/skills/$_skill" \
                              || _check_file=".claude/skills/$_skill"
        if [ -d "$_check_file" ]; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
      cursor)
        if [ -f ".cursor/rules/$_skill.mdc" ]; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
      copilot)
        if grep -q "<!-- skill:$_skill -->" ".github/copilot-instructions.md" 2>/dev/null; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
      gemini)
        [ "$SCOPE" = "user" ] && _check_file="$HOME/.gemini/GEMINI.md" || _check_file="GEMINI.md"
        if grep -q "<!-- skill:$_skill -->" "$_check_file" 2>/dev/null; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
      windsurf)
        [ "$SCOPE" = "user" ] && _check_file="$HOME/.windsurfrules" || _check_file=".windsurfrules"
        if grep -q "<!-- skill:$_skill -->" "$_check_file" 2>/dev/null; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
      aider)
        if grep -q "<!-- skill:$_skill -->" "CONVENTIONS.md" 2>/dev/null; then
          warn "  Existing: $_agent / $_skill"
          EXISTING_FOUND=1
        fi
        ;;
    esac
  done
done

if [ "$EXISTING_FOUND" -eq 1 ] && [ "$UPDATE_MODE" -eq 0 ]; then
  echo
  read -rp "  Update existing installations? [y/N]: " _ans < /dev/tty
  case "$_ans" in [yY]*) UPDATE_MODE=1 ;; esac
fi

# ── 5. Confirm ────────────────────────────────────────────────────────
heading "Summary"
printf "  Skills  :  %s\n" "$(IFS=', '; echo "${CHOSEN_SKILLS[*]}")"
printf "  Scope   :  %s\n" "$SCOPE"
printf "  Agents  :  %s\n" "$(IFS=', '; echo "${CHOSEN_AGENTS[*]}")"
[ "$UPDATE_MODE" -eq 1 ] && printf "  Mode    :  update (existing will be replaced)\n"
printf "\n"
read -rp "  Proceed? [Y/n]: " CONFIRM < /dev/tty
case "$CONFIRM" in [nN]*) log "Aborted."; exit 0 ;; esac

# ────────────────────────────────────────────────────────────────────
# Install functions
# ────────────────────────────────────────────────────────────────────

install_claude_code() {
  local skill="$1" dest
  [ "$SCOPE" = "user" ] && dest="$HOME/.claude/skills/$skill" \
                        || dest=".claude/skills/$skill"

  if [ -d "$dest" ] && [ "$UPDATE_MODE" -eq 0 ]; then
    warn "    Already present — skipping  (use --update to overwrite)"
    return 0
  fi

  mkdir -p "$dest"
  cp -r "$WORKDIR/repo/skills/$skill/." "$dest/"
  ok "Claude Code  →  $dest/"

  # Suppress language stat noise for vendored skill files
  [ "$SCOPE" = "project" ] && add_gitattribute ".claude/skills/** linguist-vendored"
}

install_cursor() {
  local skill="$1"
  [ "$SCOPE" = "user" ] && warn "    Cursor: no standard user-level location — installing at project level"

  local dest=".cursor/rules" dest_file=".cursor/rules/$skill.mdc"

  if [ -f "$dest_file" ] && [ "$UPDATE_MODE" -eq 0 ]; then
    warn "    Already present — skipping  (use --update to overwrite)"
    return 0
  fi

  mkdir -p "$dest"
  local src="$WORKDIR/repo/skills/$skill/SKILL.md"
  {
    printf -- '---\n'
    printf 'description: "%s"\n' "$(skill_desc "$src")"
    printf 'globs:\nalwaysApply: false\n'
    printf -- '---\n\n'
    skill_body "$src"
  } > "$dest_file"
  ok "Cursor       →  $dest_file"

  add_gitattribute ".cursor/rules/*.mdc linguist-vendored"
}

install_copilot() {
  local skill="$1"
  [ "$SCOPE" = "user" ] && warn "    GitHub Copilot: no standard user-level location — installing at project level"
  local dest=".github/copilot-instructions.md"
  mkdir -p .github
  local body; body=$(skill_body "$WORKDIR/repo/skills/$skill/SKILL.md")
  guarded_upsert "$dest" "$skill" \
    "$(printf '\n<!-- skill:%s -->\n%s\n<!-- /skill:%s -->' "$skill" "$body" "$skill")"
  [ "$?" -eq 0 ] && ok "Copilot      →  $dest"
}

install_gemini() {
  local skill="$1" dest
  if [ "$SCOPE" = "user" ]; then
    dest="$HOME/.gemini/GEMINI.md"; mkdir -p "$HOME/.gemini"
  else
    dest="GEMINI.md"
  fi
  local body; body=$(skill_body "$WORKDIR/repo/skills/$skill/SKILL.md")
  guarded_upsert "$dest" "$skill" \
    "$(printf '\n<!-- skill:%s -->\n%s\n<!-- /skill:%s -->' "$skill" "$body" "$skill")"
  [ "$?" -eq 0 ] && ok "Gemini       →  $dest"
}

install_windsurf() {
  local skill="$1" dest
  [ "$SCOPE" = "user" ] && dest="$HOME/.windsurfrules" || dest=".windsurfrules"
  local body; body=$(skill_body "$WORKDIR/repo/skills/$skill/SKILL.md")
  guarded_upsert "$dest" "$skill" \
    "$(printf '\n<!-- skill:%s -->\n%s\n<!-- /skill:%s -->' "$skill" "$body" "$skill")"
  [ "$?" -eq 0 ] && ok "Windsurf     →  $dest"
}

install_aider() {
  local skill="$1"
  [ "$SCOPE" = "user" ] && warn "    Aider: no standard user-level location — installing at project level"
  local dest="CONVENTIONS.md"
  local body; body=$(skill_body "$WORKDIR/repo/skills/$skill/SKILL.md")
  guarded_upsert "$dest" "$skill" \
    "$(printf '\n<!-- skill:%s -->\n%s\n<!-- /skill:%s -->' "$skill" "$body" "$skill")"
  [ "$?" -eq 0 ] && ok "Aider        →  $dest"
}

# ────────────────────────────────────────────────────────────────────
# Main install loop
# ────────────────────────────────────────────────────────────────────
heading "Installing…"
echo ""

for _skill in "${CHOSEN_SKILLS[@]}"; do
  printf "${BOLD}  %s${NC}\n" "$_skill"
  for _agent in "${CHOSEN_AGENTS[@]}"; do
    case "$_agent" in
      claude-code) install_claude_code "$_skill" ;;
      cursor)      install_cursor      "$_skill" ;;
      copilot)     install_copilot     "$_skill" ;;
      gemini)      install_gemini      "$_skill" ;;
      windsurf)    install_windsurf    "$_skill" ;;
      aider)       install_aider       "$_skill" ;;
    esac
  done
  echo ""
done

ok "All done. Skills are ready to use."
