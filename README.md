# ai-skills

A collection of reusable AI agent skills. Install them into any repo in seconds, for Claude Code, Cursor, GitHub Copilot, Gemini CLI, Windsurf, or Aider.

## Quick install

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.ps1 | iex
```

Both scripts are interactive — they ask which skills to install, whether to install at the project or user level, and which agents to target.

**First run** installs skills; re-running detects what's already present and asks whether to update. To force-update without the prompt:

```bash
curl -fsSL https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.sh | bash -s -- --update
# or:  UPDATE_MODE=1 curl -fsSL ... | bash
```

```powershell
# Downloaded version:
.\install.ps1 -Update
# Piped version:
$env:UPDATE_MODE=1; irm https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.ps1 | iex
```

The scripts also auto-detect if the target folder is a git repo and add `linguist-vendored` entries to `.gitattributes` (suppresses skill files from GitHub's language stats). After a Claude Code project install, non-skill items left behind by `git subtree add` (e.g. `scripts/`, `README.md`) are detected and offered for cleanup.

### What gets installed where

| Agent | Project-level | User-level |
|---|---|---|
| Claude Code | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| Cursor | `.cursor/rules/<name>.mdc` | *(falls back to project)* |
| GitHub Copilot | `.github/copilot-instructions.md` | *(falls back to project)* |
| Gemini CLI | `GEMINI.md` | `~/.gemini/GEMINI.md` |
| Windsurf | `.windsurfrules` | `~/.windsurfrules` |
| Aider | `CONVENTIONS.md` | *(falls back to project)* |

> **Claude Code** gets the full skill directory (SKILL.md + all supporting files). All other agents receive only the skill body, formatted for their instruction-file convention. Supporting files such as `templates/` and `reference/` are Claude Code-specific and are not copied for other agents.

---

## Layout

Each skill lives in its own top-level directory containing a `SKILL.md` and any supporting files. No grouping subfolders, no nesting — only skill directories and repo meta files at the root.

```
ai-skills/
├── <skill-name>/
│   ├── SKILL.md
│   └── (optional: references/, templates/, etc.)
└── ...
```

## How Claude discovers skills

Claude only looks **one level deep** inside `.claude/skills/` — it does not recurse into subdirectories. A skill at `.claude/skills/<skill-name>/SKILL.md` is found; a skill at `.claude/skills/ai-skills/<skill-name>/SKILL.md` is not.

This means the subtree must be rooted at `.claude/skills/` directly, not a subdirectory of it.

## Consuming this repo

### Initial setup (run once in the consuming repo)

```bash
git subtree add --prefix=.claude/skills <this-repo-url> main --squash
```

### Pulling updates

```bash
git subtree pull --prefix=.claude/skills <this-repo-url> main --squash
```

### Optional Makefile snippet

Copy this into your consuming repo's `Makefile`:

```makefile
SKILLS_PREFIX := .claude/skills
SKILLS_REMOTE := <this-repo-url>
SKILLS_BRANCH := main

skills-update:
	git subtree pull --prefix=$(SKILLS_PREFIX) $(SKILLS_REMOTE) $(SKILLS_BRANCH) --squash
```

## Editing convention

Edit skills in this repo and pull them into consumers. Do not edit the vendored copy inside a consumer repo — `git subtree push` works in theory but gets fiddly when histories diverge. Treat the consumer copy as read-only.

## Tip: suppress language stats in consumers

Add this to `.gitattributes` in any consuming repo to keep vendored skills out of GitHub's language breakdown:

```
.claude/skills/** linguist-vendored
```

---

## License

Released under the [MIT License](./LICENSE) — Copyright (c) 2026 Shivam Mishra.

You are free to use, copy, modify, and redistribute these skills and install
scripts, including in commercial projects. The software is provided **"AS IS",
without warranty of any kind**. The author accepts **no liability** for any
damages, data loss, broken builds, or other consequences arising from use of
this code. See [`LICENSE`](./LICENSE) for the full text.
