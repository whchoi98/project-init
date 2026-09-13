---
description: Run the full test suite and report failures
allowed-tools: Read, Glob, Grep, Bash(bash tests/*), Bash(bash -n:*)
---

# Test All

Run `bash tests/run-all.sh`, or `bash tests/run-all.sh <hooks|secret|structure|reference>` for one category.

The runner prints every failing assertion with expected and actual values. Fix the root cause rather than the assertion, unless the assertion encodes a stale count or path. Re-run, then report totals and any remaining failures.
