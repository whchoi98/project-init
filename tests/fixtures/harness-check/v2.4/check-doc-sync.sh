#!/bin/bash
# Detect documentation sync needs after file changes.
# Triggered by PostToolUse (Write|Edit) events; event JSON arrives on stdin.
# Walks parent directories to find CLAUDE.md before warning.

FILE_PATH="${1:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    FILE_PATH=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
[ -z "$FILE_PATH" ] && exit 0
FILE_PATH="${FILE_PATH#"$PWD"/}"   # absolute -> repo-relative

MESSAGES=""

# Detect source root directories (adapt per project)
# Default: src/, app/, lib/  |  Plugin projects: plugins/
SOURCE_ROOTS="src app lib plugins"

for ROOT in $SOURCE_ROOTS; do
    if [[ "$FILE_PATH" == ${ROOT}/* ]]; then
        DIR=$(dirname "$FILE_PATH")
        FOUND_CLAUDE=false
        CHECK_DIR="$DIR"
        while [ "$CHECK_DIR" != "$ROOT" ] && [ "$CHECK_DIR" != "." ]; do
            if [ -f "$CHECK_DIR/CLAUDE.md" ]; then
                FOUND_CLAUDE=true
                break
            fi
            CHECK_DIR=$(dirname "$CHECK_DIR")
        done
        if ! $FOUND_CLAUDE && [ "$DIR" != "$ROOT" ]; then
            MESSAGES="$MESSAGES[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation. "
        fi
        break
    fi
done

# Alert if no ADRs exist when source or architecture files change
IS_SOURCE=false
for ROOT in $SOURCE_ROOTS; do
    [[ "$FILE_PATH" == ${ROOT}/* ]] && IS_SOURCE=true && break
done
if $IS_SOURCE || [[ "$FILE_PATH" == docs/architecture.md ]]; then
    ADR_COUNT=$(find docs/decisions -name 'ADR-*.md' -not -name '.template.md' 2>/dev/null | wc -l)
    if [ "$ADR_COUNT" -eq 0 ]; then
        MESSAGES="$MESSAGES[doc-sync] No ADRs found. Record architectural decisions. "
    fi
fi

# Alert if no runbooks exist when infrastructure files change
if [[ "$FILE_PATH" == Dockerfile* ]] || [[ "$FILE_PATH" == *terraform* ]] || [[ "$FILE_PATH" == *cdk* ]] || [[ "$FILE_PATH" == template.yaml ]]; then
    RUNBOOK_COUNT=$(find docs/runbooks -name '*.md' -not -name '.template.md' 2>/dev/null | wc -l)
    if [ "$RUNBOOK_COUNT" -eq 0 ]; then
        MESSAGES="$MESSAGES[doc-sync] No runbooks found. Create operational runbooks for deployment/recovery. "
    fi
fi

# Return reminders as additionalContext so Claude sees them
if [ -n "$MESSAGES" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$MESSAGES"
fi
