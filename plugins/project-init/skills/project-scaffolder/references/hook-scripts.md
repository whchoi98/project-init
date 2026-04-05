# Hook Scripts

## check-doc-sync.sh

Path: `.claude/hooks/check-doc-sync.sh`

This hook runs after Write/Edit operations and detects when documentation sync is needed.

```bash
#!/bin/bash
# Detect documentation sync needs after file changes.
# Triggered by PostToolUse (Write|Edit) events.

FILE_PATH="${1:-}"
[ -z "$FILE_PATH" ] && exit 0

# Detect missing CLAUDE.md in src/ subdirectories
if [[ "$FILE_PATH" == src/* ]] || [[ "$FILE_PATH" == app/* ]] || [[ "$FILE_PATH" == lib/* ]]; then
    DIR=$(dirname "$FILE_PATH")
    if [ ! -f "$DIR/CLAUDE.md" ] && [ "$DIR" != "src" ] && [ "$DIR" != "app" ] && [ "$DIR" != "lib" ]; then
        echo "[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation."
    fi
fi

# Alert if no ADRs exist when source or architecture files change
if [[ "$FILE_PATH" == src/* ]] || [[ "$FILE_PATH" == docs/architecture.md ]]; then
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
```

### How It Works

| Trigger | Condition | Message |
|---------|-----------|---------|
| File edited under `src/`, `app/`, or `lib/` | Directory has no `CLAUDE.md` | Prompts to create module doc |
| File edited under `src/` or `docs/architecture.md` | No ADR files exist | Prompts to record decisions |
| Infrastructure file edited | No runbook files exist | Prompts to create runbooks |

### Installation

```bash
chmod +x .claude/hooks/check-doc-sync.sh
```

The hook is registered in `.claude/settings.json` under `hooks.PostToolUse`.

---

## secret-scan.sh (PreCommit Hook)

Path: `.claude/hooks/secret-scan.sh`

Scans staged files for secrets, API keys, and credentials before commit.

```bash
#!/bin/bash
# Scan staged files for secrets before commit.
# Triggered by PreCommit event.
# Exit 1 to block the commit if secrets are found.

SECRETS_FOUND=0

# Patterns to detect
PATTERNS=(
    'AKIA[0-9A-Z]{16}'                          # AWS Access Key ID
    '[A-Za-z0-9/+=]{40}'                         # AWS Secret Key (heuristic)
    'sk-[A-Za-z0-9]{48}'                         # OpenAI API Key
    'sk-ant-[A-Za-z0-9-]{95}'                    # Anthropic API Key
    'ghp_[A-Za-z0-9]{36}'                        # GitHub Personal Access Token
    'xoxb-[0-9]+-[A-Za-z0-9]+'                   # Slack Bot Token
    'password\s*[:=]\s*["\x27][^"\x27]{8,}'      # Password assignments
    'secret\s*[:=]\s*["\x27][^"\x27]{8,}'        # Secret assignments
    'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}'   # API key assignments
)

# Files to skip
SKIP_PATTERNS=('.env.example' 'secret-scan.sh' '*.md' 'package-lock.json' 'yarn.lock')

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
[ -z "$STAGED_FILES" ] && exit 0

for file in $STAGED_FILES; do
    # Skip binary files and excluded patterns
    skip=false
    for pattern in "${SKIP_PATTERNS[@]}"; do
        [[ "$file" == $pattern ]] && skip=true && break
    done
    $skip && continue
    [ ! -f "$file" ] && continue

    for regex in "${PATTERNS[@]}"; do
        if grep -qP "$regex" "$file" 2>/dev/null; then
            echo "[secret-scan] Potential secret found in $file (pattern: ${regex:0:30}...)"
            SECRETS_FOUND=1
        fi
    done
done

if [ "$SECRETS_FOUND" -eq 1 ]; then
    echo ""
    echo "[secret-scan] BLOCKED: Potential secrets detected in staged files."
    echo "[secret-scan] Review the files above and remove secrets before committing."
    echo "[secret-scan] Use .env files for secrets and .env.example for templates."
    exit 1
fi
```

### How It Works

