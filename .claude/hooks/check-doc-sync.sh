#!/bin/bash
# PostToolUse (Write|Edit): remind Claude to add a module CLAUDE.md when a new plugin directory appears.
# Claude Code passes the hook event as JSON on stdin; the reminder is returned as additionalContext (ADR-008).
# A path may also be passed as $1 (used by tests); stdin is read only when no argument is given.

FILE_PATH="${1:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    FILE_PATH=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
[ -z "$FILE_PATH" ] && exit 0

# Normalize absolute paths to repo-relative
FILE_PATH="${FILE_PATH#"$PWD"/}"
[[ "$FILE_PATH" == plugins/* ]] || exit 0

# Walk from the file's directory up to plugins/ looking for a CLAUDE.md
DIR=$(dirname "$FILE_PATH")
CHECK_DIR="$DIR"
while [ "$CHECK_DIR" != "plugins" ] && [ "$CHECK_DIR" != "." ]; do
    [ -f "$CHECK_DIR/CLAUDE.md" ] && exit 0
    CHECK_DIR=$(dirname "$CHECK_DIR")
done
[ "$DIR" = "plugins" ] && exit 0

MSG="[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation."
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$MSG"
