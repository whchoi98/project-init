# settings.json Template

Use this template for `.claude/settings.json`.

---

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-doc-sync.sh \"$TOOL_INPUT_PATH\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

## Hook Explanation

| Field | Value | Purpose |
|-------|-------|---------|
| `matcher` | `Write\|Edit` | Triggers on file write or edit operations |
| `command` | `check-doc-sync.sh` | Checks if documentation sync is needed |
| `2>/dev/null \|\| true` | Error suppression | Prevents hook failures from blocking work |

## Customization

Add permissions as needed:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm test:*)",
      "Bash(npm run lint:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)"
    ]
  }
}
```