| Pattern | Detects |
|---------|---------|
| `AKIA[0-9A-Z]{16}` | AWS Access Key IDs |
| `sk-[A-Za-z0-9]{48}` | OpenAI API Keys |
| `sk-ant-...` | Anthropic API Keys |
| `ghp_...` | GitHub Personal Access Tokens |
| `xoxb-...` | Slack Bot Tokens |
| `password\s*[:=]` | Hardcoded passwords |
| `api[_-]?key\s*[:=]` | Hardcoded API keys |

### Installation

```bash
chmod +x .claude/hooks/secret-scan.sh
```

Registered in `.claude/settings.json` under `hooks.PreCommit`.

---

## session-context.sh (SessionStart Hook)

Path: `.claude/hooks/session-context.sh`

Loads project context at session start to help Claude understand the project immediately.

```bash
#!/bin/bash
# Load project context at Claude Code session start.
# Outputs key project information for immediate context.

echo "=== Project Context ==="

# Project type detection
if [ -f "package.json" ]; then
    NAME=$(python3 -c "import json; print(json.load(open('package.json')).get('name',''))" 2>/dev/null)
    echo "Project: $NAME (Node.js)"
elif [ -f "pyproject.toml" ]; then
    echo "Project: $(basename $(pwd)) (Python)"
elif [ -f "go.mod" ]; then
    MODULE=$(head -1 go.mod | awk '{print $2}')
    echo "Project: $MODULE (Go)"
elif [ -f "Cargo.toml" ]; then
    echo "Project: $(basename $(pwd)) (Rust)"
else
    echo "Project: $(basename $(pwd))"
fi

# Recent activity
LAST_COMMIT=$(git log -1 --format="%h %s (%cr)" 2>/dev/null)
[ -n "$LAST_COMMIT" ] && echo "Last commit: $LAST_COMMIT"

# Branch info
BRANCH=$(git branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] && echo "Branch: $BRANCH"

# Uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[ "$CHANGES" -gt 0 ] && echo "Uncommitted changes: $CHANGES file(s)"

# Documentation status
CLAUDE_COUNT=$(find . -name "CLAUDE.md" -not -path "./.git/*" 2>/dev/null | wc -l | tr -d ' ')
echo "CLAUDE.md files: $CLAUDE_COUNT"

echo "======================"
```

### Installation

```bash
chmod +x .claude/hooks/session-context.sh
```

Registered in `.claude/settings.json` under `hooks.SessionStart`.

---

## notify.sh (Notification Hook)

Path: `.claude/hooks/notify.sh`

Sends notifications via webhook on significant events (Stop event, session end).

```bash
#!/bin/bash
# Send notifications via webhook on Claude Code events.
# Triggered by Notification events.
# Configure WEBHOOK_URL in .env or export it before use.

WEBHOOK_URL="${CLAUDE_NOTIFY_WEBHOOK:-}"
[ -z "$WEBHOOK_URL" ] && exit 0

EVENT="${1:-unknown}"
MESSAGE="${2:-Claude Code event occurred}"

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
```

### Configuration

Set the webhook URL as an environment variable:

```bash
export CLAUDE_NOTIFY_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

Or add to `.env`:

```
CLAUDE_NOTIFY_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Installation

```bash
chmod +x .claude/hooks/notify.sh
```

Registered in `.claude/settings.json` under `hooks.Notification`.

---

## Git commit-msg Hook

Path: `.git/hooks/commit-msg`

Automatically removes Co-Authored-By lines from commit messages to exclude AI contributors from git history.

```bash
#!/bin/bash
# Remove Co-Authored-By lines from commit messages.
# Prevents Claude and other AI assistants from appearing as contributors.
# Covers variations: Co-Authored-By, Co-authored-by, co-authored-by

# Remove all Co-Authored-By variations (case-insensitive)
sed -i '/^[Cc]o-[Aa]uthored-[Bb]y:.*/d' "$1"

# Remove any trailing blank lines left after removal
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$1"
```

### Installation

```bash
chmod +x .git/hooks/commit-msg
```

Note: This is a Git hook (`.git/hooks/`), not a Claude hook (`.claude/hooks/`).
This hook ensures that Claude, Copilot, and other AI tools are not listed as co-authors in the commit history.
