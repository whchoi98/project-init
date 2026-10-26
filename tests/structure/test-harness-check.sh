#!/bin/bash
# Tests for plugins/project-init/scripts/harness-check.sh, the deterministic half of
# /project-init:health-check and the detector behind /project-init:migrate-hooks.
#
# Fixture projects are built in mktemp: a generated skeleton (CLAUDE.md, docs, scripts, tests,
# /review, /test-all, code-reviewer) plus the hook and settings files of one version from
# tests/fixtures/harness-check/:
#   current/  $CLAUDE_PROJECT_DIR registrations, the commit-scope and module-coverage markers (healthy)
#   v2.4/     the v2.3-v2.4 templates: relative registrations, no commit-scope or module-coverage marker
#   v2.2/     the pre-v2.3 templates: env-var arguments, a `|| true` gate, exit 1, a .yml agent
# The skeleton is generated rather than committed because it holds test-*.sh files, which
# run-all.sh would source, and CLAUDE.md files, which this repo's doc tooling would count.
#
# Sourced by run-all.sh under `set -euo pipefail`: every command that may fail is guarded, and
# every helper returns 0.

HC_SCRIPT="$PWD/plugins/project-init/scripts/harness-check.sh"
HC_FIX="$PWD/tests/fixtures/harness-check"
HC_TMP=$(mktemp -d)
HC_CHECK_RE='^(PASS|FAIL|WARN|INFO|SKIP) [a-z0-9-]+ [0-9]+/[0-9]+ .+$'
HC_TOTAL_RE='^TOTAL [0-9]+/[0-9]+ [0-9]+%$'
# The commit-msg body scripts/install-hooks.sh writes, so the healthy fixtures score the real hook
HC_COMMIT_MSG=$(sed -n "/<< 'HOOK'\$/,/^HOOK\$/p" scripts/install-hooks.sh 2>/dev/null | sed '1d;$d' || true)

assert_file_exists "harness-check.sh exists" "$HC_SCRIPT"
assert_bash_syntax "harness-check.sh valid bash" "$HC_SCRIPT"

# hc_run ARGS...: sets HC_OUT (stdout), HC_ERR (stderr), HC_RC (exit code).
hc_run() {
    HC_RC=0
    HC_OUT=$(bash "$HC_SCRIPT" "$@" 2>"$HC_TMP/stderr") || HC_RC=$?
    HC_ERR=$(cat "$HC_TMP/stderr" 2>/dev/null || true)
    return 0
}

hc_line() {
    grep -E "^[A-Z]+ $1 " <<< "$HC_OUT" | sed -n 1p || true
}

# hc_status DESC ID EXPECTED_STATUS
hc_status() {
    local got
    got=$(hc_line "$2" | cut -d' ' -f1)
    assert_eq "$1" "$3" "${got:-<no $2 line>}"
    return 0
}

# hc_format LABEL: the output contract every caller parses.
hc_format() {
    local bad last e=0 m=0 line pair
    bad=$(printf '%s\n' "$HC_OUT" | grep -vE "$HC_CHECK_RE|^CATEGORY [a-z]+ [0-9]+/[0-9]+\$|$HC_TOTAL_RE" || true)
    assert_eq "$1: every line is a check, CATEGORY, or TOTAL line" "" "$bad"
    last=$(printf '%s\n' "$HC_OUT" | tail -n 1)
    if grep -qE "$HC_TOTAL_RE" <<< "$last"; then
        pass "$1: last line is TOTAL <earned>/<max> <percent>%"
    else
        fail "$1: last line is TOTAL <earned>/<max> <percent>%" "got '$last'"
    fi
    bad=$(printf '%s\n' "$HC_OUT" | grep -E '^(INFO|SKIP) ' | grep -vE '^(INFO|SKIP) [a-z0-9-]+ 0/0 ' || true)
    assert_eq "$1: INFO and SKIP lines carry 0/0" "" "$bad"
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        pair=$(printf '%s\n' "$line" | cut -d' ' -f3)
        e=$((e + ${pair%/*}))
        m=$((m + ${pair#*/}))
    done <<EOF
$(printf '%s\n' "$HC_OUT" | grep -E "$HC_CHECK_RE" || true)
EOF
    assert_eq "$1: TOTAL is the sum of the check lines" "$e/$m" "$(printf '%s\n' "$last" | cut -d' ' -f2)"
    return 0
}

