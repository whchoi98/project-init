# Tests Module

## Role
Automated harness engineering validation. Tests hook scripts, secret scan patterns, plugin structure integrity, version consistency, CLAUDE.md content, and the rules that several plugin prompts must state alike.

## Key Files
- `run-all.sh` - Test runner with TAP-style output, color, and assertion functions
- `hooks/test-hooks.sh` - Hook existence, permissions, registration contract, and the behavior of every hook and `scripts/install-hooks.sh` in throwaway git repos, plus the `PATTERNS`/`SECRET_RES` cross-check
- `hooks/test-secret-patterns.sh` - Secret detection true/false positive tests against the hook's own `PATTERNS`
- `structure/test-plugin-structure.sh` - Manifests, version sync (manifests, README, CHANGELOG), file existence, and repo files that must equal their template copy (`tpl_sync`)
- `structure/test-reference-docs.sh` - Reference-doc template skeletons (8 layers), INDEX/Code Pointer validation, sync-docs reference logic
- `structure/test-harness-check.sh` - `harness-check.sh` output contract and exit codes on mktemp fixture projects, and the extracted hook and settings templates
- `structure/test-bilingual-docs.sh` - `check-bilingual.py` rule fixtures, then the repo's bilingual docs
- `structure/test-prompt-contracts.sh` - Rules that one plugin file states and others must not contradict
- `fixtures/harness-check/` - Hook and settings sets per plugin version, copied into mktemp projects
- `fixtures/bilingual/` - `good*` and `changelog-good*` pass; every other file breaks exactly one checker rule
- `fixtures/secret-samples.txt` - True positive samples (some tokens runtime-constructed)
- `fixtures/false-positives.txt` - False positive samples (must not trigger)

## Rules
- Test files are named `test-*.sh` and sourced (not subprocessed) by `run-all.sh` under `set -euo pipefail`, so guard every command that may fail (`|| true`, or `( ... ) && echo 0 || echo $?` for an expected exit code)
- Give a variable to a reader that can stop early (`grep -q`, `awk '... exit'`, `head`) as a here-string (`grep -q x <<< "$VAR"`), or read it all (`sed -n 1p`), never through `printf ... |`: under pipefail the writer's SIGPIPE fails the pipeline at random and aborts the run
- Variables and functions persist between test files; prefix them per file (`HK_`/`hk_`, `SP_`/`sp_`) to avoid collisions
- Pass `CLAUDE_PROJECT_DIR` explicitly when a test points a hook at a fixture tree, because hooks resolve the root from it and the Stop gate runs this suite with it set
- Generate fixture projects that contain `test-*.sh` or `CLAUDE.md` files in mktemp at test time, because `run-all.sh` sources every `tests/**/test-*.sh`
- Tests of `test-gate.sh` set `TEST_GATE_CMD`, so the gate never runs the suite from inside it, and `TMPDIR`, so a real session's fingerprint cache cannot turn a run into a skip
- The secret patterns live only in the `PATTERNS` array of `.claude/hooks/secret-scan.sh`, which `test-secret-patterns.sh` reads; change the template copy in `hook-scripts.md` with it (`tpl_sync`). A new pattern needs a true-positive sample. `harness-check.sh` keeps its own `SECRET_RES` list: a new entry needs a runtime-built sample in `HK_TOKENS` in `test-hooks.sh`, and the `SECRET_RES=` block must end at a blank line, where the cross-check stops reading
- Build secret-shaped tokens at runtime by string concatenation, because GitHub Push Protection rejects literal ones and the commit gate scans every test file except `test-secret-patterns.sh` and the two sample files above
- Use `grep -F` (fixed string) for CLAUDE.md content assertions to avoid shell variable issues
