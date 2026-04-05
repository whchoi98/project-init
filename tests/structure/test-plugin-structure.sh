#!/bin/bash
# Tests for plugin structure, manifests, and file references

# --- Plugin manifests ---

assert_file_exists "marketplace.json exists" ".claude-plugin/marketplace.json"
assert_json_valid "marketplace.json is valid JSON" ".claude-plugin/marketplace.json"

assert_file_exists "plugin.json exists" "plugins/project-init/.claude-plugin/plugin.json"
assert_json_valid "plugin.json is valid JSON" "plugins/project-init/.claude-plugin/plugin.json"

# --- Version consistency ---

MARKETPLACE_VER=$(python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['metadata']['version'])" 2>/dev/null)
PLUGIN_VER=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)
assert_eq "Version sync: marketplace.json matches plugin.json" "$PLUGIN_VER" "$MARKETPLACE_VER"

# --- Plugin commands exist ---

COMMANDS=(init-project sync-docs add-adr add-module add-runbook health-check)
for cmd in "${COMMANDS[@]}"; do
    assert_file_exists "Plugin command: $cmd.md" "plugins/project-init/commands/$cmd.md"
done

# --- Plugin agents exist ---

assert_file_exists "Plugin agent: doc-sync-checker.md" "plugins/project-init/agents/doc-sync-checker.md"

# --- Plugin skill exists ---

assert_file_exists "Plugin skill: SKILL.md" "plugins/project-init/skills/project-scaffolder/SKILL.md"

# --- Reference templates exist ---

TEMPLATES=(claude-md-template docs-templates hook-scripts settings-json-template skills-templates agents-templates mcp-json-template scripts-templates)
for tmpl in "${TEMPLATES[@]}"; do
    assert_file_exists "Reference: $tmpl.md" "plugins/project-init/skills/project-scaffolder/references/$tmpl.md"
done

# --- Project-level skills exist ---

SKILLS=(code-review refactor release sync-docs)
for skill in "${SKILLS[@]}"; do
    assert_file_exists "Skill: $skill/SKILL.md" ".claude/skills/$skill/SKILL.md"
done

# --- Project-level commands exist ---

PROJECT_CMDS=(review test-all deploy)
for cmd in "${PROJECT_CMDS[@]}"; do
    assert_file_exists "Command: $cmd.md" ".claude/commands/$cmd.md"
done

# --- Project-level agents exist ---

assert_file_exists "Agent: code-reviewer.yml" ".claude/agents/code-reviewer.yml"
assert_file_exists "Agent: security-auditor.yml" ".claude/agents/security-auditor.yml"

# --- CLAUDE.md files exist ---

assert_file_exists "Root CLAUDE.md" "CLAUDE.md"
assert_file_exists "plugins/CLAUDE.md" "plugins/CLAUDE.md"
assert_file_exists "plugins/project-init/CLAUDE.md" "plugins/project-init/CLAUDE.md"

# --- Documentation exists ---

assert_file_exists "docs/architecture.md" "docs/architecture.md"
assert_file_exists "docs/onboarding.md" "docs/onboarding.md"
assert_file_exists "docs/decisions/.template.md" "docs/decisions/.template.md"
assert_file_exists "docs/runbooks/.template.md" "docs/runbooks/.template.md"

# --- Supporting files exist ---

assert_file_exists ".mcp.json" ".mcp.json"
assert_json_valid ".mcp.json is valid JSON" ".mcp.json"
assert_file_exists ".env.example" ".env.example"
assert_file_exists ".editorconfig" ".editorconfig"
assert_file_exists ".gitignore" ".gitignore"

# --- Scripts exist and are executable ---

assert_file_exists "scripts/setup.sh" "scripts/setup.sh"
assert_file_executable "scripts/setup.sh is executable" "scripts/setup.sh"
assert_bash_syntax "scripts/setup.sh valid bash" "scripts/setup.sh"

assert_file_exists "scripts/install-hooks.sh" "scripts/install-hooks.sh"
assert_file_executable "scripts/install-hooks.sh is executable" "scripts/install-hooks.sh"
assert_bash_syntax "scripts/install-hooks.sh valid bash" "scripts/install-hooks.sh"

# --- .gitignore includes critical entries ---

GITIGNORE=$(cat .gitignore)
assert_contains ".gitignore: excludes .env" "$GITIGNORE" ".env"
assert_contains ".gitignore: excludes settings.local.json" "$GITIGNORE" "settings.local.json"
assert_contains ".gitignore: excludes node_modules" "$GITIGNORE" "node_modules"
assert_contains ".gitignore: excludes .DS_Store" "$GITIGNORE" ".DS_Store"

# --- Command frontmatter validation ---

for cmd in "${PROJECT_CMDS[@]}"; do
    CMD_CONTENT=$(cat ".claude/commands/$cmd.md")
    assert_contains "Command $cmd: has frontmatter" "$CMD_CONTENT" "description:"
    assert_contains "Command $cmd: has allowed-tools" "$CMD_CONTENT" "allowed-tools:"
done

# --- Root CLAUDE.md content validation ---

CLAUDE_SECTIONS=("Overview" "Tech Stack" "Project Structure" "Conventions" "Key Commands" "Auto-Sync Rules")
for section in "${CLAUDE_SECTIONS[@]}"; do
    if grep -qF "## $section" CLAUDE.md; then
        pass "CLAUDE.md: has $section"
    else
        fail "CLAUDE.md: has $section" "section '## $section' not found in CLAUDE.md"
    fi
done
