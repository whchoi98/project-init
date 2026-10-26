#!/bin/bash
# PostToolUse (Write|Edit): note when a file lands in a plugin that has no CLAUDE.md at its root.
# project-init:module-coverage: each plugin is one module. This repo keeps one CLAUDE.md per plugin
# root (plugins/CLAUDE.md); subdirectories such as commands/ or agents/ do not get their own, so
# only plugins/<name>/CLAUDE.md is checked, and a subdirectory is never asked for one.
# Input: the path as $1 (tests), else the event JSON on stdin (tool_input.file_path).
# Stdin is read only when no argument is given, so a test passing "" never blocks.
# The note is returned as hookSpecificOutput.additionalContext so Claude sees it (ADR-008).

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
FILE_PATH="${1:-}"
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    FILE_PATH=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
[ -z "$FILE_PATH" ] && exit 0
# Most edits are outside plugins/: leave before the git calls below. A linked worktree's path
# (.../.claude/worktrees/<name>/plugins/...) still matches.
case "$FILE_PATH" in plugins/*/*|*/plugins/*/*) ;; *) exit 0 ;; esac

# common_dir <dir>: the repository's shared git directory, the same for a linked worktree and its
# main checkout
common_dir() {
    (
        cd "$1" 2>/dev/null || exit 0
        top=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$top" || exit 0
        dir=$(git rev-parse --git-common-dir 2>/dev/null) && cd "$dir" && pwd -P
    ) 2>/dev/null
}

# CLAUDE_PROJECT_DIR stays at the session's checkout while Claude edits in a linked worktree, so an
# absolute path is made relative to the edited file's own work tree when that tree belongs to this
# repository; git prints the relative path, so a symlinked checkout path makes no difference.
FILE_DIR=$(dirname "$FILE_PATH")
if [[ "$FILE_PATH" == /* ]] && TOP=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null) &&
    [ "$(common_dir "$TOP")" = "$(common_dir "$ROOT")" ]; then
    ROOT="$TOP"
    FILE_PATH="$(git -C "$FILE_DIR" rev-parse --show-prefix)${FILE_PATH##*/}"
else
    FILE_PATH="${FILE_PATH#"$ROOT"/}"   # absolute -> repo-relative
fi
[[ "$FILE_PATH" == plugins/*/* ]] || exit 0   # files directly in plugins/ belong to no plugin

REL="${FILE_PATH#plugins/}"
PLUGIN_DIR="plugins/${REL%%/*}"
[ -f "$ROOT/$PLUGIN_DIR/CLAUDE.md" ] && exit 0

MSG="[doc-sync] $PLUGIN_DIR/CLAUDE.md is missing; each plugin keeps one CLAUDE.md at its root (role, key files, rules), and its subdirectories do not get their own; see plugins/CLAUDE.md."
python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": sys.argv[1]}}))' "$MSG"
