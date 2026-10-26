#!/bin/bash
# Send notifications via webhook on Claude Code events.
# Triggered by Notification events; event JSON ({"hook_event_name":..., "message":...}) arrives on stdin.
# Configure WEBHOOK_URL in .env or export it before use.

WEBHOOK_URL="${CLAUDE_NOTIFY_WEBHOOK:-}"
[ -z "$WEBHOOK_URL" ] && exit 0

EVENT="${1:-}"
MESSAGE="${2:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    read -r EVENT MESSAGE < <(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("hook_event_name","Notification"), d.get("message",""))' 2>/dev/null)
fi
EVENT="${EVENT:-unknown}"
MESSAGE="${MESSAGE:-Claude Code event occurred}"

# Build payload
PAYLOAD=$(cat <<EOF
{
  "text": "[$EVENT] $MESSAGE",
  "project": "$(basename $(pwd))",
  "branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

# Send notification (non-blocking)
curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null 2>&1 &
