---
description: Run the test suite, fix failures at their cause, and report
allowed-tools: Read, Edit, Glob, Grep, Bash(bash tests/*), Bash(bash -n *)
---

# Test All

Run `bash tests/run-all.sh`, or `bash tests/run-all.sh <filter>` for the test files whose name matches (filters: `CLAUDE.md` `## Key Commands`).

The runner repeats every failing assertion, with expected and actual values, under `=== Failures ===`. Fix the cause, not the assertion, unless the assertion encodes a stale count or path. Re-run until the suite is green or the remaining failures need the user's decision, such as a test that asserts behavior the change removes on purpose.

Report the totals, each change you made (file and a one-line reason), and each remaining failure with why you left it.
