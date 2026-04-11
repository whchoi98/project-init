# Tests Module

## Role
Automated harness engineering validation. Tests hook scripts, secret scan patterns, plugin structure integrity, version consistency, and CLAUDE.md content.

## Key Files
- `run-all.sh` - Test runner with TAP-style output, color, and assertion functions
- `hooks/test-hooks.sh` - Hook existence, permissions, registration, behavior (27 tests)
- `hooks/test-secret-patterns.sh` - Secret detection true/false positive tests (22 tests)
- `structure/test-plugin-structure.sh` - Manifest, version sync, file existence (65 tests)
- `fixtures/secret-samples.txt` - True positive samples (some tokens runtime-constructed)
- `fixtures/false-positives.txt` - False positive samples (must not trigger)

## Rules
- Test files are named `test-*.sh` and sourced (not subprocessed) by `run-all.sh`
- Variables persist between test files — avoid name collisions
- Sensitive tokens must be runtime-constructed via string concatenation to avoid GitHub Push Protection
- Use `grep -F` (fixed string) for CLAUDE.md content assertions to avoid shell variable issues
- Run `bash tests/run-all.sh` to execute all 114 tests