# hc_project DIR VERSION: skeleton + tests/fixtures/harness-check/VERSION, as a git work tree.
hc_project() {
    local d="$1" v="$2" f
    mkdir -p "$d/.claude/hooks" "$d/.claude/commands" "$d/.claude/agents" "$d/scripts" \
        "$d/docs/decisions" "$d/docs/runbooks" "$d/src/api" "$d/tests/hooks" "$d/tests/structure" "$d/tests/fixtures"
    printf '# Fixture project\n\n## Key Commands\n\n```bash\nbash tests/run-all.sh\n```\n' > "$d/CLAUDE.md"
    for f in README.md CHANGELOG.md .editorconfig .env.example docs/architecture.md docs/onboarding.md \
        docs/decisions/.template.md docs/runbooks/.template.md src/api/CLAUDE.md tests/fixtures/samples.txt; do
        printf 'fixture\n' > "$d/$f"
    done
    printf '.env\n.claude/settings.local.json\n' > "$d/.gitignore"
    printf '{"mcpServers": {}}\n' > "$d/.mcp.json"
    for f in scripts/setup.sh scripts/install-hooks.sh tests/run-all.sh tests/hooks/test-hooks.sh \
        tests/hooks/test-secret-patterns.sh tests/structure/test-structure.sh; do
        printf '#!/bin/bash\nexit 0\n' > "$d/$f"
    done
    printf -- '---\ndescription: Review the current diff\nallowed-tools: Read, Grep, Bash(git diff *)\n---\n\nReview the diff.\n' \
        > "$d/.claude/commands/review.md"
    printf -- '---\ndescription: Run the test suite\nallowed-tools: Read, Bash(bash tests/run-all.sh *)\n---\n\nRun the tests.\n' \
        > "$d/.claude/commands/test-all.md"
    printf -- '---\nname: code-reviewer\ndescription: Review a diff for bugs and convention violations\ntools: Read, Glob, Grep, Bash\n---\n\nReview the diff.\n' \
        > "$d/.claude/agents/code-reviewer.md"
    cp "$HC_FIX/$v/settings.json" "$d/.claude/settings.json"
    for f in "$HC_FIX/$v"/*.sh "$HC_FIX/$v"/*.yml; do
        case "$f" in
            *.sh) [ -f "$f" ] && cp "$f" "$d/.claude/hooks/" ;;
            *.yml) [ -f "$f" ] && cp "$f" "$d/.claude/agents/" ;;
        esac
    done
    chmod +x "$d"/.claude/hooks/*.sh "$d"/scripts/*.sh "$d"/tests/run-all.sh "$d"/tests/*/*.sh
    (
        cd "$d" && git init -q && git config core.hooksPath .git/hooks &&
            printf '%s\n' "$HC_COMMIT_MSG" > .git/hooks/commit-msg &&
            chmod +x .git/hooks/commit-msg && git add -A
    ) >/dev/null 2>&1 || true
    return 0
}

# --- This repository ---

hc_run .
assert_eq "repo: normal mode exits 0" "0" "$HC_RC"
assert_eq "repo: nothing on stderr" "" "$HC_ERR"
hc_format "repo"
hc_run --contract-only .
assert_eq "repo: this repo's hooks pass --contract-only" "0" "$HC_RC"

# --- Usage ---

hc_run --no-such-option
assert_eq "usage: unknown option exits 2" "2" "$HC_RC"
hc_run "$HC_TMP/does-not-exist"
assert_eq "usage: missing PROJECT_DIR exits 2" "2" "$HC_RC"

# --- Healthy project (current contract) ---

