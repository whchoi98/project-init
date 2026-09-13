---
description: Review current changes against this repo's conventions
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git log:*), Bash(bash -n:*), Bash(bash tests/run-all.sh:*)
---

# Code Review

Review `$ARGUMENTS` if given; otherwise `git diff`, falling back to `git diff --cached`.

Focus on what a generic review misses in this repo:

- Bilingual docs: English and Korean sections have identical structure, code blocks, and tables (ADR-001); language toggles use `#english` / `#korean` anchors (ADR-002)
- Version consistency: `marketplace.json` (`metadata.version` and `plugins[0].version`) matches `plugin.json`
- Hardcoded counts (test totals, file counts) in CLAUDE.md, README, or CHANGELOG match reality, or were removed
- Hooks read their JSON input from stdin and block with exit 2 (ADR-008); registration follows ADR-004
- A changed reference template is reflected in the command that consumes it
- Shell scripts pass `bash -n`; `bash tests/run-all.sh` passes

Report only issues you are confident are real, each with `file:line` and a concrete fix. If nothing qualifies, say so in one line.
