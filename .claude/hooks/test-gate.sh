#!/bin/bash
# Stop gate: when the working tree has changes, run the test suite and keep Claude working while
# it fails. Exit 2 hands stderr to Claude as the reason to continue (ADR-008); registered without
# `|| true` because it is a gate (ADR-004), with a timeout in .claude/settings.json.
# Input: the Stop event JSON on stdin, read only when no argument is given and stdin is not a TTY.
# Every run records the tree's fingerprint, green or red, and a tree identical to the last run is
# skipped: a turn without edits costs nothing, and a red tree is reported once, not on every prompt.
# A run the hook timeout kills is reported once, on the next Stop, as a systemMessage to the user.
# So when stop_hook_active is true (Claude is already continuing because of this gate), the suite
# runs again only if Claude changed something since, which bounds re-blocking to turns that
# attempted a fix; Claude Code also ends the turn after 8 consecutive blocks.
# TEST_GATE_CMD overrides the command; the tests use it so the suite never runs itself.

INPUT=""
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    INPUT=$(cat)
fi
ACTIVE=false
[[ "$INPUT" =~ \"stop_hook_active\"[[:space:]]*:[[:space:]]*true ]] && ACTIVE=true
GATE_CMD="${TEST_GATE_CMD:-bash tests/run-all.sh}"

# common_dir <dir>: the repository's shared git directory, the same for a linked worktree and its
# main checkout
common_dir() {
    (
        cd "$1" 2>/dev/null || exit 0
        top=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$top" || exit 0
        dir=$(git rev-parse --git-common-dir 2>/dev/null) && cd "$dir" && pwd -P
    ) 2>/dev/null
}

# CLAUDE_PROJECT_DIR stays at the session's checkout, while the event's cwd follows Claude into a
# linked worktree. Test the tree Claude works in, but only when it belongs to this repository, so
# a cd into another repository never runs this suite there.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
HOOK_CWD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd") or "")' 2>/dev/null)
if [ -n "$HOOK_CWD" ]; then
    TOP=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
    PREFIX=$(git -C "$ROOT" rev-parse --show-prefix 2>/dev/null)   # ROOT may be below its repo's top
    if [ -n "$TOP" ] && [ -d "$TOP/$PREFIX" ] && [ "$(common_dir "$TOP")" = "$(common_dir "$ROOT")" ]; then
        ROOT="$TOP${PREFIX:+/${PREFIX%/}}"
    fi
fi
cd "$ROOT" 2>/dev/null || exit 0
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

# fingerprint: the command, status, tracked diffs, and the contents of untracked regular files.
# Only regular files are hashed, because a nested repository or worktree (listed as dir/) or a
# dangling symlink would stop a batched `git hash-object` and drop every later file.
fingerprint() {
    {
        printf '%s\n' "$GATE_CMD"
        git status --porcelain
        git diff
        git diff --cached
        git ls-files -z --others --exclude-standard | while IFS= read -r -d '' f; do
            [ -f "$f" ] && [ -r "$f" ] && case "$f" in *$'\n'*) ;; *) printf '%s\n' "$f" ;; esac
        done | git hash-object --stdin-paths
    } 2>/dev/null | git hash-object --stdin 2>/dev/null
}
CACHE="${TMPDIR:-/tmp}/claude-test-gate-$(pwd -P | git hash-object --stdin)"
STATE=$(fingerprint)
LAST=$(cat "$CACHE" 2>/dev/null)
[ -n "$STATE" ] && [ "$LAST" = "$STATE" ] && exit 0
# "pending <fingerprint>" is written before the run and replaced after it, so finding it for this
# tree means the last run was killed, most likely by the hook timeout, which discards the hook's
# output. Say so once, in systemMessage (additionalContext on Stop would keep the turn going), and
# record the tree, so the gate neither hides the kill nor spends another timeout on the same tree.
if [ -n "$STATE" ] && [ "$LAST" = "pending $STATE" ]; then
    { printf '%s\n' "$STATE" > "$CACHE"; } 2>/dev/null
    echo '{"systemMessage": "[test-gate] the last test run on this tree did not finish (hook timeout?); run bash tests/run-all.sh yourself"}'
    exit 0
fi
# Without a record, a continued turn cannot tell whether Claude changed anything, so it may end.
{ printf 'pending %s\n' "$STATE" > "$CACHE"; } 2>/dev/null || { [ "$ACTIVE" = true ] && exit 0; }

# The output goes to a file, not $(...): a background process the suite leaves behind would hold
# the pipe open and keep the turn waiting.
LOG=$(mktemp "${TMPDIR:-/tmp}/claude-test-gate.XXXXXX") || exit 0
trap 'rm -f "$LOG"' EXIT
bash -c "$GATE_CMD" >"$LOG" 2>&1 </dev/null
RC=$?
{ fingerprint > "$CACHE"; } 2>/dev/null   # the suite may have changed the tree (caches, build output)
[ "$RC" -eq 0 ] && exit 0

# Drop color codes, then keep what follows the runner's own "=== Failures ===" header line
OUTPUT=$(sed "s/$(printf '\033')\[[0-9;]*m//g" "$LOG")
SUMMARY=$(printf '%s\n' "$OUTPUT" | awk '$0 == "=== Failures ===" { buf = ""; found = 1 } found { buf = buf $0 "\n" } END { printf "%s", buf }')
[ -n "$SUMMARY" ] || SUMMARY=$(printf '%s\n' "$OUTPUT" | tail -n 40)
printf '%s\n' "$SUMMARY" >&2
echo "[test-gate] tests fail on the current changes; fix the cause, or tell the user why they should stay red. If the failure predates your changes, or you are waiting for the user's answer, say so in one line and end the turn: the gate runs again only after the tree changes." >&2
exit 2
