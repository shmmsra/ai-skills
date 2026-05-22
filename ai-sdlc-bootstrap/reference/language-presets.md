# Language Presets

Per-language detection + recommended `make check` body + starter-test guidance.

## TypeScript / Node

**Detection**: `package.json` exists and `tsconfig.json` exists, or `package.json` has a `typescript` dep.

**Default test framework**: Vitest (preferred) > Jest > Mocha. Use whichever is already in `devDependencies`. If none, default to Vitest.

**Recommended `make check` body**:
```makefile
check: typecheck test-ts

typecheck:
	npm run typecheck       # tsc --noEmit, configured in package.json

test-ts:
	npm test                # vitest run / jest
```

**Starter failing test (Vitest)** — write to `src/__tests__/scaffold.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';

describe('scaffold', () => {
  it('reminds you to delete this test once the first real one exists', () => {
    // Deliberately failing. Replace with a real test before committing.
    expect(true).toBe(false);
  });
});
```

## Python

**Detection**: `pyproject.toml`, `setup.py`, `requirements.txt`, or `*.py` files in the root.

**Default test framework**: pytest. Default type checker: mypy if `mypy` in deps, else ruff in type-check mode, else skip.

**Recommended `make check` body**:
```makefile
check: lint test-py

lint:
	ruff check .

test-py:
	pytest
```

**Add `typecheck` if mypy is present**:
```makefile
check: lint typecheck test-py

typecheck:
	mypy src/
```

**Starter failing test** — `tests/test_scaffold.py`:
```python
def test_scaffold_reminder():
    """Replace with a real test before committing."""
    assert False, "Delete this and write your first real test"
```

## Go

**Detection**: `go.mod` exists.

**Default test framework**: built-in `go test`. No extra config needed.

**Recommended `make check` body**:
```makefile
check: vet test-go

vet:
	go vet ./...

test-go:
	go test ./...
```

**Starter failing test** — `scaffold_test.go`:
```go
package main

import "testing"

func TestScaffoldReminder(t *testing.T) {
	t.Fatal("Delete this and write your first real test")
}
```

## Rust

**Detection**: `Cargo.toml` exists.

**Default test framework**: built-in `cargo test`.

**Recommended `make check` body**:
```makefile
check: fmt-check clippy test-rs

fmt-check:
	cargo fmt --check

clippy:
	cargo clippy -- -D warnings

test-rs:
	cargo test
```

**Starter failing test** — append to `src/lib.rs` or create `tests/scaffold.rs`:
```rust
#[test]
fn scaffold_reminder() {
    panic!("Delete this and write your first real test");
}
```

## C++

**Detection**: `CMakeLists.txt` exists.

**Default test framework**: Catch2 (lightweight, header-only via FetchContent). Alternative: GoogleTest.

**Recommended `make check` body**:
```makefile
check: build-cpp test-cpp

build-cpp:
	cmake -B build
	cmake --build build --parallel

test-cpp: build-cpp
	ctest --test-dir build --output-on-failure
```

**Starter failing test** — `tests/test_scaffold.cpp` (Catch2):
```cpp
#include <catch2/catch_test_macros.hpp>

TEST_CASE("scaffold reminder", "[scaffold]") {
    FAIL("Delete this and write your first real test");
}
```

## Java / Kotlin

**Detection**: `pom.xml` (Maven) or `build.gradle{,.kts}` (Gradle).

**Default test framework**: JUnit 5.

**Recommended `make check` body** (Gradle example):
```makefile
check:
	./gradlew check
```

(Gradle's `check` task already runs tests + linting; no need to reinvent.)

**Maven equivalent**:
```makefile
check:
	mvn verify
```

## Polyglot projects

If multiple languages are detected (e.g. TS + C++, or Python + Rust), the `make check` body chains all of them. Example for a TS frontend + C++ backend in subdirectories:

```makefile
check: typecheck-ts test-ts build-cpp test-cpp

typecheck-ts:
	cd <ts-subdir> && npm run typecheck

test-ts:
	cd <ts-subdir> && npm test

build-cpp:
	cmake -B <cpp-subdir>/build <cpp-subdir>
	cmake --build <cpp-subdir>/build --parallel

test-cpp: build-cpp
	ctest --test-dir <cpp-subdir>/build --output-on-failure
```

Ask the user for the directory layout — is it monorepo-style with sub-projects, or top-level mixed?

## Generic / unknown

If detection fails, ask the user. Don't guess. *"I couldn't determine the primary language. What's the canonical command to run all tests in this repo?"*

Use whatever they say as `{{TEST_COMMAND}}` and write the simplest possible Makefile:

```makefile
check:
	{{TEST_COMMAND}}
```

The point of the gate is enforcement, not language elegance. A one-line check command is fine.

## CI workflow mapping

Whatever `make check` does, the GitHub Actions workflow runs the same thing on Linux. Don't drift the two — CI failures that pass locally erode the gate's authority.

```yaml
- name: Check
  run: make check
```

That's it. No duplicated test invocations in CI.
