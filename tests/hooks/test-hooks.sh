#!/bin/bash
# Tests for .claude/hooks/*.sh
# Validates syntax, executability, and basic behavior

# --- Existence and permissions ---

assert_file_exists "check-doc-sync.sh exists" ".claude/hooks/check-doc-sync.sh"
assert_file_exists "secret-scan.sh exists" ".claude/hooks/secret-scan.sh"
assert_file_exists "session-context.sh exists" ".claude/hooks/session-context.sh"

assert_file_executable "check-doc-sync.sh is executable" ".claude/hooks/check-doc-sync.sh"
assert_file_executable "secret-scan.sh is executable" ".claude/hooks/secret-scan.sh"
assert_file_executable "session-context.sh is executable" ".claude/hooks/session-context.sh"

# --- Bash syntax validation ---

assert_bash_syntax "check-doc-sync.sh valid bash" ".claude/hooks/check-doc-sync.sh"
assert_bash_syntax "secret-scan.sh valid bash" ".claude/hooks/secret-scan.sh"
assert_bash_syntax "session-context.sh valid bash" ".claude/hooks/session-context.sh"

# --- settings.json hook registration ---

assert_file_exists "settings.json exists" ".claude/settings.json"
assert_json_valid "settings.json is valid JSON" ".claude/settings.json"

SETTINGS=$(cat .claude/settings.json)
assert_contains "SessionStart hook registered" "$SETTINGS" "session-context.sh"
assert_contains "PreToolUse hook registered" "$SETTINGS" "secret-scan.sh"
assert_contains "PostToolUse hook registered" "$SETTINGS" "check-doc-sync.sh"
assert_contains "PostToolUse matcher is Write|Edit" "$SETTINGS" "Write|Edit"
assert_contains "PreToolUse gate registered without || true (ADR-004/008)" "$SETTINGS" '"bash .claude/hooks/secret-scan.sh"'

# --- check-doc-sync.sh behavior ---

# Empty input should exit silently
OUTPUT=$(bash .claude/hooks/check-doc-sync.sh "" 2>&1)
assert_eq "check-doc-sync: empty path produces no output" "" "$OUTPUT"

# Plugins path triggers CLAUDE.md check (simulate missing CLAUDE.md)
OUTPUT=$(bash .claude/hooks/check-doc-sync.sh "plugins/new-plugin/commands/foo.md" 2>&1)
assert_contains "check-doc-sync: detects missing CLAUDE.md in plugins/" "$OUTPUT" "CLAUDE.md is missing"

# Existing path with CLAUDE.md should not warn
OUTPUT=$(bash .claude/hooks/check-doc-sync.sh "plugins/project-init/commands/foo.md" 2>&1)
EXPECTS_NO_MISSING=$(echo "$OUTPUT" | grep "CLAUDE.md is missing" || true)
assert_eq "check-doc-sync: no warning for dir with CLAUDE.md" "" "$EXPECTS_NO_MISSING"

# --- session-context.sh behavior ---

OUTPUT=$(bash .claude/hooks/session-context.sh 2>&1)
assert_contains "session-context: shows project header" "$OUTPUT" "Project Context"
assert_contains "session-context: shows project name" "$OUTPUT" "project-init"
assert_contains "session-context: shows branch info" "$OUTPUT" "Branch:"
assert_contains "session-context: shows CLAUDE.md count" "$OUTPUT" "CLAUDE.md files:"

# --- stdin JSON contract (ADR-008) ---

# check-doc-sync reads tool_input.file_path from stdin and answers with additionalContext
OUTPUT=$(echo '{"tool_input":{"file_path":"plugins/new-plugin/commands/foo.md"}}' | bash .claude/hooks/check-doc-sync.sh 2>&1)
assert_contains "check-doc-sync: reads file_path from stdin JSON" "$OUTPUT" "additionalContext"
assert_contains "check-doc-sync: stdin path reports missing CLAUDE.md" "$OUTPUT" "plugins/new-plugin/commands/CLAUDE.md is missing"

# absolute paths are normalized to repo-relative
OUTPUT=$(echo "{\"tool_input\":{\"file_path\":\"$PWD/plugins/project-init/commands/foo.md\"}}" | bash .claude/hooks/check-doc-sync.sh 2>&1)
assert_eq "check-doc-sync: absolute covered path is silent" "" "$OUTPUT"

# secret-scan only gates git commit
OUTPUT=$(echo '{"tool_input":{"command":"ls -la"}}' | bash .claude/hooks/secret-scan.sh 2>&1; echo "exit=$?")
assert_eq "secret-scan: non-commit command passes with exit 0" "exit=0" "$OUTPUT"

# secret-scan blocks a commit with a staged secret using exit 2
# (wrapped in `if` so the runner's `set -e` does not abort on the expected non-zero exit)
SCAN_TMP=$(mktemp -d)
SCAN_RC=0
(
  cd "$SCAN_TMP" && git init -q && printf 'key = "AKIAIOSFODNN7EXAMPLE"\n' > cfg.py && git add cfg.py
  if echo '{"tool_input":{"command":"git commit -m test"}}' | bash "$OLDPWD/.claude/hooks/secret-scan.sh" >/dev/null 2>&1; then
    echo 0 > "$SCAN_TMP/result"
  else
    echo $? > "$SCAN_TMP/result"
  fi
) || true
SCAN_RC=$(cat "$SCAN_TMP/result" 2>/dev/null || echo "unknown")
assert_eq "secret-scan: staged secret blocks commit with exit 2" "2" "$SCAN_RC"
rm -r "$SCAN_TMP"
