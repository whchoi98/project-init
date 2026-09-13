---
description: Release the plugin (version bump, changelog, tag, push)
allowed-tools: Read, Edit, Glob, Grep, Bash(git status:*), Bash(git branch:*), Bash(git pull:*), Bash(git log:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git tag:*), Bash(git push:*), Bash(python3:*), Bash(bash tests/run-all.sh:*)
---

# Deploy

Follow `docs/runbooks/release.md`; it is the single source of truth for releasing.

Before tagging, confirm all of the following and stop if any fails:

- `bash tests/run-all.sh` passes on a clean, up-to-date `main`
- `marketplace.json` (`metadata.version` and `plugins[0].version`) and `plugin.json` carry the same new version
- `CHANGELOG.md` has a `## [X.Y.Z] - YYYY-MM-DD` entry in both language sections and `[Unreleased]` is empty

After pushing, print the consumer update commands from `docs/runbooks/update-from-marketplace.md`.
