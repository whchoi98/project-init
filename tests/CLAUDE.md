# Tests Module

## Role
Automated harness engineering validation. Tests hook scripts, secret scan patterns, plugin structure integrity, version consistency, and CLAUDE.md content.

## Key Files
- `run-all.sh` - Test runner with TAP-style output, color, and assertion functions
- `hooks/test-hooks.sh` - Hook existence, permissions, registration, behavior
- `hooks/test-secret-patterns.sh` - Secret detection true/false positive tests
- `structure/test-plugin-structure.sh` - Manifest, version sync, file existence
- `structure/test-reference-docs.sh` - Reference-doc template skeletons (8 layers), INDEX/Code Pointer validation, sync-docs reference logic
- `fixtures/secret-samples.txt` - True positive samples (some tokens runtime-constructed)
- `fixtures/false-positives.txt` - False positive samples (must not trigger)

## Rules
- Test files are named `test-*.sh` and sourced (not subprocessed) by `run-all.sh`
- Variables persist between test files — avoid name collisions
- Sensitive tokens must be runtime-constructed via string concatenation to avoid GitHub Push Protection
- Use `grep -F` (fixed string) for CLAUDE.md content assertions to avoid shell variable issues
- Run `bash tests/run-all.sh` to execute the full suite; the runner prints the live total, so do not hardcode test counts in docs
