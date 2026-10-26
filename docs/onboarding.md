# Developer Onboarding

## Quick Start

### 1. Prerequisites
- [ ] Claude Code CLI installed (latest version)
- [ ] Git installed
- [ ] Python 3 installed (the hooks, the test suite, and `check-bilingual.py` use it; without it the commit gate lets commits through with a warning)
- [ ] Repository access granted

### 2. Setup

```bash
# Clone the repository
git clone https://github.com/whchoi98/project-init.git
cd project-init

# Run project setup
bash scripts/setup.sh

# Register this checkout as a marketplace and install the plugin (from the repository root)
claude plugin marketplace add "$PWD"
claude plugin install project-init@project-init
```

### 3. Verify

```bash
# Restart Claude Code session, then test
/health-check
```

## Project Overview
- Read `CLAUDE.md` for project context and conventions
- Read `docs/architecture.md` for system design
- Review `docs/decisions/` for architectural decisions

## Development Workflow
- Branch naming: `feat/`, `fix/`, `docs/`, `refactor/`
- Commit convention: Conventional Commits
- PR process: Create PR from feature branch to `main`
- Tests: `bash tests/run-all.sh`, or `bash tests/run-all.sh <filter>` to run only the test files whose basename contains the filter (`hooks`, `secret`, `structure` for `test-plugin-structure.sh` only, `reference`, `harness`, `bilingual`, `prompt`). In Claude Code sessions in this repo, a Stop hook (`.claude/hooks/test-gate.sh`) runs the suite when Claude ends a turn on a tree that changed since the gate's last run, and sends any failures back to Claude; an unchanged tree is not run again

## Key Concepts

### Plugin Structure
- Commands live in `plugins/project-init/commands/` as Markdown files
- Skills live in `plugins/project-init/skills/` with `SKILL.md` and `references/`
- Agents live in `plugins/project-init/agents/` as Markdown files
- Deterministic checks live in `plugins/project-init/scripts/`: `harness-check.sh` (harness score and hook-contract checks for a project) and `check-bilingual.py` (bilingual document structure). Commands reference them as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>`
- Plugin manifest: `plugins/project-init/.claude-plugin/plugin.json`
- Rules for writing commands, agents, and templates: `plugins/project-init/CLAUDE.md`

### Reference Templates
All generated files are based on templates in `plugins/project-init/skills/project-scaffolder/references/`:
- `claude-md-template.md` - Root and module CLAUDE.md structure
- `settings-json-template.md` - Permissions and hook registration
- `hook-scripts.md` - Hook script sources
- `skills-templates.md` - Skill and command definitions
- `agents-templates.md` - Agent definitions
- `docs-templates.md` - Documentation templates
- `scripts-templates.md` - Setup and Git hook install scripts
- `mcp-json-template.md` - MCP server configuration
- `tests-templates.md` - Test framework templates
- `readme-template.md` - Bilingual README.md generation rules
- `changelog-template.md` - Bilingual CHANGELOG.md generation rules
- `reference-doc-template.md` - Implementation reference doc skeletons for the 8 layers under `docs/reference/`
- `writing-style-guide.md` - Shared bilingual and style rules for every generated document (ADR-003)

### 4-Layer Auto-Sync
1. **CLAUDE.md Auto-Sync Rules** - Claude applies them in the same change that triggers them (after Plan mode exit or a code change); no hook enforces them
2. **PostToolUse Hook** - Write/Edit triggers missing doc detection
3. **/sync-docs Command** - Manual full documentation sync
4. **commit-msg Hook** - Auto-removes Co-Authored-By lines

## Troubleshooting

### Plugin not loading after install
Restart your Claude Code session. Plugins are loaded at session start.

### Hook scripts not running
Hooks run through `bash`, so the executable bit is not the cause. Run the harness check and read the `hook-*` lines, especially `hook-reg-*` (registration), `hook-python3`, and `hook-disable-all`:
```bash
bash plugins/project-init/scripts/harness-check.sh .
```

### Commands not appearing
Verify the plugin is installed:
```bash
claude plugin list
```

## Resources
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Plugin System Guide](https://docs.anthropic.com/en/docs/claude-code/plugins)