HC_P="$HC_TMP/healthy"
hc_project "$HC_P" current || true
hc_run "$HC_P"
assert_eq "healthy: exits 0" "0" "$HC_RC"
hc_format "healthy"
assert_eq "healthy: no FAIL or WARN lines" "" "$(printf '%s\n' "$HC_OUT" | grep -E '^(FAIL|WARN) ' || true)"
assert_eq "healthy: scores 100%" "100%" "$(printf '%s\n' "$HC_OUT" | tail -n 1 | cut -d' ' -f3)"
hc_status "healthy: gate registered via \$CLAUDE_PROJECT_DIR" hook-reg-secret-scan PASS
hc_status "healthy: observational hook registered with || true" hook-reg-check-doc-sync PASS
hc_status "healthy: installed Optional hook is scored" hook-reg-session-context PASS
hc_status "healthy: absent Optional hook is not applicable" hook-notify SKIP
hc_status "healthy: absent Optional gate is not applicable" hook-verify-on-stop SKIP
hc_status "healthy: commit-scope marker present" secret-scan-scope PASS
hc_status "healthy: module-coverage marker present" doc-sync-scope PASS
hc_status "healthy: registered gate script exists" contract-gate-missing PASS
hc_status "healthy: module coverage is a report" docs-modules INFO
assert_contains "healthy: module with CLAUDE.md is covered" "$(hc_line docs-modules)" "1/1 first-level modules covered"
assert_eq "healthy: a valid settings.json prints no contract-settings-json line" "" "$(hc_line contract-settings-json)"
hc_run --contract-only "$HC_P"
assert_eq "healthy: --contract-only exits 0" "0" "$HC_RC"
assert_eq "healthy: --contract-only prints only contract checks and TOTAL" "" \
    "$(printf '%s\n' "$HC_OUT" | grep -vE '^[A-Z]+ (contract-[a-z0-9-]+|secret-scan-scope|doc-sync-scope) |^TOTAL ' || true)"
hc_format "healthy --contract-only"
hc_run --contract-only -- "$HC_P"
assert_eq "healthy: -- ends the options" "0" "$HC_RC"
assert_eq "healthy: -- then PROJECT_DIR checks the project" "100%" "$(printf '%s\n' "$HC_OUT" | tail -n 1 | cut -d' ' -f3)"

# --- Lean Core+Default project: modules without a CLAUDE.md are not findings ---
# /init-project writes a module CLAUDE.md only for rules the code does not show, so a correct
# project may have none; docs-modules lists them for the model to judge and costs no points.

HC_P="$HC_TMP/lean"
hc_project "$HC_P" current || true
rm -f -- "$HC_P/src/api/CLAUDE.md" || true
mkdir -p "$HC_P/src/utils" && printf 'export const x = 1;\n' > "$HC_P/src/utils/x.js" || true
hc_run "$HC_P"
hc_format "lean"
assert_eq "lean: no FAIL or WARN lines" "" "$(printf '%s\n' "$HC_OUT" | grep -E '^(FAIL|WARN) ' || true)"
assert_eq "lean: scores 100%" "100%" "$(printf '%s\n' "$HC_OUT" | tail -n 1 | cut -d' ' -f3)"
hc_status "lean: uncovered modules are INFO" docs-modules INFO
assert_contains "lean: docs-modules lists the uncovered modules" "$(hc_line docs-modules)" "uncovered: src/api/, src/utils/"
printf '# src\n' > "$HC_P/src/CLAUDE.md" || true
hc_run "$HC_P"
assert_contains "lean: a source root's CLAUDE.md covers every module below it" "$(hc_line docs-modules)" \
    "2/2 first-level modules covered"
assert_eq "lean: nothing is uncovered under src/CLAUDE.md" "" "$(hc_line docs-modules | grep -F uncovered || true)"

# --- v2.3-v2.4 project: relative registrations, no commit-scope marker ---

HC_P="$HC_TMP/v2.4"
hc_project "$HC_P" v2.4 || true
hc_run "$HC_P"
assert_eq "v2.4: exits 0" "0" "$HC_RC"
hc_format "v2.4"
hc_status "v2.4: missing marker is WARN" secret-scan-scope WARN
assert_contains "v2.4: marker message points to migrate-hooks" "$(hc_line secret-scan-scope)" \
    "predates the commit-scope fix; run /project-init:migrate-hooks"
hc_status "v2.4: local \$EVENT/\$MESSAGE in notify.sh are not pre-v2.3 signals" contract-env-vars PASS
hc_status "v2.4: gate without || true passes" contract-gate-true PASS
hc_status "v2.4: exit 2 passes" contract-exit1 PASS
hc_status "v2.4: relative gate registration counts, but is not anchored" hook-reg-secret-scan WARN
hc_status "v2.4: installed Optional notify.sh is scored" hook-reg-notify WARN
hc_status "v2.4: check-doc-sync.sh without the module-coverage marker is WARN" doc-sync-scope WARN
assert_contains "v2.4: module-coverage message points to migrate-hooks" "$(hc_line doc-sync-scope)" \
    "predates the module-coverage fix; run /project-init:migrate-hooks"
hc_run --contract-only "$HC_P"
assert_eq "v2.4: --contract-only exits 1 on the marker WARN" "1" "$HC_RC"
assert_contains "v2.4: --contract-only reports doc-sync-scope" "$(hc_line doc-sync-scope)" "WARN doc-sync-scope"

