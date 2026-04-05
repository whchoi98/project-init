#!/bin/bash
# Detect documentation sync needs after file changes.
# Triggered by PostToolUse (Write|Edit) events.
# Adapted for plugin marketplace project (watches plugins/ instead of src/).

FILE_PATH="${1:-}"
[ -z "$FILE_PATH" ] && exit 0

# Detect missing CLAUDE.md in plugins/ subdirectories
# Checks current directory and walks up to plugins/ root
if [[ "$FILE_PATH" == plugins/* ]]; then
    DIR=$(dirname "$FILE_PATH")
    FOUND_CLAUDE=false
    CHECK_DIR="$DIR"
    while [ "$CHECK_DIR" != "plugins" ] && [ "$CHECK_DIR" != "." ]; do
        if [ -f "$CHECK_DIR/CLAUDE.md" ]; then
            FOUND_CLAUDE=true
            break
        fi
        CHECK_DIR=$(dirname "$CHECK_DIR")
    done
    if ! $FOUND_CLAUDE && [ "$DIR" != "plugins" ]; then
        echo "[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation."
    fi
fi

# Alert if no ADRs exist when plugin source or architecture files change
if [[ "$FILE_PATH" == plugins/* ]] || [[ "$FILE_PATH" == docs/architecture.md ]]; then
    ADR_COUNT=$(find docs/decisions -name 'ADR-*.md' -not -name '.template.md' 2>/dev/null | wc -l)
    if [ "$ADR_COUNT" -eq 0 ]; then
        echo "[doc-sync] No ADRs found. Record architectural decisions."
    fi
fi

# Alert if no runbooks exist when infrastructure files change
if [[ "$FILE_PATH" == Dockerfile* ]] || [[ "$FILE_PATH" == *terraform* ]] || [[ "$FILE_PATH" == *cdk* ]] || [[ "$FILE_PATH" == template.yaml ]]; then
    RUNBOOK_COUNT=$(find docs/runbooks -name '*.md' -not -name '.template.md' 2>/dev/null | wc -l)
    if [ "$RUNBOOK_COUNT" -eq 0 ]; then
        echo "[doc-sync] No runbooks found. Create operational runbooks for deployment/recovery."
    fi
fi
