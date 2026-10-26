# Project Context

## Overview
**project-init** is a Claude Code plugin marketplace that provides project structure initialization, documentation quality scoring, and auto-sync workflows. The main plugin lives in `plugins/project-init/`.

## Tech Stack
- Claude Code Plugin System (commands, skills, agents as Markdown with YAML frontmatter)
- Bash (hook scripts, setup scripts, `harness-check.sh`)
- Python 3, standard library only (`check-bilingual.py`, secret-scan pattern matching)
- Git (version control, commit-msg hooks)
- Markdown (all plugin definitions, documentation, templates)

## Project Structure
```text
plugins/project-init/     - Main plugin source
  .claude-plugin/         - Plugin manifest (plugin.json)
  commands/               - Slash commands (init-project, sync-docs, generate-readme, etc.)
  agents/                 - Agent definitions (doc-sync-checker)
  scripts/                - Bundled checks (harness-check.sh, check-bilingual.py)
  skills/project-scaffolder/ - Scaffolding skill with reference templates
.claude/                  - Claude Code settings and project hooks
  hooks/                  - SessionStart (context), PreToolUse (secret gate on git commit), PostToolUse (module CLAUDE.md reminder), Stop (test gate)
  commands/               - Project-level slash commands (review, test-all, deploy)
docs/                     - Architecture, onboarding, ADRs (decisions/), runbooks (runbooks/)
tests/                    - Automated test suite (hooks, structure, fixtures)
scripts/                  - Setup and Git hook install scripts
.claude-plugin/           - Marketplace manifest (marketplace.json)
```

## Conventions
- **Language**: Bilingual (Korean/English) for user-facing docs (README, CHANGELOG, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, architecture, ADR, runbook; `docs/onboarding.md` is English-only); see `writing-style-guide.md` in the reference templates. `check-bilingual.py` checks structure, not translation
- **Plugin structure**: Commands and agents are `.md` files with YAML frontmatter (Claude Code does not load `.yml` agents). Rules for writing plugin prompts: `plugins/project-init/CLAUDE.md` `## Rules`
- **Reference templates**: Markdown in `plugins/project-init/skills/project-scaffolder/references/`, with code in fenced blocks that /init-project and the tests extract by heading
- **Versioning**: Semantic versioning; a bump follows `docs/runbooks/release.md`, which lists every file that carries the version
- **Commit messages**: Co-Authored-By lines auto-removed by commit-msg hook
- **Hooks**: read the event JSON from stdin only when `$# -eq 0` (tests pass `$1`; a blocking read hangs the runner), block with exit 2 (any other exit lets the action through), and resolve the root as `${CLAUDE_PROJECT_DIR:-$PWD}`. Register them as `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh`, since a relative path fails once Claude `cd`s: gates with nothing after `.sh`, observational hooks with `2>/dev/null || true`. A hook that acts on the working tree uses the event's `cwd` when it is in this repository (ADR-009 decision 9)
- **Test gate**: a Stop hook runs `bash tests/run-all.sh` on a changed tree and blocks on failure; fix the cause, or tell the user in one line why the suite should stay red
- **Counts**: no hardcoded counts of tests, files, steps, or commands in docs or prompts, because they drift (ADR-008); structural constants that are the contract (8 reference layers, 6 CLAUDE.md criteria, 100-point scale) are fine
- **Indentation**: 2 spaces; 4 for shell and Python (`.editorconfig`)
- **Line endings**: LF

## Key Commands
```bash
# Tests
bash tests/run-all.sh              # Run full test suite
bash tests/run-all.sh <filter>     # Test files whose basename matches: hooks, secret, structure, reference, harness, bilingual, prompt

# Bundled checks (the plugin commands run these in consumer projects)
bash plugins/project-init/scripts/harness-check.sh [--contract-only] [PROJECT_DIR]
python3 plugins/project-init/scripts/check-bilingual.py FILE...

# Plugin management (from the repository root)
claude plugin marketplace add "$PWD"
claude plugin install project-init@project-init

# Plugin commands: see plugins/project-init/CLAUDE.md

# Scripts
bash scripts/setup.sh           # Project setup for new developers
bash scripts/install-hooks.sh   # Install Git hooks
```

---

## Auto-Sync Rules

Nothing runs these automatically; apply them in the same change that triggers them.

### Post-Plan Mode Actions
After exiting Plan mode (`/plan`), before starting implementation:

1. **Architecture decision made** -> Update `docs/architecture.md` (both languages)
2. **Contract changed** (hook contract, manifest schema, command interface, script CLI, generated file layout) **or an earlier ADR reversed** -> New ADR in `docs/decisions/`; amend the superseded ADR's Status line to point to it. Routine choices need no ADR
3. **Operational procedure defined** -> Create runbook in `docs/runbooks/`

### Code Change Sync Rules
- New plugin under `plugins/` -> one `CLAUDE.md` at its root, none in its subdirectories (`plugins/CLAUDE.md`)
- Plugin command, agent, or bundled script added/changed -> Update `plugins/project-init/CLAUDE.md`
- Reference template changed -> Update every command or agent that reads it (grep the template filename under `plugins/project-init/`)
- Hook script changed -> Update the `.claude/hooks/` bullet under `## Components` in `docs/architecture.md` (both languages)

### ADR Numbering
Find the highest number in `docs/decisions/ADR-*.md` and increment by 1.
Format: `ADR-NNN-concise-title.md`

### Current ADRs
- [ADR-001](docs/decisions/ADR-001-bilingual-documentation-policy.md) -- Bilingual documentation policy (Korean/English, English first, identical structure)
- [ADR-002](docs/decisions/ADR-002-html-anchor-navigation.md) -- HTML `<a><img></a>` badges with ASCII-only anchor IDs (`#english`, `#korean`)
- [ADR-003](docs/decisions/ADR-003-shared-writing-style-guide.md) -- Shared writing-style-guide as the single source of truth for the document-generating commands
- [ADR-004](docs/decisions/ADR-004-hook-non-blocking-failure.md) -- Hook failure policy: gates block with exit 2 and are registered without `|| true` (amended by ADR-008); observational hooks end with `2>/dev/null || true`
- [ADR-005](docs/decisions/ADR-005-implementation-reference-docs.md) -- Implementation reference docs structure (8 layers, shared 5-section skeleton, AUTO-MANAGED INDEX)
- [ADR-006](docs/decisions/ADR-006-hybrid-detection-confirmation.md) -- Hybrid detection + user confirmation for the /init-project Implementation Reference Detection
- [ADR-007](docs/decisions/ADR-007-mermaid-architecture-diagrams.md) -- Mermaid flowchart replaces ASCII box diagrams for all architecture flows; README gains an Architecture section
- [ADR-008](docs/decisions/ADR-008-right-sized-harness.md) -- Right-sized harness: stdin JSON / exit 2 hook contract, dead or duplicated components removed, repo commands reduced to repo-specific checks (extended by ADR-009)
- [ADR-009](docs/decisions/ADR-009-opus-5-5-harness-alignment.md) -- Opus 5.5 harness alignment: tiered generation (Core/Default/Optional), model/effort policy, report-all reviewers, deterministic script checks, Stop test gate, commit-scope secret gate

### Current Runbooks
- [release.md](docs/runbooks/release.md) -- Maintainer-side release: version bump in every file that carries it, tag, clean-install check
- [update-from-marketplace.md](docs/runbooks/update-from-marketplace.md) -- Consumer-side procedure to update or remove the installed plugin