# --- Pre-v2.3 project ---

HC_P="$HC_TMP/v2.2"
hc_project "$HC_P" v2.2 || true
hc_run "$HC_P"
assert_eq "v2.2: normal mode still exits 0" "0" "$HC_RC"
hc_format "v2.2"
hc_status "v2.2: env-var arguments and \$1-only hooks" contract-env-vars FAIL
hc_status "v2.2: gate registered with || true" contract-gate-true FAIL
hc_status "v2.2: secret-scan exits 1" contract-exit1 FAIL
hc_status "v2.2: .yml agent" contract-yml-agents FAIL
hc_status "v2.2: no commit-scope marker" secret-scan-scope WARN
hc_status "v2.2: no module-coverage marker" doc-sync-scope WARN
hc_status "v2.2: a gate that cannot block earns nothing" hook-reg-secret-scan FAIL
hc_run --contract-only "$HC_P"
assert_eq "v2.2: --contract-only exits 1" "1" "$HC_RC"
assert_contains "v2.2: env-var finding names the script and \$TOOL_INPUT_PATH" "$(hc_line contract-env-vars)" \
    'check-doc-sync.sh is registered with $TOOL_INPUT_PATH'
assert_contains "v2.2: env-var finding names notify.sh" "$(hc_line contract-env-vars)" 'notify.sh is registered with $EVENT $MESSAGE'

# --- Fresh template output passes the contract ---
# The Core hooks and settings that /init-project writes must never be flagged; a template change
# that trips a contract check would send every new project to /migrate-hooks.

HC_P="$HC_TMP/template"
hc_project "$HC_P" current || true
if python3 - "$PWD/plugins/project-init/skills/project-scaffolder/references" "$HC_P/.claude" <<'PY' 2>/dev/null
import re, sys
ref, out = sys.argv[1], sys.argv[2]
hooks = open(ref + "/hook-scripts.md", encoding="utf-8").read()
for name in ("secret-scan", "check-doc-sync"):
    m = re.search(r"^## " + re.escape(name) + r"\.sh.*?^```bash\n(.*?)^```", hooks, re.S | re.M)
    open(out + "/hooks/" + name + ".sh", "w").write(m.group(1))
settings = open(ref + "/settings-json-template.md", encoding="utf-8").read()
m = re.search(r"^```json\n(.*?)^```", settings, re.S | re.M)
open(out + "/settings.json", "w").write(m.group(1))
PY
then
    hc_run --contract-only "$HC_P"
    assert_eq "template: fresh secret-scan.sh, check-doc-sync.sh, settings.json pass --contract-only" "0" "$HC_RC"
    hc_run "$HC_P"
    hc_status "template: secret-scan registration" hook-reg-secret-scan PASS
    hc_status "template: check-doc-sync registration" hook-reg-check-doc-sync PASS
else
    fail "template: extract Core hooks and settings from the references" \
        "hook-scripts.md needs '## <name>.sh' sections with a bash block; settings-json-template.md a json block"
fi

# --- Empty directory: Core is scored, Optional is not ---

HC_P="$HC_TMP/empty"
mkdir -p "$HC_P" || true
hc_run "$HC_P"
assert_eq "empty: exits 0" "0" "$HC_RC"
hc_format "empty"
hc_status "empty: missing root CLAUDE.md is FAIL" core-claude-md FAIL
hc_status "empty: missing Core gate is FAIL" hook-secret-scan FAIL
hc_status "empty: missing Optional hook is SKIP" hook-session-context SKIP
hc_status "empty: no components is SKIP" components-load SKIP
hc_run --contract-only "$HC_P"
assert_eq "empty: --contract-only exits 0 when nothing applies" "0" "$HC_RC"
assert_eq "empty: --contract-only TOTAL with nothing applicable" "TOTAL 0/0 100%" "$(printf '%s\n' "$HC_OUT" | tail -n 1)"

# --- Outside git: the secret scan walks the working tree ---

# hc_nogit DIR: a token in a source file and in the local-only .env.
hc_nogit() {
    mkdir -p "$1/src"
    printf 'k = "%s%s"\n' 'ghp_' "$(printf '%036d' 0)" > "$1/src/app.py"
    printf 'K=%s%s\n' 'ghp_' "$(printf '%036d' 0)" > "$1/.env"
    return 0
}

