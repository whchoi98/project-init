#!/bin/bash
# Tests for .claude/hooks/*.sh
# Validates syntax, executability, and basic behavior

# --- Existence and permissions ---

assert_file_exists "check-doc-sync.sh exists" ".claude/hooks/check-doc-sync.sh"
assert_file_exists "secret-scan.sh exists" ".claude/hooks/secret-scan.sh"
assert_file_exists "session-context.sh exists" ".claude/hooks/session-context.sh"
assert_file_exists "notify.sh exists" ".claude/hooks/notify.sh"

assert_file_executable "check-doc-sync.sh is executable" ".claude/hooks/check-doc-sync.sh"
assert_file_executable "secret-scan.sh is executable" ".claude/hooks/secret-scan.sh"
assert_file_executable "session-context.sh is executable" ".claude/hooks/session-context.sh"
assert_file_executable "notify.sh is executable" ".claude/hooks/notify.sh"

# --- Bash syntax validation ---

assert_bash_syntax "check-doc-sync.sh valid bash" ".claude/hooks/check-doc-sync.sh"
assert_bash_syntax "secret-scan.sh valid bash" ".claude/hooks/secret-scan.sh"
assert_bash_syntax "session-context.sh valid bash" ".claude/hooks/session-context.sh"
assert_bash_syntax "notify.sh valid bash" ".claude/hooks/notify.sh"

# --- settings.json hook registration ---

assert_file_exists "settings.json exists" ".claude/settings.json"
assert_json_valid "settings.json is valid JSON" ".claude/settings.json"

SETTINGS=$(cat .claude/settings.json)
assert_contains "SessionStart hook registered" "$SETTINGS" "session-context.sh"
assert_contains "PreCommit hook registered" "$SETTINGS" "secret-scan.sh"
assert_contains "PostToolUse hook registered" "$SETTINGS" "check-doc-sync.sh"
assert_contains "PostToolUse matcher is Write|Edit" "$SETTINGS" "Write|Edit"
assert_contains "Notification hook registered" "$SETTINGS" "notify.sh"

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

# --- notify.sh behavior ---

# Without webhook URL, should exit silently
OUTPUT=$(CLAUDE_NOTIFY_WEBHOOK="" bash .claude/hooks/notify.sh "test" "msg" 2>&1)
assert_eq "notify.sh: no webhook URL produces no output" "" "$OUTPUT"
