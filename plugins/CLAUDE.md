# Plugins Directory

## Role
Contains all Claude Code plugins distributed through this marketplace. Each subdirectory is a self-contained plugin with its own manifest, commands, skills, agents, and optional bundled scripts.

## Key Files
- `project-init/` - Main plugin for project initialization and doc management

## Rules
- Each plugin must have `.claude-plugin/plugin.json` manifest
- Each plugin keeps one `CLAUDE.md` at its root (role, key files, rules); subdirectories such as `commands/`, `agents/`, or `scripts/` do not get their own, and the plugin CLAUDE.md lists their key files
- Commands are Markdown files in `commands/`
- Skills have `SKILL.md` plus optional `references/` directory
- Agents are Markdown files with YAML frontmatter in `agents/` (`.yml` is not loaded)
- Bundled scripts live in `scripts/`; commands reference them as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>` because relative paths do not resolve in a consumer project
- Plugin versions must match between `plugin.json` and root `marketplace.json`
