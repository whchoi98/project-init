#!/bin/bash
# Fixture stub for tests/structure/test-harness-check.sh: reads the event JSON on stdin like the
# current check-doc-sync.sh template; the real logic lives in hook-scripts.md.
# project-init:module-coverage
SOURCE_ROOTS="src app lib"
FILE_PATH="${1:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    FILE_PATH=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
[ -z "$FILE_PATH" ] && exit 0
exit 0