HC_P="$HC_TMP/nogit"
hc_nogit "$HC_P" || true
if git -C "$HC_P" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    skip "nogit: secret scan outside git" "the temp directory is inside a git work tree"
else
    hc_run "$HC_P"
    hc_status "nogit: token in a working-tree file" sec-scan WARN
    assert_contains "nogit: finding names file:line" "$(hc_line sec-scan)" "src/app.py:1"
    assert_eq "nogit: .env is local-only, not a finding" "" "$(hc_line sec-scan | grep -F '.env' || true)"
    hc_status "nogit: tracked-file check does not apply" sec-tracked SKIP
fi

# --- Components, compatibility, and security signals ---

# hc_signals DIR: a healthy project plus one instance of each non-contract finding.
hc_signals() {
    local d="$1"
    hc_project "$d" current
    mkdir -p "$d/.claude/skills/code-review" "$d/.claude/skills/sync-docs" "$d/.claude/skills/refactor" "$d/.claude/skills/notes"
    printf -- '---\nname: code-review\ndescription: Review code\n---\n\nReview.\n' > "$d/.claude/skills/code-review/SKILL.md"
    printf -- '---\nname: sync-docs\ndescription: Sync docs\ntools: Read, Glob\n---\n\nSync.\n' > "$d/.claude/skills/sync-docs/SKILL.md"
    printf '# Notes skill\n\nNo frontmatter.\n' > "$d/.claude/skills/notes/SKILL.md"
    printf -- '---\nname: auditor\ndescription: Audit\nmax_turns: 5\nmodel: claude-3-5-sonnet-20241022\n---\n\nAudit.\n' > "$d/.claude/agents/auditor.md"
    printf 'name: broken\n' > "$d/.claude/agents/broken.md"
    sed 's/"SessionStart"/"SessionBegin"/' "$HC_FIX/current/settings.json" > "$d/.claude/settings.json"
    chmod -x "$d/.claude/hooks/check-doc-sync.sh"
    mkdir -p "$d/src/billing"
    printf 'token = "%s%s"\n' 'ghp_' "$(printf '%036d' 0)" > "$d/src/billing/config.py"
    printf 'key = "%s%s"\n' 'AKIA' 'IOSFODNN7EXAMPLE' > "$d/src/billing/sample.py"
    printf 'SECRET=x\n' > "$d/.env"
    ( cd "$d" && git add -A && git add -f .env ) >/dev/null 2>&1 || true
    return 0
}

HC_P="$HC_TMP/signals"
hc_signals "$HC_P" || true
hc_run "$HC_P"
hc_format "signals"
hc_status "signals: code-review skill beside /review and code-reviewer" components-dup WARN
hc_status "signals: local sync-docs skill duplicates the plugin command" components-plugin-dup WARN
hc_status "signals: code-review skill shadows the bundled command" components-bundled INFO
hc_status "signals: skill dir without SKILL.md and agent without frontmatter do not load" components-load WARN
hc_status "signals: skill without frontmatter" compat-skill-frontmatter WARN
hc_status "signals: skill tools: key" compat-skill-keys WARN
hc_status "signals: snake_case agent key" compat-agent-keys WARN
hc_status "signals: old full model ID" compat-model-ids WARN
hc_status "signals: undocumented hook event" compat-hook-events WARN
hc_status "signals: hook registered under the wrong event" hook-reg-session-context FAIL
hc_status "signals: non-executable hook run via bash" hook-check-doc-sync WARN
hc_status "signals: uncovered module is a note, not a finding" docs-modules INFO
assert_contains "signals: docs-modules names the uncovered module" "$(hc_line docs-modules)" "uncovered: src/billing/"
hc_status "signals: tracked .env" sec-tracked FAIL
hc_status "signals: committed token" sec-scan WARN
assert_contains "signals: secret finding names file:line" "$(hc_line sec-scan)" "src/billing/config.py:1"
assert_eq "signals: AWS documentation sample key is not a finding" "" \
    "$(hc_line sec-scan | grep -F 'sample.py' || true)"
assert_eq "signals: the matched secret is never printed" "" \
    "$(printf '%s\n' "$HC_OUT" | grep -F "ghp_$(printf '%036d' 0)" || true)"
hc_run --contract-only "$HC_P"
assert_eq "signals: --contract-only ignores non-contract findings" "0" "$HC_RC"

# --- Settings that Claude Code cannot load, and gates that cannot run ---

