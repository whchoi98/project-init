# Plugins Directory

## Role
Contains all Claude Code plugins distributed through this marketplace. Each subdirectory is a self-contained plugin with its own manifest, commands, skills, and agents.

## Key Files
- `project-init/` - Main plugin for project initialization and doc management

## Rules
- Each plugin must have `.claude-plugin/plugin.json` manifest
- Commands are Markdown files in `commands/`
- Skills have `SKILL.md` plus optional `references/` directory
- Agents are Markdown files with YAML frontmatter in `agents/` (`.yml` is not loaded)
- Plugin versions must match between `plugin.json` and root `marketplace.json`
