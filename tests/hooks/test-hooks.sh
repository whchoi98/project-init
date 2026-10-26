#!/bin/bash
# Tests for .claude/hooks/*.sh
# Validates syntax, executability, registration contract, and behavior.
# Sourced by run-all.sh under `set -euo pipefail`: every command that may fail is guarded, and
# hooks are called with an argument or explicit stdin so none of them blocks on a read.

HK_ROOT="$PWD"
HK_HOOKS=(check-doc-sync secret-scan session-context test-gate)

# --- Existence and permissions ---

for hook in "${HK_HOOKS[@]}"; do
    assert_file_exists "$hook.sh exists" ".claude/hooks/$hook.sh"
    assert_file_executable "$hook.sh is executable" ".claude/hooks/$hook.sh"
    assert_bash_syntax "$hook.sh valid bash" ".claude/hooks/$hook.sh"
done

# --- settings.json hook registration ---

assert_file_exists "settings.json exists" ".claude/settings.json"
assert_json_valid "settings.json is valid JSON" ".claude/settings.json"

SETTINGS=$(cat .claude/settings.json)
assert_contains "SessionStart hook registered" "$SETTINGS" "session-context.sh"
assert_contains "PreToolUse hook registered" "$SETTINGS" "secret-scan.sh"
assert_contains "PostToolUse hook registered" "$SETTINGS" "check-doc-sync.sh"
assert_contains "PostToolUse matcher is Write|Edit" "$SETTINGS" "Write|Edit"
assert_contains "Stop hook registered" "$SETTINGS" "test-gate.sh"

