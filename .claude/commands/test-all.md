---
description: Run the full test suite and validate plugin structure
allowed-tools: Read, Bash(bash tests/*), Bash(bash -n:*), Bash(find:*), Bash(python3 -m json.tool:*), Bash(chmod:*), Bash(ls:*), Glob, Grep
---

# Test All

Run the automated test suite and validate plugin health.

## Step 1: Run Test Suite

Execute the harness test suite:

```bash
bash tests/run-all.sh
```

This runs 113 tests across 3 categories:
- **Hook tests** (27): Syntax, permissions, registration, behavior
- **Secret pattern tests** (22): True positive detection, false positive rejection
- **Structure tests** (64): Manifests, version sync, file existence, CLAUDE.md content

## Step 2: Analyze Results

If tests fail:
- Read the failure messages for exact file paths and expected values
- Hook failures: Check `.claude/hooks/*.sh` syntax and permissions
- Pattern failures: Check regex in `secret-scan.sh` against test fixtures in `tests/fixtures/`
- Structure failures: Check file existence and JSON validity

## Step 3: Run Targeted Tests (if needed)

```bash
# Run only specific test category
bash tests/run-all.sh hooks        # Hook tests only
bash tests/run-all.sh secret       # Secret pattern tests only
bash tests/run-all.sh structure    # Structure tests only
```

## Step 4: Report

Present:
- Total tests run, passed, failed, skipped
- Failed test details with file paths and fix suggestions
- If all pass, confirm project health is verified

## Error Recovery

### If test runner itself fails
```bash
# Check bash syntax of test runner
bash -n tests/run-all.sh

# Check if test files are executable
ls -la tests/hooks/test-*.sh tests/structure/test-*.sh

# Fix permissions if needed
chmod +x tests/**/*.sh
```

### Common failure categories and fixes

| Failure Pattern | Likely Cause | Fix |
|---|---|---|
| "file not found" | Missing file after restructure | Create the file or update the test |
| "invalid JSON" | Malformed manifest | `python3 -m json.tool <file>` to find syntax error |
| "Version mismatch" | marketplace.json ≠ plugin.json | Update both to same version |
| "not executable" | Permission reset by git | `chmod +x .claude/hooks/*.sh scripts/*.sh` |
| "bash syntax error" | Bad edit in hook script | `bash -n <file>` to locate error line |
| "pattern did not match" | Regex changed in secret-scan.sh | Update test patterns to match or fix the regex |

### If many tests fail at once
Likely a structural change broke multiple assumptions. Check:
1. `git log -1` — what was the last change?
2. `git diff HEAD~1` — what specifically changed?
3. Fix the root cause, not individual tests