# hc_variant NAME: a fresh copy of the healthy project; sets HC_P.
hc_variant() {
    HC_P="$HC_TMP/$1"
    hc_project "$HC_P" current
    return 0
}

# hc_settings JSON: replace the healthy project's settings.json.
hc_settings() {
    printf '%s\n' "$1" > "$HC_P/.claude/settings.json"
    return 0
}

# --- Model pins: the superseded 5.0 IDs are older models; the 5.5 family and Fable 5.1 are not ---

hc_variant pins-old || true
printf -- '---\nname: a\ndescription: A\nmodel: claude-sonnet-5\n---\n\nA.\n' > "$HC_P/.claude/agents/a.md" || true
printf -- '---\nname: b\ndescription: B\nmodel: "claude-opus-5[1m]"\n---\n\nB.\n' > "$HC_P/.claude/agents/b.md" || true
printf -- '---\nname: c\ndescription: C\nmodel: claude-sonnet-5-5\n---\n\nC.\n' > "$HC_P/.claude/agents/c.md" || true
hc_run "$HC_P"
hc_status "pins: claude-sonnet-5 is an older model" compat-model-ids WARN
assert_contains "pins: the [1m] form of claude-opus-5 is flagged" "$(hc_line compat-model-ids)" "claude-opus-5[1m]"
assert_eq "pins: claude-sonnet-5-5 is not flagged" "" "$(hc_line compat-model-ids | grep -F 'claude-sonnet-5-5' || true)"

hc_variant pins-new || true
printf -- '---\nname: a\ndescription: A\nmodel: claude-opus-5-5\n---\n\nA.\n' > "$HC_P/.claude/agents/a.md" || true
printf -- '---\nname: b\ndescription: B\nmodel: claude-fable-5-1\n---\n\nB.\n' > "$HC_P/.claude/agents/b.md" || true
printf -- '---\nname: c\ndescription: C\nmodel: claude-haiku-5-5\n---\n\nC.\n' > "$HC_P/.claude/agents/c.md" || true
hc_run "$HC_P"
hc_status "pins: claude-opus-5-5, claude-fable-5-1, and claude-haiku-5-5 are current" compat-model-ids PASS

hc_variant badjson || true
sed '$d' "$HC_FIX/current/settings.json" > "$HC_P/.claude/settings.json" 2>/dev/null || true   # drop the closing }
if command -v python3 >/dev/null 2>&1; then
    hc_run "$HC_P"
    hc_format "badjson"
    hc_status "badjson: unparsable settings.json is a contract FAIL" contract-settings-json FAIL
    hc_status "badjson: a gate in an unparsable settings.json is not registered" hook-reg-secret-scan FAIL
    assert_contains "badjson: the registration finding names the cause" "$(hc_line hook-reg-secret-scan)" "invalid JSON"
    hc_status "badjson: deny rules in an unparsable settings.json do not apply" core-deny FAIL
    hc_run --contract-only "$HC_P"
    assert_eq "badjson: --contract-only exits 1" "1" "$HC_RC"
else
    skip "badjson: invalid settings.json" "python3 not found"
fi

hc_variant nogate || true
rm -f -- "$HC_P/.claude/hooks/secret-scan.sh" || true
hc_run "$HC_P"
hc_status "nogate: registered gate whose script is missing" contract-gate-missing FAIL
hc_status "nogate: its registration earns nothing" hook-reg-secret-scan FAIL
assert_contains "nogate: the finding says why it never blocks" "$(hc_line hook-reg-secret-scan)" "exits 127"
hc_run --contract-only "$HC_P"
assert_eq "nogate: --contract-only exits 1" "1" "$HC_RC"

# --- settings.json parsing ---

HC_GATE='"bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/secret-scan.sh'
HC_DOCS='{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-doc-sync.sh 2>/dev/null || true"}'

