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
if [[ "$FILE_PATH" == src/* ]]; then
    DIR=$(dirname "$FILE_PATH")
    if [ ! -f "$DIR/CLAUDE.md" ] && [ "$DIR" != "src" ]; then
        echo "[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation."
    fi
fi

# Alert if no ADRs exist when source or architecture files change
if [[ "$FILE_PATH" == src/* ]] || [[ "$FILE_PATH" == docs/architecture.md ]]; then
    ADR_COUNT=$(find docs/decisions -name 'ADR-*.md' 2>/dev/null | wc -l)
    if [ "$ADR_COUNT" -eq 0 ]; then
        echo "[doc-sync] No ADRs found. Record architectural decisions."
    fi
fi
```

### How It Works

| Trigger | Condition | Message |
|---------|-----------|---------|
| File edited under `src/` | Directory has no `CLAUDE.md` | Prompts to create module doc |
| File edited under `src/` or `docs/architecture.md` | No ADR files exist | Prompts to record decisions |

### Installation

```bash
chmod +x .claude/hooks/check-doc-sync.sh
```

The hook is registered in `.claude/settings.json` under `hooks.PostToolUse`.

---

## Git commit-msg Hook

Path: `.git/hooks/commit-msg`

Automatically removes Co-Authored-By lines from commit messages.

```bash
#!/bin/bash
# Remove Co-Authored-By lines from commit messages.
# Prevents unintended contributors from appearing in git history.
sed -i '/^Co-Authored-By:.*/d' "$1"
```

### Installation

```bash
chmod +x .git/hooks/commit-msg
```

Note: This is a Git hook (`.git/hooks/`), not a Claude hook (`.claude/hooks/`).