# One line per registered command: <event> TAB <matcher> TAB <command>
HK_REGS=$(python3 -c '
import json
hooks = json.load(open(".claude/settings.json")).get("hooks", {})
for event, groups in hooks.items():
    for group in groups:
        for hook in group.get("hooks", []):
            print("%s\t%s\t%s" % (event, group.get("matcher", ""), hook.get("command", "")))
' 2>/dev/null || true)

# hk_check_reg <event> <matcher> <script> <gate|observational>
# A gate must be able to block, so nothing may follow the script path (ADR-004/008). Every command
# resolves the script through $CLAUDE_PROJECT_DIR, because a relative path exits 127 once Claude
# cds into a subdirectory, and a non-2 exit silently opens a gate.
hk_check_reg() {
    local event="$1" matcher="$2" script="$3" kind="$4" cmd desc
    desc="$event${matcher:+ ($matcher)} runs $script"
    cmd=$(awk -F'\t' -v e="$event" -v m="$matcher" -v s="$script" \
        '$1 == e && $2 == m && index($3, s) { print $3; exit }' <<< "$HK_REGS")
    if [ -z "$cmd" ]; then
        fail "$desc" "no matching registration in .claude/settings.json"
        return 0
    fi
    pass "$desc"
    assert_contains "$script registration resolves via \$CLAUDE_PROJECT_DIR" "$cmd" '"$CLAUDE_PROJECT_DIR"/.claude/hooks/'
    if [ "$kind" = gate ]; then
        if [[ "$cmd" == *"$script" ]]; then
            pass "$script gate registered without || true (ADR-004/008)"
        else
            fail "$script gate registered without || true (ADR-004/008)" "command must end at $script, got: $cmd"
        fi
    elif [[ "$cmd" == *" 2>/dev/null || true" ]]; then
        pass "$script observational registration ends with 2>/dev/null || true"
    else
        fail "$script observational registration ends with 2>/dev/null || true" "got: $cmd"
    fi
}
hk_check_reg PreToolUse Bash secret-scan.sh gate
hk_check_reg Stop "" test-gate.sh gate
hk_check_reg PostToolUse "Write|Edit" check-doc-sync.sh observational
hk_check_reg SessionStart "" session-context.sh observational

# --- check-doc-sync.sh behavior ---

hk_doc_sync() { CLAUDE_PROJECT_DIR="$HK_ROOT" bash .claude/hooks/check-doc-sync.sh "$@" 2>&1 || true; }

OUTPUT=$(hk_doc_sync "")
assert_eq "check-doc-sync: empty path produces no output" "" "$OUTPUT"

OUTPUT=$(hk_doc_sync "plugins/new-plugin/commands/foo.md")
assert_contains "check-doc-sync: detects missing CLAUDE.md in plugins/" "$OUTPUT" "CLAUDE.md is missing"
assert_contains "check-doc-sync: names the plugin root, not the subdirectory" "$OUTPUT" "plugins/new-plugin/CLAUDE.md is missing"
EXPECTS_NO_SUBDIR=$(echo "$OUTPUT" | grep -F "commands/CLAUDE.md" || true)
assert_eq "check-doc-sync: never asks for commands/CLAUDE.md" "" "$EXPECTS_NO_SUBDIR"

OUTPUT=$(hk_doc_sync "plugins/project-init/commands/foo.md")
EXPECTS_NO_MISSING=$(echo "$OUTPUT" | grep "CLAUDE.md is missing" || true)
assert_eq "check-doc-sync: no warning for dir with CLAUDE.md" "" "$EXPECTS_NO_MISSING"

OUTPUT=$(hk_doc_sync "plugins/README.md")
assert_eq "check-doc-sync: file directly in plugins/ is silent" "" "$OUTPUT"

# --- stdin JSON contract (ADR-008) ---

OUTPUT=$(echo '{"tool_input":{"file_path":"plugins/new-plugin/commands/foo.md"}}' | hk_doc_sync)
assert_contains "check-doc-sync: reads file_path from stdin JSON" "$OUTPUT" "additionalContext"
assert_contains "check-doc-sync: stdin path reports missing plugin CLAUDE.md" "$OUTPUT" "plugins/new-plugin/CLAUDE.md is missing"

# absolute paths are normalized to repo-relative
OUTPUT=$(echo "{\"tool_input\":{\"file_path\":\"$HK_ROOT/plugins/project-init/commands/foo.md\"}}" | hk_doc_sync)
assert_eq "check-doc-sync: absolute covered path is silent" "" "$OUTPUT"

# the reminder is built with json.dumps, so a quote in the path cannot break it
OUTPUT=$(echo '{"tool_input":{"file_path":"plugins/new\"plugin/x.md"}}' | hk_doc_sync)
HK_CONTEXT=$(printf '%s' "$OUTPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>/dev/null || echo "invalid JSON")
assert_contains "check-doc-sync: output stays valid JSON with a quote in the path" "$HK_CONTEXT" 'plugins/new"plugin/CLAUDE.md is missing'

# hk_doc_sync_json <project dir> <absolute path>: check-doc-sync.sh output for a Write event on <path>
hk_doc_sync_json() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' "$2" |
        CLAUDE_PROJECT_DIR="$1" bash "$HK_ROOT/.claude/hooks/check-doc-sync.sh" 2>&1 || true
}
# In a linked worktree CLAUDE_PROJECT_DIR stays at the main checkout, so the edited path is outside it.
# Scratch repos, so the real plugins/ never changes; git exits early when they cannot be created.
HK_DS_MAIN=$(mktemp -d)
HK_DS_WT="$HK_DS_MAIN/.claude/worktrees/wt1"
(cd "$HK_DS_MAIN" && git init -q && mkdir -p plugins/new-plugin && printf '# x\n' > plugins/new-plugin/CLAUDE.md &&
    printf 'x\n' > README.md && git add README.md &&
    git -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false commit -q --no-verify -m init &&
    git worktree add -q "$HK_DS_WT" && mkdir -p "$HK_DS_WT/plugins/new-plugin/commands") >/dev/null 2>&1 || true
OUTPUT=$(hk_doc_sync_json "$HK_DS_MAIN" "$HK_DS_WT/plugins/new-plugin/commands/foo.md")
assert_contains "check-doc-sync: a worktree edit is checked against the worktree's files" "$OUTPUT" "plugins/new-plugin/CLAUDE.md is missing"
OUTPUT=$(hk_doc_sync_json "$HK_DS_MAIN" "$HK_DS_MAIN/plugins/new-plugin/foo.md")
assert_eq "check-doc-sync: the main checkout's own CLAUDE.md still counts" "" "$OUTPUT"
HK_DS_OTHER=$(mktemp -d)
(cd "$HK_DS_OTHER" && git init -q && mkdir -p plugins/other/commands) >/dev/null 2>&1 || true
OUTPUT=$(hk_doc_sync_json "$HK_DS_MAIN" "$HK_DS_OTHER/plugins/other/commands/foo.md")
assert_eq "check-doc-sync: a file in another repository is silent" "" "$OUTPUT"
rm -rf -- "$HK_DS_MAIN" "$HK_DS_OTHER"   # -f: git objects are read-only, and rm would prompt on a terminal

# --- session-context.sh behavior ---

HK_PLUGIN_VER=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown")
OUTPUT=$(CLAUDE_PROJECT_DIR="$HK_ROOT" bash .claude/hooks/session-context.sh 2>&1 || true)
assert_contains "session-context: prints the plugin.json version" "$OUTPUT" "[project-init] plugin.json version: $HK_PLUGIN_VER"
EXPECTS_NO_GIT=$(echo "$OUTPUT" | grep -E "^(Branch|Last commit|Uncommitted changes):" || true)
assert_eq "session-context: leaves git state to Claude Code's own context" "" "$EXPECTS_NO_GIT"

# drift report, against a fixture tree with a stale README badge and Korean CHANGELOG entry
HK_CTX_TMP=$(mktemp -d)
mkdir -p "$HK_CTX_TMP/.claude-plugin" "$HK_CTX_TMP/plugins/project-init/.claude-plugin"
printf '{"version": "2.0.0"}\n' > "$HK_CTX_TMP/plugins/project-init/.claude-plugin/plugin.json"
printf '{"metadata": {"version": "2.0.0"}, "plugins": [{"version": "2.0.0"}]}\n' > "$HK_CTX_TMP/.claude-plugin/marketplace.json"
printf '[![Version](https://img.shields.io/badge/version-1.9.0-green.svg)](x)\n' > "$HK_CTX_TMP/README.md"
printf '<a id="english"></a>\n# English\n## [Unreleased]\n## [2.0.0] - 2026-01-02\n<a id="korean"></a>\n# 한국어\n## [Unreleased]\n## [1.9.0] - 2026-01-01\n' > "$HK_CTX_TMP/CHANGELOG.md"
OUTPUT=$(CLAUDE_PROJECT_DIR="$HK_CTX_TMP" bash .claude/hooks/session-context.sh 2>&1 || true)
assert_contains "session-context: reports version drift" "$OUTPUT" "version drift (plugin.json=2.0.0)"
assert_contains "session-context: drift names the README badge" "$OUTPUT" "README version badge=1.9.0"
assert_contains "session-context: drift names the Korean CHANGELOG release" "$OUTPUT" "CHANGELOG Korean latest release=1.9.0"
EXPECTS_NO_SYNCED=$(echo "$OUTPUT" | grep -F -e "metadata.version=" -e "English latest release=" || true)
assert_eq "session-context: drift omits sources that match" "" "$EXPECTS_NO_SYNCED"
printf '[![Version](https://img.shields.io/badge/version-2.0.0-green.svg)](x)\n' > "$HK_CTX_TMP/README.md"
printf '<a id="english"></a>\n# English\n## [2.0.0] - 2026-01-02\n<a id="korean"></a>\n# 한국어\n## [2.0.0] - 2026-01-02\n' > "$HK_CTX_TMP/CHANGELOG.md"
OUTPUT=$(CLAUDE_PROJECT_DIR="$HK_CTX_TMP" bash .claude/hooks/session-context.sh 2>&1 || true)
EXPECTS_NO_DRIFT=$(echo "$OUTPUT" | grep -F "version drift" || true)
assert_eq "session-context: no drift line when every version matches" "" "$EXPECTS_NO_DRIFT"
rm -rf -- "$HK_CTX_TMP"

# --- secret-scan.sh behavior ---

# secret-scan only gates git commit
OUTPUT=$(echo '{"tool_input":{"command":"ls -la"}}' | bash .claude/hooks/secret-scan.sh 2>&1; echo "exit=$?")
assert_eq "secret-scan: non-commit command passes with exit 0" "exit=0" "$OUTPUT"

# Sample key built at runtime so this file never matches the scan itself (tests/CLAUDE.md).
HK_AWS_ID="AKIA""IOSFODNN7EXAMPLE"

# hk_repo: print the path of a fresh repo whose only commit holds a clean cfg.py.
# It fails loudly rather than fall back to the current directory, which is the real repo.
hk_repo() {
    local dir
    dir=$(mktemp -d) && [ -d "$dir" ] || return 1
    (
        cd "$dir" && git init -q && printf 'x = 1\n' > cfg.py && git add cfg.py &&
            git -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false \
                commit -q --no-verify -m init
    ) >/dev/null 2>&1 || true
    printf '%s\n' "$dir"
}
# hk_scan_rc <repo> <command>: exit code of secret-scan.sh for that Bash command, run from <repo>
# (`&& ... || echo $?` keeps the runner's `set -e` from aborting on the expected exit 2)
hk_scan_rc() {
    local json
    json=$(python3 -c 'import json,sys; print(json.dumps({"tool_input": {"command": sys.argv[1]}}))' "$2")
    ( cd "$1" && printf '%s' "$json" | bash "$HK_ROOT/.claude/hooks/secret-scan.sh" >/dev/null 2>&1 ) && echo 0 || echo $?
}

HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
(cd "$HK_REPO" && git add cfg.py) || true
assert_eq "secret-scan: staged secret blocks commit with exit 2" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m test")"
assert_eq "secret-scan: git -C . commit is gated too" "2" "$(hk_scan_rc "$HK_REPO" "git -C . commit -m x")"
assert_eq "secret-scan: non-commit command with a staged secret passes" "0" "$(hk_scan_rc "$HK_REPO" "git status")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/new.py"
assert_eq "secret-scan: chained git add && git commit is scanned" "2" "$(hk_scan_rc "$HK_REPO" "git add new.py && git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
assert_eq "secret-scan: commit -am scans modified tracked files" "2" "$(hk_scan_rc "$HK_REPO" "git commit -am x")"
assert_eq "secret-scan: plain commit ignores unstaged changes" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# the skip list is path-aware: the hook's own pattern definitions are skipped only at its own path
HK_REPO=$(hk_repo)
mkdir -p "$HK_REPO/.claude/hooks"
cp .claude/hooks/secret-scan.sh "$HK_REPO/.claude/hooks/secret-scan.sh"
(cd "$HK_REPO" && git add .claude/hooks/secret-scan.sh) || true
assert_eq "secret-scan: staging .claude/hooks/secret-scan.sh itself passes" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
cp .claude/hooks/secret-scan.sh "$HK_REPO/copy.sh"
(cd "$HK_REPO" && git add copy.sh) || true
assert_eq "secret-scan: the same content at another path is scanned" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

hk_commit() { git -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false commit -q --no-verify "$@"; }
# hk_scan_out <dir> <command>: stdout of secret-scan.sh for that Bash command, run from <dir>
hk_scan_out() {
    local json
    json=$(python3 -c 'import json,sys; print(json.dumps({"tool_input": {"command": sys.argv[1]}}))' "$2")
    ( cd "$1" && printf '%s' "$json" | bash "$HK_ROOT/.claude/hooks/secret-scan.sh" 2>/dev/null ) || true
}

# renames (git reports R once the new file is mostly the old one) and type changes are scanned
HK_REPO=$(hk_repo)
(cd "$HK_REPO" && seq 1 40 > big.py && git add big.py && hk_commit -m big && git mv big.py moved.py &&
    printf 'key = "%s"\n' "$HK_AWS_ID" >> moved.py && git add moved.py) >/dev/null 2>&1 || true
assert_eq "secret-scan: a staged rename that adds a secret blocks" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal
HK_REPO=$(hk_repo)
(cd "$HK_REPO" && git mv cfg.py moved.py) >/dev/null 2>&1 || true
assert_eq "secret-scan: a clean rename passes" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal
HK_REPO=$(hk_repo)
(cd "$HK_REPO" && ln -s cfg.py link.py && git add link.py && hk_commit -m link && rm link.py &&
    printf 'key = "%s"\n' "$HK_AWS_ID" > link.py && git add link.py) >/dev/null 2>&1 || true
assert_eq "secret-scan: a symlink replaced by a file with a secret blocks" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# quoted and spaced git options still count as a commit
HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
(cd "$HK_REPO" && git add cfg.py) || true
assert_eq "secret-scan: git -c user.name=\"Claude Code\" commit is gated" "2" \
    "$(hk_scan_rc "$HK_REPO" 'git -c user.name="Claude Code" -c user.email=noreply@anthropic.com commit -m "init"')"
assert_eq "secret-scan: git -c \"k=v w\" commit is gated" "2" "$(hk_scan_rc "$HK_REPO" 'git -c "user.name=a b" commit -m x')"
assert_eq "secret-scan: git --git-dir .git commit is gated" "2" "$(hk_scan_rc "$HK_REPO" 'git --git-dir .git commit -m x')"
assert_eq "secret-scan: git log --grep \"commit\" is not a commit" "0" "$(hk_scan_rc "$HK_REPO" 'git -c x=y log --grep "commit"')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# a repo reached through cd or a quoted -C, from a directory that holds several repos
HK_WS=$(mktemp -d)
for hk_dir in "my repo" sub; do
    (cd "$HK_WS" && mkdir "$hk_dir" && cd "$hk_dir" && git init -q &&
        printf 'key = "%s"\n' "$HK_AWS_ID" > cfg.py && git add cfg.py) >/dev/null 2>&1 || true
done
assert_eq "secret-scan: git -C \"my repo\" commit scans that repo" "2" "$(hk_scan_rc "$HK_WS" 'git -C "my repo" commit -m x')"
assert_eq "secret-scan: git -C my\\ repo commit scans that repo" "2" "$(hk_scan_rc "$HK_WS" 'git -C my\ repo commit -m x')"
assert_eq "secret-scan: cd \"my repo\" && git commit scans that repo" "2" "$(hk_scan_rc "$HK_WS" 'cd "my repo" && git commit -m x')"
# cd options are not the directory (chdir("-P") would land in $HOME)
assert_eq "secret-scan: cd -P sub && git commit scans that repo" "2" "$(hk_scan_rc "$HK_WS" 'cd -P sub && git commit -m x')"
assert_eq "secret-scan: cd -- sub && git commit scans that repo" "2" "$(hk_scan_rc "$HK_WS" 'cd -- sub && git commit -m x')"
if git -C "$HK_WS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    skip "secret-scan: unknown repo reported as unscanned" "the temp directory is inside a git work tree"
else
    HK_OUT=$(hk_scan_out "$HK_WS" 'cd "$REPO" && git commit -m x')
    assert_contains "secret-scan: an unknown repo (\$REPO) is reported as unscanned" "$HK_OUT" "could not find the repository"
    assert_eq "secret-scan: echo git commit outside a repo stays silent" "" "$(hk_scan_out "$HK_WS" 'echo git commit')"
fi
rm -rf -- "$HK_WS"   # -f: git objects are read-only, and rm would prompt on a terminal

# a ; inside a quoted message does not end the commit's arguments
HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
assert_eq "secret-scan: git commit -m \"a; b\" -a scans modified tracked files" "2" \
    "$(hk_scan_rc "$HK_REPO" 'git commit -m "Update config; add key" -a')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# git stage, and git add -f of an ignored file, on the commit's line
HK_REPO=$(hk_repo)
printf '.env\n' > "$HK_REPO/.gitignore"
printf 'KEY="%s"\n' "$HK_AWS_ID" > "$HK_REPO/.env"
assert_eq "secret-scan: git add -f .env && git commit blocks" "2" "$(hk_scan_rc "$HK_REPO" 'git add -f .env && git commit -m x')"
assert_eq "secret-scan: git add -f of another file leaves ignored .env alone" "0" \
    "$(hk_scan_rc "$HK_REPO" 'git add -f cfg.py && git commit -m x')"
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/new.py"
assert_eq "secret-scan: git stage new.py && git commit blocks" "2" "$(hk_scan_rc "$HK_REPO" 'git stage new.py && git commit -m x')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# git add -f resolves its paths where that add runs: its own -C, or a cd the line undoes before the commit
HK_REPO=$(hk_repo)
mkdir -p "$HK_REPO/sub"
printf 'sub/.env\n' > "$HK_REPO/.gitignore"
printf 'KEY="%s"\n' "$HK_AWS_ID" > "$HK_REPO/sub/.env"
assert_eq "secret-scan: git -C sub add -f .env && git commit blocks" "2" "$(hk_scan_rc "$HK_REPO" 'git -C sub add -f .env && git commit -m x')"
assert_eq "secret-scan: cd sub && git add -f .env && cd .. && git commit blocks" "2" \
    "$(hk_scan_rc "$HK_REPO" 'cd sub && git add -f .env && cd .. && git commit -m x')"
assert_eq "secret-scan: git -C sub add -f of another file leaves sub/.env alone" "0" \
    "$(hk_scan_rc "$HK_REPO" 'git -C sub add -f ../cfg.py && git commit -m x')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# pathspecs: a glob, quoted or not, is matched by git; a path outside the repository drops only itself
HK_REPO=$(hk_repo)
HK_OTHER=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
assert_eq "secret-scan: git commit *.py (a glob) scans the matching files" "2" "$(hk_scan_rc "$HK_REPO" 'git commit -m x *.py')"
assert_eq "secret-scan: git commit -- '*.py' scans the matching files" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x -- '*.py'")"
assert_eq "secret-scan: a pathspec outside the repository does not drop the others" "2" \
    "$(hk_scan_rc "$HK_REPO" "git commit -m x '$HK_OTHER/cfg.py' cfg.py")"
assert_eq "secret-scan: a glob that matches no changed file passes" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x -- '*.txt'")"
rm -rf -- "$HK_REPO" "$HK_OTHER"   # -f: git objects are read-only, and rm would prompt on a terminal

# paths git would print quoted; CLAUDE.md despite '*.md'; tests/fixtures beyond the two sample files
HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/we\"ird.txt"
(cd "$HK_REPO" && git add .) || true
assert_eq "secret-scan: a file name with a quote is scanned" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal
HK_REPO=$(hk_repo)
mkdir -p "$HK_REPO/docs"
printf 'key %s\n' "$HK_AWS_ID" > "$HK_REPO/docs/README.md"
(cd "$HK_REPO" && git add docs) || true
assert_eq "secret-scan: other Markdown stays skipped" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
printf 'key %s\n' "$HK_AWS_ID" > "$HK_REPO/docs/CLAUDE.md"
(cd "$HK_REPO" && git add docs) || true
assert_eq "secret-scan: a CLAUDE.md with a secret blocks" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal
HK_REPO=$(hk_repo)
mkdir -p "$HK_REPO/tests/fixtures"
printf 'key %s\n' "$HK_AWS_ID" > "$HK_REPO/tests/fixtures/secret-samples.txt"
(cd "$HK_REPO" && git add tests) || true
assert_eq "secret-scan: tests/fixtures/secret-samples.txt is skipped" "0" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
printf 'Authorization: %s\n' "$HK_AWS_ID" > "$HK_REPO/tests/fixtures/cassette.yaml"
(cd "$HK_REPO" && git add tests) || true
assert_eq "secret-scan: other files under tests/fixtures are scanned" "2" "$(hk_scan_rc "$HK_REPO" "git commit -m x")"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# a project in a subdirectory of its repo: SKIP_PATTERNS also match project-relative paths
HK_REPO=$(hk_repo)
mkdir -p "$HK_REPO/services/api/tests/fixtures"
printf 'key %s\n' "$HK_AWS_ID" > "$HK_REPO/services/api/tests/fixtures/secret-samples.txt"
(cd "$HK_REPO" && git add services) || true
hk_sub_rc() {
    ( cd "$HK_REPO/services/api" && printf '%s' '{"tool_input":{"command":"git commit -m x"}}' |
        CLAUDE_PROJECT_DIR="$HK_REPO/services/api" bash "$HK_ROOT/.claude/hooks/secret-scan.sh" >/dev/null 2>&1 ) && echo 0 || echo $?
}
assert_eq "secret-scan: project-relative skip in a monorepo package" "0" "$(hk_sub_rc)"
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/services/api/cfg.py"
(cd "$HK_REPO" && git add services) || true
assert_eq "secret-scan: a secret in the monorepo package still blocks" "2" "$(hk_sub_rc)"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# without a working python3 the commit goes through, with a warning the user and Claude can see
HK_REPO=$(hk_repo)
printf 'key = "%s"\n' "$HK_AWS_ID" > "$HK_REPO/cfg.py"
(cd "$HK_REPO" && git add cfg.py) || true
HK_BIN=$(mktemp -d)
mkdir -p "$HK_BIN/none" "$HK_BIN/stub"
for hk_tool in git cat tr; do
    ln -s "$(command -v "$hk_tool")" "$HK_BIN/none/$hk_tool" 2>/dev/null || true
    ln -s "$(command -v "$hk_tool")" "$HK_BIN/stub/$hk_tool" 2>/dev/null || true
done
printf '#!/bin/sh\nexit 49\n' > "$HK_BIN/stub/python3"   # like a Windows Store alias: on PATH, never runs
chmod +x "$HK_BIN/stub/python3"
for hk_case in none stub; do
    HK_OUT=$( (cd "$HK_REPO" && printf '%s' '{"tool_input":{"command":"git commit -m x"}}' |
        PATH="$HK_BIN/$hk_case" "$BASH" "$HK_ROOT/.claude/hooks/secret-scan.sh" 2>/dev/null; echo "exit=$?") || true)
    assert_contains "secret-scan: python3 $hk_case: commit goes through" "$HK_OUT" "exit=0"
    HK_MSG=$(printf '%s' "${HK_OUT%exit=*}" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(d["systemMessage"], "|", d["hookSpecificOutput"]["additionalContext"])' 2>/dev/null || echo "no JSON warning")
    assert_contains "secret-scan: python3 $hk_case: warning reaches the user and Claude" "$HK_MSG" "not scanned for secrets"
done
rm -rf -- "$HK_REPO" "$HK_BIN"   # -f: git objects are read-only, and rm would prompt on a terminal

# harness-check's committed-secret audit (SECRET_RES, grep -E) and this gate must agree: every token
# shape the audit flags has a sample here, and the gate blocks each sample the audit flags
HK_A=$(printf 'A%.0s' {1..90})
HK_B64URL=$(printf 'aB3_x-Y9%.0s' {1..12})
HK_TOKENS="$HK_AWS_ID
aws_secret_access""_key = wJalrXUtnFEMI/K7MDENG/""bPxRfiCYEXAMPLEKEY
sk-ant-""api03-${HK_B64URL}AA
sk-""proj-${HK_B64URL}
sk-""svcacct-${HK_B64URL}
sk-""admin-${HK_B64URL}
sk-${HK_A:0:20}T3Blbk""FJ${HK_A:0:20}
ghp""_${HK_A:0:36}
gho""_${HK_A:0:36}
github""_pat_${HK_A:0:82}
xox""b-123456789012-abcdef
xox""p-123456789012-abcdef
sk""_live_${HK_A:0:24}
rk""_live_${HK_A:0:24}
AI""za${HK_A:0:35}
ya""29.${HK_A:0:50}
DefaultEndpoints""Protocol=https;AccountName=x
-----BEGIN RSA PRIV""ATE KEY-----
-----BEGIN OPENSSH PRIV""ATE KEY-----
-----BEGIN PGP PRIV""ATE KEY BLOCK-----"
HK_PATTERNS=$(bash -c "$(sed -n '/^PATTERNS=(/,/^)/p' .claude/hooks/secret-scan.sh)"'
printf "%s\n" "${PATTERNS[@]}"' 2>/dev/null || true)
HK_SECRET_RES=$(bash -c "$(sed -n '/^SECRET_RES=/,/^$/p' plugins/project-init/scripts/harness-check.sh)"'
printf "%s\n" "$SECRET_RES"' 2>/dev/null || true)
HK_XCHECK=$(python3 -c '
import re, subprocess, sys
patterns = [p for p in sys.argv[1].split("\n") if p]
audit = [p for p in sys.argv[2].split("\n") if p]
samples = sys.argv[3].split("\n")
problems = [] if audit else ["no SECRET_RES found in harness-check.sh"]
for entry in audit:
    out = subprocess.run(["grep", "-nE", "-e", entry], input="\n".join(samples).encode(),
                         stdout=subprocess.PIPE).stdout.decode()
    hits = [samples[int(line.split(":", 1)[0]) - 1] for line in out.splitlines()]
    if not hits:
        problems.append("add a sample for SECRET_RES entry %s" % entry)
    for sample in hits:
        if not any(re.search(p, sample) for p in patterns):
            problems.append("the gate misses what SECRET_RES entry %s flags" % entry)
print("; ".join(sorted(set(problems))))
' "$HK_PATTERNS" "$HK_SECRET_RES" "$HK_TOKENS" 2>&1 || true)
assert_eq "secret-scan: blocks every token shape harness-check's SECRET_RES flags" "" "$HK_XCHECK"

# --- test-gate.sh behavior (TEST_GATE_CMD stands in for the suite, so it never runs itself) ---

HK_GATE_TMP=$(mktemp -d)   # TMPDIR for the gate's fingerprint cache, so no test leaves files in /tmp
# hk_gate_rc <repo> <stdin> <gate command>: exit code of test-gate.sh with <repo> as the project
hk_gate_rc() {
    ( cd "$1" && printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" TMPDIR="$HK_GATE_TMP" TEST_GATE_CMD="$3" \
        bash "$HK_ROOT/.claude/hooks/test-gate.sh" >/dev/null 2>&1 ) && echo 0 || echo $?
}
# hk_gate_cwd_rc <project dir> <event cwd> <gate command>: the same, with "cwd" in the event JSON
hk_gate_cwd_rc() {
    local json
    json=$(python3 -c 'import json,sys; print(json.dumps({"cwd": sys.argv[1], "stop_hook_active": False}))' "$2")
    hk_gate_rc "$1" "$json" "$3"
}
HK_RUNS="$HK_GATE_TMP/runs"
HK_COUNTED="echo run >> '$HK_RUNS'; true"   # a passing suite that counts its runs

HK_REPO=$(hk_repo)
assert_eq "test-gate: clean tree skips the suite" "0" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": false}' false)"
printf 'y = 2\n' > "$HK_REPO/new.py"
assert_eq "test-gate: failing suite on a changed tree blocks with exit 2" "2" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": false}' false)"
assert_eq "test-gate: stop_hook_active on an unchanged tree lets the turn end" "0" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": true}' false)"
assert_eq "test-gate: an unchanged red tree is not blocked again on the next prompt" "0" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": false}' false)"
printf 'y = 3\n' > "$HK_REPO/new.py"
assert_eq "test-gate: stop_hook_active after a change runs the suite again" "2" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": true}' false)"
printf 'y = 4\n' > "$HK_REPO/new.py"
assert_eq "test-gate: passing suite lets the turn end" "0" "$(hk_gate_rc "$HK_REPO" '{"stop_hook_active": true}' "$HK_COUNTED")"
hk_gate_rc "$HK_REPO" '{"stop_hook_active": false}' "$HK_COUNTED" >/dev/null
assert_eq "test-gate: an unchanged tree after a green run is skipped" "1" "$( (wc -l < "$HK_RUNS") 2>/dev/null | tr -d ' ')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# a long, colored run like the real suite's (the summary step must stay fast on large output)
HK_REPO=$(hk_repo)
printf 'y = 2\n' > "$HK_REPO/new.py"
HK_NOISY='printf "  + a case whose name mentions === Failures ===\n"
for i in $(seq 1 3000); do printf "\033[0;32m+\033[0m case %s\n" "$i"; done
printf "\033[0;31m=== Failures ===\033[0m\n  case-a: broke\n"; false'
OUTPUT=$( (cd "$HK_REPO" && printf '{}' | CLAUDE_PROJECT_DIR="$HK_REPO" TMPDIR="$HK_GATE_TMP" TEST_GATE_CMD="$HK_NOISY" \
    bash "$HK_ROOT/.claude/hooks/test-gate.sh" 2>&1 >/dev/null) || true)
assert_contains "test-gate: reports the failure summary" "$OUTPUT" "case-a: broke"
assert_contains "test-gate: tells Claude what to do next" "$OUTPUT" "[test-gate] tests fail on the current changes"
EXPECTS_NO_PASSES=$(echo "$OUTPUT" | grep -F -e "case 3000" -e "whose name mentions" || true)
assert_eq "test-gate: sends only the runner's failure summary" "" "$EXPECTS_NO_PASSES"
if [[ "$OUTPUT" == *$'\e'* ]]; then
    fail "test-gate: strips color codes" "stderr still contains escape sequences"
else
    pass "test-gate: strips color codes"
fi
# a process the suite leaves in the background does not hold the turn open
printf 'y = 3\n' > "$HK_REPO/new.py"
HK_START=$SECONDS
hk_gate_rc "$HK_REPO" '{}' '(sleep 5 &); true' >/dev/null
if [ $((SECONDS - HK_START)) -lt 4 ]; then
    pass "test-gate: does not wait for a background process the suite leaves behind"
else
    fail "test-gate: does not wait for a background process the suite leaves behind" "took $((SECONDS - HK_START))s"
fi
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# A run the hook timeout kills leaves "pending <fingerprint>" in the cache. The next Stop on that tree
# says so once, in systemMessage only (additionalContext would keep the turn going), and does not
# run the suite again. The kill is simulated by writing the marker into the cache.
HK_REPO=$(hk_repo)
printf 'y = 2\n' > "$HK_REPO/new.py"
HK_KILL_TMP="$HK_GATE_TMP/killed"
mkdir -p "$HK_KILL_TMP"
HK_PEEK="cat \"\$TMPDIR\"/claude-test-gate-* > '$HK_GATE_TMP/during'; echo run >> '$HK_GATE_TMP/peek-runs'"
# hk_peek_gate: stdout of test-gate.sh with HK_PEEK as the suite, then "exit=<code>"
hk_peek_gate() {
    ( cd "$HK_REPO" && printf '{}' | CLAUDE_PROJECT_DIR="$HK_REPO" TMPDIR="$HK_KILL_TMP" TEST_GATE_CMD="$HK_PEEK" \
        bash "$HK_ROOT/.claude/hooks/test-gate.sh" 2>/dev/null; echo "exit=$?" ) || true
}
hk_peek_gate >/dev/null
assert_contains "test-gate: marks the tree pending while the suite runs" "$(cat "$HK_GATE_TMP/during" 2>/dev/null || true)" "pending "
HK_CACHE_FILE=""
for hk_f in "$HK_KILL_TMP"/claude-test-gate-*; do [ -f "$hk_f" ] && HK_CACHE_FILE="$hk_f"; done
HK_STATE=$(cat "$HK_CACHE_FILE" 2>/dev/null || true)
if [ -n "$HK_STATE" ] && [[ "$HK_STATE" != pending* ]]; then
    pass "test-gate: a finished run replaces the pending mark with the fingerprint"
else
    fail "test-gate: a finished run replaces the pending mark with the fingerprint" "cache holds '$HK_STATE'"
fi
printf 'pending %s\n' "$HK_STATE" > "${HK_CACHE_FILE:-$HK_KILL_TMP/none}" 2>/dev/null || true
rm -f "$HK_GATE_TMP/peek-runs"
HK_OUT=$(hk_peek_gate)
assert_contains "test-gate: after a killed run the turn ends" "$HK_OUT" "exit=0"
HK_MSG=$(printf '%s' "${HK_OUT%exit=*}" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(",".join(sorted(d)), "|", d["systemMessage"])' 2>/dev/null || echo "no JSON systemMessage")
assert_contains "test-gate: a killed run is reported in systemMessage" "$HK_MSG" "did not finish (hook timeout?)"
assert_contains "test-gate: the report carries no additionalContext or decision" "$HK_MSG" "systemMessage |"
assert_eq "test-gate: a killed run is not rerun on the same tree" "no" "$([ -f "$HK_GATE_TMP/peek-runs" ] && echo yes || echo no)"
assert_eq "test-gate: a killed run is reported once" "exit=0" "$(hk_peek_gate)"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# untracked directory entries (a nested repository) and a dangling symlink do not end the fingerprint
# early, so a later untracked file still counts as a change
HK_REPO=$(hk_repo)
(cd "$HK_REPO" && mkdir -p vendor/lib && cd vendor/lib && git init -q && printf 'v\n' > v.txt) >/dev/null 2>&1 || true
(cd "$HK_REPO" && ln -s missing dangling) 2>/dev/null || true
printf 'ok\n' > "$HK_REPO/zz.py"
assert_eq "test-gate: green run beside a nested repository" "0" "$(hk_gate_rc "$HK_REPO" '{}' 'grep -q ok zz.py')"
printf 'bad\n' > "$HK_REPO/zz.py"
assert_eq "test-gate: an untracked file listed after a nested repository still counts as a change" "2" \
    "$(hk_gate_rc "$HK_REPO" '{}' 'grep -q ok zz.py')"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

# the event's cwd follows Claude into a linked worktree, while CLAUDE_PROJECT_DIR stays at the main
# checkout; a cwd in another repository is ignored
HK_REPO=$(hk_repo)
HK_WT="$HK_REPO/.claude/worktrees/wt1"
(cd "$HK_REPO" && git worktree add -q "$HK_WT" && printf '.claude/worktrees/\n' >> .git/info/exclude) >/dev/null 2>&1 || true
printf 'BROKEN\n' > "$HK_WT/cfg.py"
mkdir -p "$HK_WT/src"
assert_eq "test-gate: a red linked worktree (event cwd) blocks" "2" "$(hk_gate_cwd_rc "$HK_REPO" "$HK_WT" '! grep -q BROKEN cfg.py')"
assert_eq "test-gate: a cwd below the worktree root checks that worktree" "2" "$(hk_gate_cwd_rc "$HK_REPO" "$HK_WT/src" 'grep -qv BROKEN cfg.py')"
HK_OTHER=$(hk_repo)
printf 'BROKEN\n' > "$HK_OTHER/cfg.py"
assert_eq "test-gate: a cwd in another repository falls back to the project" "0" "$(hk_gate_cwd_rc "$HK_REPO" "$HK_OTHER" '! grep -q BROKEN cfg.py')"
rm -rf -- "$HK_REPO" "$HK_OTHER" "$HK_GATE_TMP"   # -f: git objects are read-only, and rm would prompt on a terminal

# --- scripts/install-hooks.sh and the commit-msg hook it installs ---

# A global or system core.hooksPath would redirect git's hooks, so these runs see only the repo's config
HK_IH_HOME=$(mktemp -d)
hk_isolated() { HOME="$HK_IH_HOME" XDG_CONFIG_HOME="$HK_IH_HOME" GIT_CONFIG_NOSYSTEM=1 "$@"; }
# hk_install_rc <repo>: exit code of scripts/install-hooks.sh run from <repo>
hk_install_rc() { ( cd "$1" && hk_isolated bash "$HK_ROOT/scripts/install-hooks.sh" >/dev/null 2>&1 ) && echo 0 || echo $?; }
# hk_trailer_commit <repo>: commit with Co-Authored-By trailers, through the hooks (no --no-verify)
hk_trailer_commit() {
    ( cd "$1" && printf 'z\n' >> z.txt && git add z.txt &&
        printf 'subject\n\nbody\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nco-authored-by: B <b@example.invalid>\n' |
        hk_isolated git -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false commit -q -F - ) >/dev/null 2>&1 || true
}
HK_REPO=$(hk_repo)
assert_eq "install-hooks: installs into a fresh repository" "0" "$(hk_install_rc "$HK_REPO")"
HK_HOOK="$HK_REPO/.git/hooks/commit-msg"
assert_file_executable "install-hooks: commit-msg hook is executable" "$HK_HOOK"
HK_SED_I=$(grep -v '^[[:space:]]*#' "$HK_HOOK" 2>/dev/null | grep -E "sed[[:space:]]+(-[A-Za-z]*[[:space:]]+)*-i([[:space:]\"']|$)" || true)
assert_eq "install-hooks: commit-msg hook avoids GNU-only 'sed -i' (fails on macOS)" "" "$HK_SED_I"
hk_trailer_commit "$HK_REPO"
HK_BODY=$(git -C "$HK_REPO" log -1 --format=%B 2>/dev/null || true)
assert_contains "install-hooks: the commit still goes through" "$HK_BODY" "body"
EXPECTS_NO_TRAILER=$(printf '%s\n' "$HK_BODY" | grep -i "co-authored-by" || true)
assert_eq "install-hooks: commit-msg removes Co-Authored-By lines in any case" "" "$EXPECTS_NO_TRAILER"
assert_eq "install-hooks: commit-msg runs with /bin/sh, since /bin/bash is missing on some systems" "#!/bin/sh" \
    "$(sed -n 1p "$HK_HOOK" 2>/dev/null || true)"
assert_contains "install-hooks: commit-msg carries the project-init marker" "$(cat "$HK_HOOK" 2>/dev/null || true)" "# project-init:commit-msg"
assert_eq "install-hooks: a rerun replaces its own hook" "0" "$(hk_install_rc "$HK_REPO")"
HK_WT="$HK_REPO/wt"
(cd "$HK_REPO" && git worktree add -q "$HK_WT") >/dev/null 2>&1 || true
rm -f "$HK_HOOK"
assert_eq "install-hooks: works from a linked worktree (.git is a file)" "0" "$(hk_install_rc "$HK_WT")"
assert_file_exists "install-hooks: a worktree install lands in the shared hooks directory" "$HK_HOOK"
rm -rf -- "$HK_REPO"   # -f: git objects are read-only, and rm would prompt on a terminal

HK_REPO=$(hk_repo)
git -C "$HK_REPO" config core.hooksPath .husky 2>/dev/null || true
assert_eq "install-hooks: core.hooksPath set by a hook manager exits 1" "1" "$(hk_install_rc "$HK_REPO")"
HK_WROTE=$( { [ -e "$HK_REPO/.git/hooks/commit-msg" ] || [ -e "$HK_REPO/.husky" ]; } && echo yes || echo no)
assert_eq "install-hooks: writes nothing git would ignore or a hook manager owns" "no" "$HK_WROTE"
git -C "$HK_REPO" config --unset core.hooksPath 2>/dev/null || true
printf '#!/bin/sh\n# add Change-Id\nexit 0\n' > "$HK_REPO/.git/hooks/commit-msg"
assert_eq "install-hooks: another commit-msg hook exits 1" "1" "$(hk_install_rc "$HK_REPO")"
assert_contains "install-hooks: another commit-msg hook is left unchanged" "$(cat "$HK_REPO/.git/hooks/commit-msg")" "add Change-Id"
# the unmarked body earlier releases installed is replaced; a hook that adds a trailer, or that old
# body plus a line of the user's own, is not
HK_OLD_BODY="$HK_IH_HOME/old-commit-msg"
cat > "$HK_OLD_BODY" << 'HK_OLD' || true
#!/bin/bash
# Remove Co-Authored-By lines from commit messages.
# Prevents Claude and other AI assistants from appearing as contributors.
sed -i '/^[Cc]o-[Aa]uthored-[Bb]y:.*/d' "$1"
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$1"
HK_OLD
cp "$HK_OLD_BODY" "$HK_REPO/.git/hooks/commit-msg" 2>/dev/null || true
assert_eq "install-hooks: the unmarked body of earlier releases is replaced" "0" "$(hk_install_rc "$HK_REPO")"
assert_contains "install-hooks: the replacement carries the marker" "$(cat "$HK_REPO/.git/hooks/commit-msg" 2>/dev/null || true)" "project-init:commit-msg"
{ cat "$HK_OLD_BODY"; printf 'echo my own step\n'; } > "$HK_REPO/.git/hooks/commit-msg" 2>/dev/null || true
assert_eq "install-hooks: the old body with a line of the user's own exits 1" "1" "$(hk_install_rc "$HK_REPO")"
printf '#!/bin/sh\necho "Co-authored-by: Pair <pair@example.invalid>" >> "$1"\n' > "$HK_REPO/.git/hooks/commit-msg" 2>/dev/null || true
assert_eq "install-hooks: a hook that adds a Co-authored-by trailer exits 1" "1" "$(hk_install_rc "$HK_REPO")"
assert_contains "install-hooks: a hook that adds a trailer is left unchanged" "$(cat "$HK_REPO/.git/hooks/commit-msg" 2>/dev/null || true)" "Pair <pair@example.invalid>"
rm -rf -- "$HK_REPO" "$HK_IH_HOME"   # -f: git objects are read-only, and rm would prompt on a terminal

# the consumer templates carry the same scripts: scripts-templates.md `## install-hooks.sh` is this
# repo's scripts/install-hooks.sh, and hook-scripts.md `## Git commit-msg Hook (Core)` is its hook body
HK_TPL_SYNC=$(python3 -c '
import re, sys
ref = sys.argv[1]
def block(name, heading):
    text = open("%s/%s" % (ref, name), encoding="utf-8").read()
    m = re.search("^" + re.escape(heading) + r"\n.*?^```bash\n(.*?)^```$", text, re.S | re.M)
    return m.group(1) if m else None
script = open("scripts/install-hooks.sh", encoding="utf-8").read()
body = re.search(r"<< .HOOK.\n(.*?)^HOOK$", script, re.S | re.M)
problems = []
if block("scripts-templates.md", "## install-hooks.sh") != script:
    problems.append("scripts-templates.md \"## install-hooks.sh\" differs from scripts/install-hooks.sh")
if not body or block("hook-scripts.md", "## Git commit-msg Hook (Core)") != body.group(1):
    problems.append("hook-scripts.md \"## Git commit-msg Hook (Core)\" differs from the hook install-hooks.sh writes")
print("; ".join(problems))
' "plugins/project-init/skills/project-scaffolder/references" 2>&1 || true)
assert_eq "install-hooks: templates match scripts/install-hooks.sh and its hook body" "" "$HK_TPL_SYNC"
