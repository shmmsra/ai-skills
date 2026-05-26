.PHONY: check setup-hooks lint test typecheck build clean help

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo "Available targets:"
	@echo "  make check         Pre-commit gate: shell script syntax check"
	@echo "  make setup-hooks   Install .git/hooks/pre-commit (run once after clone)"
	@echo "  make lint          Shell script syntax check (same as check)"
	@echo "  make test          No automated test suite — see docs/manual-testing.md"
	@echo "  make clean         No build artifacts to clean"

# ── Pre-commit gate ──────────────────────────────────────────────────────────

check: lint

# ── Hook installation ─────────────────────────────────────────────────────────

setup-hooks:
	bash scripts/setup-hooks.sh

# ── Lint: shell script syntax check ──────────────────────────────────────────

lint:
	@echo "→ Shell script syntax check..."
	@find scripts -name '*.sh' -exec bash -n {} \; && echo "✓ scripts/ — all shell scripts are syntactically valid"
	@find .claude/skills -name '*.sh' -exec bash -n {} \; 2>/dev/null && echo "✓ .claude/skills/ — all shell scripts are syntactically valid" || true

# ── Stubs ─────────────────────────────────────────────────────────────────────

test:
	@echo "No automated test suite — this is a docs/scripts repo. See docs/manual-testing.md."

typecheck:
	@echo "No type checker configured."

build:
	@echo "No build step — this is a docs/scripts repo."

# ── Clean ─────────────────────────────────────────────────────────────────────

clean:
	@echo "Nothing to clean."
