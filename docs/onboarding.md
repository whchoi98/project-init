# Developer Onboarding

## Quick Start

### 1. Prerequisites
- [ ] Claude Code CLI installed (latest version)
- [ ] Git installed
- [ ] Repository access granted

### 2. Setup

```bash
# Clone the repository
git clone https://github.com/whchoi98/project-init.git
cd project-init

# Run project setup
bash scripts/setup.sh

# Register the marketplace and install plugin
claude plugin marketplace add ./project-init
claude plugin install project-init
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

## Key Concepts

### Plugin Structure
- Commands live in `plugins/project-init/commands/` as Markdown files
- Skills live in `plugins/project-init/skills/` with `SKILL.md` and `references/`
- Agents live in `plugins/project-init/agents/` as Markdown files
- Plugin manifest: `plugins/project-init/.claude-plugin/plugin.json`

### Reference Templates
All generated files are based on templates in `plugins/project-init/skills/project-scaffolder/references/`:
- `claude-md-template.md` - CLAUDE.md structure
- `settings-json-template.md` - Hook configuration
- `hook-scripts.md` - All hook script sources
- `skills-templates.md` - Skill and command definitions
- `agents-templates.md` - Agent definitions
- `docs-templates.md` - Documentation templates
- `scripts-templates.md` - Setup and deploy scripts
- `mcp-json-template.md` - MCP server configuration
- `tests-templates.md` - Test framework templates
- `readme-template.md` - Bilingual README.md generation rules
- `changelog-template.md` - Bilingual CHANGELOG.md generation rules

### 4-Layer Auto-Sync
1. **CLAUDE.md Auto-Sync Rules** - Plan mode exit triggers doc updates
2. **PostToolUse Hook** - Write/Edit triggers missing doc detection
3. **/sync-docs Command** - Manual full documentation sync
4. **commit-msg Hook** - Auto-removes Co-Authored-By lines

## Troubleshooting

### Plugin not loading after install
Restart your Claude Code session. Plugins are loaded at session start.

### Hook scripts not running
Check that hook scripts are executable:
```bash
chmod +x .claude/hooks/*.sh
```

### Commands not appearing
Verify the plugin is installed:
```bash
claude plugin list
```

## Resources
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Plugin System Guide](https://docs.anthropic.com/en/docs/claude-code/plugins)
