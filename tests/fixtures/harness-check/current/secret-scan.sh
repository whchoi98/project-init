#!/bin/bash
# Fixture stub for tests/structure/test-harness-check.sh: carries the signals harness-check reads
# from a current secret-scan.sh, not the real scan (that lives in hook-scripts.md).
# project-init:commit-scope
CMD="${1:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    CMD=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
fi
case "$CMD" in
    *"git commit"*) ;;
    *) exit 0 ;;
esac
echo "[secret-scan] BLOCKED: fixture stub" >&2
exit 2
