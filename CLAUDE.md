# Project Context

## Overview
**project-init** is a Claude Code plugin marketplace that provides project structure initialization, documentation quality scoring, and auto-sync workflows. The main plugin lives in `plugins/project-init/`.

## Tech Stack
- Claude Code Plugin System (commands, skills, agents as Markdown/YAML)
- Bash (hook scripts, setup scripts)
- Git (version control, commit-msg hooks)
- Markdown (all plugin definitions, documentation, templates)

## Project Structure
```
plugins/project-init/     - Main plugin source
  .claude-plugin/         - Plugin manifest (plugin.json)
  commands/               - Slash commands (init-project, sync-docs, generate-readme, etc.)
  agents/                 - Agent definitions (doc-sync-checker)
  skills/project-scaffolder/ - Scaffolding skill with reference templates
.claude/                  - Claude Code settings and project hooks
  hooks/                  - PostToolUse, PreToolUse, SessionStart, Notification hooks
  skills/                 - Project-level skills (code-review, refactor, release, sync-docs)
  commands/               - Project-level slash commands (review, test-all, deploy)
  agents/                 - Project-level agents (code-reviewer, security-auditor)
docs/                     - Architecture docs, ADRs, runbooks
  decisions/              - Architecture Decision Records
  runbooks/               - Operational runbooks
tests/                    - Automated test suite (hooks, secret patterns, structure)
scripts/                  - Setup and deployment scripts
.claude-plugin/           - Marketplace manifest (marketplace.json)
img/                      - Images and assets
.github/                  - GitHub issue/PR templates
```

## Conventions
- **Language**: Bilingual (Korean/English) for all user-facing docs (README, CHANGELOG, architecture, ADR, runbook); see `writing-style-guide.md`
- **Plugin structure**: Commands are `.md` files with frontmatter; agents are `.md` or `.yml`
- **Reference templates**: Stored in `skills/project-scaffolder/references/` as Markdown with embedded code blocks
- **Versioning**: Semantic versioning; version tracked in `marketplace.json` and `plugin.json`
- **Commit messages**: Co-Authored-By lines auto-removed by commit-msg hook
- **Indentation**: 2 spaces (see `.editorconfig`)
- **Line endings**: LF

## Key Commands
```bash
# Tests
bash tests/run-all.sh              # Run full test suite (114 tests)
bash tests/run-all.sh hooks        # Run only hook tests
bash tests/run-all.sh secret       # Run only secret pattern tests
bash tests/run-all.sh structure    # Run only structure tests

# Plugin management
claude plugin marketplace add ./project-init
claude plugin install project-init

# Plugin commands (run inside Claude Code)
/init-project          # Initialize project structure
/sync-docs             # Synchronize documentation
/generate-readme       # Generate bilingual README.md
/generate-changelog    # Generate bilingual CHANGELOG.md
/add-adr               # Create Architecture Decision Record
/add-module            # Add new module with CLAUDE.md
/add-runbook           # Create operational runbook
/health-check          # Validate project setup

# Scripts
bash scripts/setup.sh           # Project setup for new developers
bash scripts/install-hooks.sh   # Install Git hooks
```

---

## Auto-Sync Rules

Rules below are applied automatically after Plan mode exit and on major code changes.

### Post-Plan Mode Actions
After exiting Plan mode (`/plan`), before starting implementation:

1. **Architecture decision made** -> Update `docs/architecture.md`
2. **Technical choice/trade-off made** -> Create `docs/decisions/ADR-NNN-title.md`
3. **New module added** -> Create `CLAUDE.md` in that module directory
4. **Operational procedure defined** -> Create runbook in `docs/runbooks/`
5. **Changes needed in this file** -> Update relevant sections above

### Code Change Sync Rules
- New directory under `plugins/` -> Must create `CLAUDE.md` alongside
- Plugin command added/changed -> Update `plugins/project-init/CLAUDE.md`
- Reference template changed -> Update relevant command documentation
- Hook script changed -> Update `docs/architecture.md` Hooks section

### ADR Numbering
Find the highest number in `docs/decisions/ADR-*.md` and increment by 1.
Format: `ADR-NNN-concise-title.md`

### Current ADRs
- [ADR-001](docs/decisions/ADR-001-bilingual-documentation-policy.md) -- Bilingual documentation policy (Korean/English, English first, identical structure)
- [ADR-002](docs/decisions/ADR-002-html-anchor-navigation.md) -- HTML `<a><img></a>` badges with ASCII-only anchor IDs (`#english`, `#korean`)
- [ADR-003](docs/decisions/ADR-003-shared-writing-style-guide.md) -- Shared writing-style-guide as the single source of truth for all five document-generating commands
- [ADR-004](docs/decisions/ADR-004-hook-non-blocking-failure.md) -- Hook non-blocking failure policy: gate hooks exit non-zero, observational hooks suppress via `2>/dev/null \|\| true` at the registration boundary
- [ADR-005](docs/decisions/ADR-005-implementation-reference-docs.md) -- Implementation reference docs structure (8 layers, shared 5-section skeleton, AUTO-MANAGED INDEX)
- [ADR-006](docs/decisions/ADR-006-hybrid-detection-confirmation.md) -- Hybrid detection + user confirmation flow for /init-project Step 4.5

### Current Runbooks
- [release.md](docs/runbooks/release.md) -- Maintainer-side procedure to release a new plugin version with atomic version bump in both manifests
- [update-from-marketplace.md](docs/runbooks/update-from-marketplace.md) -- Consumer-side procedure to update or remove the installed plugin