hc_variant groups || true
hc_settings '{"permissions": {"deny": ["Bash(rm -rf *)"]}, "hooks": {
  "PreToolUse": [
    {"matcher": "Edit", "hooks": [{"type": "command", "command": "echo edit"}]},
    {"hooks": [{"type": "command", "command": '"$HC_GATE"'"}]}
  ],
  "PostToolUse": [{"matcher": "Write|Edit", "hooks": ['"$HC_DOCS"']}]}}' || true
hc_run "$HC_P"
hc_status "groups: a group without a matcher matches Bash" hook-reg-secret-scan PASS

hc_variant gatetail || true
hc_settings '{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": '"$HC_GATE"' || echo failed"}]}]}}' || true
hc_run --contract-only "$HC_P"
hc_status "gatetail: || echo replaces the exit code" contract-gate-true FAIL
hc_settings '{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": '"$HC_GATE"'; exit 0"}]}]}}' || true
hc_run --contract-only "$HC_P"
hc_status "gatetail: ; exit 0 replaces the exit code" contract-gate-true FAIL
hc_settings '{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": '"$HC_GATE"' 2>&1"}]}]}}' || true
hc_run "$HC_P"
hc_status "gatetail: 2>&1 keeps exit 2" contract-gate-true PASS
hc_status "gatetail: 2>&1 still costs the registration points" hook-reg-secret-scan WARN
hc_settings '{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /opt/repo/.claude/hooks/secret-scan.sh"}]}]}}' || true
hc_run "$HC_P"
assert_contains "gatetail: an absolute path is named as such" "$(hc_line hook-reg-secret-scan)" "absolute path"

# --- Secret scan: patterns, samples, and skips ---

# hc_secret FILE LINE: write LINE to FILE in HC_P and stage it. Tokens are built at run time, so this
# file never matches a secret pattern itself.
hc_secret() {
    mkdir -p "$(dirname "$HC_P/$1")" && printf '%s\n' "$2" > "$HC_P/$1" && ( cd "$HC_P" && git add -- "$1" )
    return 0
}
HC_Z36=$(printf '%036d' 0)
HC_Z50=$(printf '%050d' 0)

hc_variant secrets || true
hc_secret src/a/svc.py "k = \"sk-svcacct-$HC_Z50\"" || true
hc_secret src/a/key.pem "-----BEGIN RSA PRIVATE"" KEY-----" || true
hc_secret src/a/cfg.json "{\"pass""word\": \"hunter2hunter2\"}" || true
hc_secret src/a/az.txt "DefaultEndpointsProtocol=https;""AccountName=x" || true
hc_secret src/a/g.py "t = \"ya29.$HC_Z50\"" || true
hc_secret src/b/refs.yml "pass""word: \"\${DB_PASSWORD}\"" || true
hc_secret src/b/helm.yml "sec""ret: \"{{ .Values.secret }}\"" || true
hc_secret src/b/ph.py "api_""key = \"<your-api-key-here>\"" || true
hc_secret src/b/aws.py "key = \"AKIA""IOSFODNN7EXAMPLE\"" || true
hc_secret tests/fixtures/secret-samples.txt "k = \"ghp_$HC_Z36\"" || true
hc_secret packages/x/.claude/hooks/secret-scan.sh "k = \"ghp_$HC_Z36\"" || true
hc_run "$HC_P"
hc_status "secrets: committed secrets are found" sec-scan WARN
for HC_F in src/a/svc.py src/a/key.pem src/a/cfg.json src/a/az.txt src/a/g.py; do
    assert_contains "secrets: finds $HC_F" "$(hc_line sec-scan)" "$HC_F:1"
done
for HC_F in src/b/refs.yml src/b/helm.yml src/b/ph.py src/b/aws.py tests/fixtures/secret-samples.txt \
    packages/x/.claude/hooks/secret-scan.sh; do
    assert_eq "secrets: $HC_F is not a finding" "" "$(hc_line sec-scan | grep -F "$HC_F" || true)"
done

# The AWS sample exemption is per token: EXAMPLE elsewhere on the line or in the path is no excuse.
hc_variant samples || true
hc_secret src/a/example.py "k = \"ghp_$HC_Z36\"  # replace with EXAMPLE value" || true
hc_secret EXAMPLES/app.py "k = \"ghp_$HC_Z36\"" || true
hc_secret tests/fixtures/other.txt "k = \"ghp_$HC_Z36\"" || true
hc_run "$HC_P"
for HC_F in src/a/example.py EXAMPLES/app.py tests/fixtures/other.txt; do
    assert_contains "samples: finds $HC_F" "$(hc_line sec-scan)" "$HC_F:1"
done

# --- One project, independent signals: disableAllHooks, .mcp.json literals, .gitignore coverage,
# and the Optional verify-on-stop gate's VERIFY_CMD ---

hc_variant misc || true
printf '{"disableAllHooks": true}\n' > "$HC_P/.claude/settings.local.json" || true
printf '{"mcpServers": {"api": {"type": "http", "url": "https://x", "headers": {"X-API-%s": "%s"}}}}\n' \
    Key "lit""eral-value-123" > "$HC_P/.mcp.json" || true
printf '.env.local\n.env.*\n.claude/settings.local.json\n' > "$HC_P/.gitignore" || true
printf '#!/bin/bash\nVERIFY_CMD="${VERIFY_CMD:-npm run lint}"\nexit 0\n' > "$HC_P/.claude/hooks/verify-on-stop.sh" || true
chmod +x "$HC_P/.claude/hooks/verify-on-stop.sh" || true
hc_run "$HC_P"
hc_status "misc: disableAllHooks turns every gate off" hook-disable-all WARN
hc_status "misc: literal value in an X-API-Key header" sec-mcp WARN
hc_status "misc: .env.local and .env.* do not cover .env" sec-gitignore WARN
hc_status "misc: VERIFY_CMD is the template default without a lint script" hook-verify-cmd WARN
printf '{"mcpServers": {"api": {"type": "http", "url": "https://x", "headers": {"Authorization": "Bearer ${API_TOKEN}"}}}}\n' \
    > "$HC_P/.mcp.json" || true
printf '.env\n!.env\n.claude/settings.local.json\n' > "$HC_P/.gitignore" || true
printf '#!/bin/bash\nVERIFY_CMD="${VERIFY_CMD:-bash tests/run-all.sh}"\nexit 0\n' > "$HC_P/.claude/hooks/verify-on-stop.sh" || true
hc_run "$HC_P"
hc_status "misc: a \${VAR} reference is not a literal" sec-mcp PASS
if git -C "$HC_P" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    hc_status "misc: a later !.env negation undoes the coverage" sec-gitignore WARN
fi
hc_status "misc: a VERIFY_CMD that runs here" hook-verify-cmd PASS

# --- The commit-msg hook: a GNU-only sed -i, and a hook manager that owns core.hooksPath ---

hc_variant commitmsg || true
printf '#!/bin/bash\nsed -i "/^[Cc]o-[Aa]uthored-[Bb]y:/d" "$1"\n' > "$HC_P/.git/hooks/commit-msg" 2>/dev/null || true
hc_run "$HC_P"
hc_status "commit-msg: a bare sed -i (fails on macOS) is a finding" core-commit-msg WARN
assert_contains "commit-msg: the finding names the backup suffix" "$(hc_line core-commit-msg)" "without a backup suffix"
rm -f -- "$HC_P/.git/hooks/commit-msg" || true
git -C "$HC_P" config core.hooksPath .husky >/dev/null 2>&1 || true
hc_run "$HC_P"
hc_status "commit-msg: no hook under a custom core.hooksPath" core-commit-msg WARN
assert_contains "commit-msg: the finding points at the hook manager" "$(hc_line core-commit-msg)" "core.hooksPath=.husky"

# --- A python3 on PATH that does not run (the Windows Store alias) is not python3 ---

HC_STUB="$HC_TMP/stub-bin"
mkdir -p "$HC_STUB" && printf '#!/bin/sh\nexit 49\n' > "$HC_STUB/python3" && chmod +x "$HC_STUB/python3" || true
HC_RC=0
HC_OUT=$(PATH="$HC_STUB:$PATH" bash "$HC_SCRIPT" "$HC_TMP/healthy" 2>/dev/null) || HC_RC=$?
hc_status "stub python3: a python3 that does not run is a finding" hook-python3 WARN
assert_contains "stub python3: the finding says commits go through with a warning" "$(hc_line hook-python3)" "lets commits through with a warning"

# --- The Stop gate outside a git work tree never runs its check ---

if git -C "$HC_TMP" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    skip "nogit: verify-on-stop outside git" "the temp directory is inside a git work tree"
else
    mkdir -p "$HC_TMP/nogit/.claude/hooks" || true
    printf '#!/bin/bash\nVERIFY_CMD="${VERIFY_CMD:-true}"\nexit 0\n' > "$HC_TMP/nogit/.claude/hooks/verify-on-stop.sh" || true
    hc_run "$HC_TMP/nogit"
    hc_status "nogit: verify-on-stop outside a git work tree is a finding" hook-verify-cmd WARN
    assert_contains "nogit: the finding says the gate never runs" "$(hc_line hook-verify-cmd)" "not a git work tree"
fi

rm -rf -- "$HC_TMP"   # -f: git objects are read-only, and rm would prompt on a terminal
