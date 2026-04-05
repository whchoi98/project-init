---
description: Run the full test suite and validate plugin structure
allowed-tools: Read, Bash(bash tests/*), Bash(find:*), Bash(python3:*), Glob, Grep
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
