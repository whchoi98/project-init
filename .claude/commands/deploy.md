---
description: Release the plugin (version bump, changelog, tag, push)
disable-model-invocation: true
allowed-tools: Read, Edit, Glob, Grep, Bash(git status:*), Bash(git branch:*), Bash(git pull:*), Bash(git log:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git tag:*), Bash(git push:*), Bash(python3:*), Bash(bash tests/run-all.sh:*)
---

# Deploy

Follow `docs/runbooks/release.md`; it is the single source of truth for releasing.

Before tagging, confirm all of the following and stop if any fails:

- `bash tests/run-all.sh` passes on a clean, up-to-date `main`
- `plugin.json` carries the new version, and `CHANGELOG.md` has its `## [X.Y.Z] - YYYY-MM-DD` entry with `[Unreleased]` empty in both language sections (the tests check that the files agree, not the bump)

After pushing, print the consumer update commands from `docs/runbooks/update-from-marketplace.md`.
