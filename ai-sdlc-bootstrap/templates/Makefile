.PHONY: check setup-hooks test typecheck lint build clean help

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo "Available targets:"
	@echo "  make check         Pre-commit gate: typecheck + lint + tests"
	@echo "  make setup-hooks   Install .git/hooks/pre-commit (run once after clone)"
	@echo "  make test          Run the test suite only"
	@echo "  make typecheck     Run the type checker only"
	@echo "  make lint          Run the linter only"
	@echo "  make build         Build the project"
	@echo "  make clean         Remove build artifacts"

# ── Pre-commit gate ──────────────────────────────────────────────────────────

# {{CHECK_TARGETS}} is filled in at scaffold time with the right language-specific chain.
# Examples:
#   TypeScript:   check: typecheck lint test
#   Python:       check: lint typecheck test
#   Go:           check: vet test
#   Rust:         check: fmt-check clippy test
#   C++:          check: build test
#   Polyglot:     check: typecheck-ts test-ts build-cpp test-cpp
check: {{CHECK_TARGETS}}

# ── Hook installation ─────────────────────────────────────────────────────────

setup-hooks:
	bash scripts/setup-hooks.sh

# ── Language-specific targets ─────────────────────────────────────────────────
#
# Replace the block below with the right invocations for this project.
# See reference/language-presets.md in the ai-sdlc-bootstrap skill for per-language snippets.

{{LANGUAGE_TARGETS_BLOCK}}

# ── Clean ─────────────────────────────────────────────────────────────────────

clean:
{{CLEAN_COMMANDS}}
