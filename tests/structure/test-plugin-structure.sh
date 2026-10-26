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

# A release bumps every file below together (docs/runbooks/release.md). Nothing else compares
# them, so without these checks the README and CHANGELOG drift while the suite stays green.
MARKETPLACE_PLUGIN_VER=$(python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])" 2>/dev/null || echo "missing")
assert_eq "Version sync: marketplace.json plugins[0].version matches plugin.json" "$PLUGIN_VER" "$MARKETPLACE_PLUGIN_VER"

README_BADGE_VER=$(python3 -c "
import re
m = re.search(r'badge/version-(\d+\.\d+\.\d+)-', open('README.md', encoding='utf-8').read())
print(m.group(1) if m else 'missing')" 2>/dev/null || echo "missing")
assert_eq "Version sync: README version badge matches plugin.json" "$PLUGIN_VER" "$README_BADGE_VER"

README_STALE_LABELS=$(python3 -c "
import re, sys
text = open('README.md', encoding='utf-8').read()
print(' '.join(sorted(set(v for v in re.findall(r'\(v(\d+\.\d+\.\d+)\)', text) if v != sys.argv[1]))))" "$PLUGIN_VER" 2>/dev/null || echo "unreadable")
assert_eq "Version sync: README (vX.Y.Z) structure-tree labels match plugin.json" "" "$README_STALE_LABELS"

CHANGELOG_VERS=$(python3 -c "
import re
english, marker, korean = open('CHANGELOG.md', encoding='utf-8').read().partition('<a id=\"korean\"></a>')
def latest(section):
    m = re.search(r'^## \[(\d+\.\d+\.\d+)\]', section, re.M)
    return m.group(1) if m else 'missing'
print(latest(english), latest(korean) if marker else 'missing')" 2>/dev/null || echo "missing missing")
read -r CHANGELOG_EN_VER CHANGELOG_KO_VER <<< "$CHANGELOG_VERS"
assert_eq "Version sync: latest English CHANGELOG release matches plugin.json" "$PLUGIN_VER" "$CHANGELOG_EN_VER"
assert_eq "Version sync: latest Korean CHANGELOG release matches plugin.json" "$PLUGIN_VER" "$CHANGELOG_KO_VER"

# --- Plugin commands exist ---

COMMANDS=(init-project sync-docs add-adr add-module add-runbook health-check add-reference-doc generate-readme generate-changelog migrate-hooks)
for cmd in "${COMMANDS[@]}"; do
    assert_file_exists "Plugin command: $cmd.md" "plugins/project-init/commands/$cmd.md"
done

# --- Plugin agents exist ---

assert_file_exists "Plugin agent: doc-sync-checker.md" "plugins/project-init/agents/doc-sync-checker.md"

# --- Plugin skill exists ---

assert_file_exists "Plugin skill: SKILL.md" "plugins/project-init/skills/project-scaffolder/SKILL.md"

# --- Reference templates exist ---

TEMPLATES=(claude-md-template docs-templates hook-scripts settings-json-template skills-templates agents-templates mcp-json-template scripts-templates tests-templates)
for tmpl in "${TEMPLATES[@]}"; do
    assert_file_exists "Reference: $tmpl.md" "plugins/project-init/skills/project-scaffolder/references/$tmpl.md"
done

# --- Hook and test templates: blocks parse, and copies of this repo's files stay identical ---
# Consumers get the template copies, so the repo hook and its template must not drift (ADR-003).

TPL_DIR="plugins/project-init/skills/project-scaffolder/references"
TPL_BAD=$(python3 -c '
import json, re, subprocess, sys
bad = []
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    for lang, body in re.findall(r"^```(bash|json)\n(.*?)^```$", text, re.S | re.M):
        if lang == "json":
            try:
                json.loads(body)
            except ValueError as err:
                bad.append("%s: json block: %s" % (path, err))
        elif subprocess.run(["bash", "-n"], input=body.encode(), stderr=subprocess.DEVNULL).returncode:
            bad.append("%s: bash block starting %r" % (path, body.splitlines()[0][:40]))
print("; ".join(bad))
' "$TPL_DIR/hook-scripts.md" "$TPL_DIR/settings-json-template.md" "$TPL_DIR/tests-templates.md" 2>&1 || true)
assert_eq "Templates: every bash block passes bash -n and every json block parses" "" "$TPL_BAD"

# tpl_block <template> <heading line> <fence language> <n>: print the n-th such block after the heading
tpl_block() {
    python3 -c '
import sys
path, heading, lang, n = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
lines = open(path, encoding="utf-8").read().split("\n")
block, seen = None, 0
for line in lines[lines.index(heading) + 1:]:
    if block is None:
        if line == "```" + lang:
            seen, block = seen + 1, []
    elif line == "```":
        if seen == n:
            print("\n".join(block))
            break
        block = None
    else:
        block.append(line)
' "$@" 2>/dev/null || true
}
# tpl_sync <repo file> <template> <heading line> <fence language> <n>
tpl_sync() {
    local desc="Template sync: ${2##*/} '${3#\#* }' block matches $1"
    if [ "$(cat "$1" 2>/dev/null)" = "$(tpl_block "$2" "$3" "$4" "$5")" ]; then
        pass "$desc"
    else
        fail "$desc" "the $4 block under '$3' differs from $1; copy the file into the block"
    fi
}
tpl_sync .claude/hooks/secret-scan.sh "$TPL_DIR/hook-scripts.md" "## secret-scan.sh (PreToolUse Hook, Core)" bash 1
tpl_sync tests/hooks/test-secret-patterns.sh "$TPL_DIR/tests-templates.md" "## Secret Pattern Tests" bash 1
tpl_sync tests/fixtures/secret-samples.txt "$TPL_DIR/tests-templates.md" "### Test Fixture Files" text 1
tpl_sync tests/fixtures/false-positives.txt "$TPL_DIR/tests-templates.md" "### Test Fixture Files" text 2

# --- Project-level commands exist ---

PROJECT_CMDS=(review test-all deploy)
for cmd in "${PROJECT_CMDS[@]}"; do
    assert_file_exists "Command: $cmd.md" ".claude/commands/$cmd.md"
done

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
