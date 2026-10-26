---
description: Review current changes against this repo's conventions
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *), Bash(git status *), Bash(bash -n *), Bash(bash tests/run-all.sh *), Bash(python3 plugins/project-init/scripts/check-bilingual.py *)
---

# Code Review

Review `$ARGUMENTS` if given; otherwise `git diff HEAD` plus the untracked files that `git status --porcelain` lists, since a diff leaves out new files.

Run `bash tests/run-all.sh` first and put its failures in the report as they are. It already checks version sync, bash syntax, the hook contract and registration, the reference-doc skeletons, harness-check.sh, and the structure of the repo's bilingual docs. For a changed bilingual doc outside the suite, run `python3 plugins/project-init/scripts/check-bilingual.py <file>`.

Spend the review on what those checks cannot see:

- Translation fidelity: each Korean paragraph says what its English counterpart says, with matching technical terms (ADR-001)
- Hardcoded counts (tests, files, commands, steps) in CLAUDE.md, README, CHANGELOG, or command docs: removed, or correct (ADR-008)
- New hooks the suite does not exercise yet: they follow the contract and registration form in `CLAUDE.md` `## Conventions`
- Contract changes: a changed hook, script CLI, command interface, heading, generated path, or reference template is updated everywhere that consumes it (grep the name under `plugins/project-init/`, `tests/`, and `docs/`)
- Prompt changes under `plugins/`: they follow `plugins/project-init/CLAUDE.md` `## Rules`
- The `CLAUDE.md` `## Auto-Sync Rules` were applied in the same change

Report every issue you find, most severe first, one per line:

```text
[high|medium|low] [confirmed|suspected] file:line - problem. Fix: concrete change.
```

Mark an issue confirmed when you ran it or traced the code, suspected otherwise. If you find none, say so in one line.
