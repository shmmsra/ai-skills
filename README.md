# ai-skills

A collection of reusable Claude Code skills, designed to be consumed by other repos via git subtree.

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
