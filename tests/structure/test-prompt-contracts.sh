#!/bin/bash
# Cross-file prompt contracts in the plugin: rules that one file states and others must not contradict.
# Each check guards a drift that an adversarial review found and the rest of the suite did not catch.
# Sourced by tests/run-all.sh (set -euo pipefail), so every command that can fail is guarded.
# Secret-shaped samples are built at runtime, so this file never matches the commit gate itself.

PC_PLUGIN="plugins/project-init"
PC_SKILL="$PC_PLUGIN/skills/project-scaffolder/SKILL.md"
PC_REFS="$PC_PLUGIN/skills/project-scaffolder/references"

# --- Module coverage: a source root's own CLAUDE.md counts (SKILL.md is the single source) ---

PC_COVERAGE=$(sed -n '/^## Module CLAUDE.md Coverage$/,/^## CLAUDE.md Quality Criteria$/p' "$PC_SKILL" 2>/dev/null || true)
assert_contains "coverage rule: SKILL.md covers a directory from an ancestor at or below the source root" "$PC_COVERAGE" "at or below the source root"
if grep -qi "does not count" <<< "$PC_COVERAGE"; then
    fail "coverage rule: SKILL.md does not exclude the source root's own CLAUDE.md" "found 'does not count' in ## Module CLAUDE.md Coverage"
else
    pass "coverage rule: SKILL.md does not exclude the source root's own CLAUDE.md"
fi
if grep -q "below src/)" "$PC_PLUGIN/agents/doc-sync-checker.md" 2>/dev/null; then
    fail "coverage rule: doc-sync-checker example counts src/CLAUDE.md" "example says 'an ancestor below src/', which excludes the source root"
else
    pass "coverage rule: doc-sync-checker example counts src/CLAUDE.md"
fi

# The fallback source roots (no check-doc-sync.sh SOURCE_ROOTS) are stated once in SKILL.md, and
# harness-check.sh and /sync-docs use the same list
PC_ROOTS=$(sed -n 's/.*|| roots="\([^"]*\)".*/\1/p' "$PC_PLUGIN/scripts/harness-check.sh" 2>/dev/null | sed -n 1p || true)
if [ -z "$PC_ROOTS" ]; then
    fail "coverage rule: harness-check.sh has a fallback source-root list" "no '|| roots=\"...\"' line found"
else
    assert_contains "coverage rule: SKILL.md states harness-check's fallback roots ($PC_ROOTS)" "$PC_COVERAGE" "\`$PC_ROOTS\`"
    PC_FIND=$(grep -m 1 'Source roots:' "$PC_PLUGIN/commands/sync-docs.md" 2>/dev/null |
        grep -oE -- "-name [a-z]+" | sed 's/-name //' | tr '\n' ' ' | sed 's/ $//' || true)
    assert_eq "coverage rule: /sync-docs falls back to the same source roots" "$PC_ROOTS" "$PC_FIND"
fi

# --- Module CLAUDE.md template: commands cite the section instead of listing old headings ---

PC_STALE=$(grep -l -E 'Key Files|\(Role, ' "$PC_PLUGIN"/commands/*.md "$PC_PLUGIN"/agents/*.md 2>/dev/null || true)
assert_eq "module template: no command or agent lists the old Role/Key Files/Rules headings" "" "$PC_STALE"

# --- Generated /deploy: the runbook it offers to write matches the glob it follows ---

PC_DEPLOY=$(sed -n '/^### Deploy Command$/,/^## Optional Skills$/p' "$PC_REFS/skills-templates.md" 2>/dev/null || true)
assert_contains "deploy template: follows docs/runbooks/deploy-*.md" "$PC_DEPLOY" 'docs/runbooks/deploy-*.md'
assert_contains "deploy template: offers /add-runbook deploy-<environment>" "$PC_DEPLOY" '/add-runbook deploy-production'
if grep -q '/add-runbook deploy`' <<< "$PC_DEPLOY"; then
    fail "deploy template: never offers /add-runbook deploy (writes deploy.md, which the glob misses)" "found '/add-runbook deploy\`'"
else
    pass "deploy template: never offers /add-runbook deploy (writes deploy.md, which the glob misses)"
fi

# --- Secrets grep in SKILL.md: one list, catches real key shapes, skips kebab-case words ---

PC_TOKEN_RE=$(grep -m 1 "# secret-shaped tokens" "$PC_SKILL" 2>/dev/null | sed -n "s/^grep -nE '\\(.*\\)' CLAUDE.md .*/\\1/p" || true)
PC_ASSIGN_RE=$(grep -m 1 "# credential assignments" "$PC_SKILL" 2>/dev/null | sed -n "s/^grep -inE '\\(.*\\)' CLAUDE.md .*/\\1/p" || true)
if [ -z "$PC_TOKEN_RE" ] || [ -z "$PC_ASSIGN_RE" ]; then
    fail "secrets grep: SKILL.md has the token and assignment greps" "could not extract them from ## CLAUDE.md Anti-Patterns"
else
    pass "secrets grep: SKILL.md has the token and assignment greps"
    PC_ANT="sk-""ant-api03-$(printf 'A%.0s' $(seq 1 90))"
    for PC_SAMPLE in "$PC_ANT" "sk-""proj-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789abcdefgh" \
        "gh""p_abcdefghijklmnopqrstuvwxyz0123456789" "AK""IAABCDEFGHIJKLMNOP" "-----BEGIN RSA PRIV""ATE KEY-----"; do
        if grep -qE -- "$PC_TOKEN_RE" <<< "$PC_SAMPLE"; then
            pass "secrets grep: matches ${PC_SAMPLE:0:12}..."
        else
            fail "secrets grep: matches ${PC_SAMPLE:0:12}..." "the SKILL.md token grep missed it"
        fi
    done
    for PC_SAMPLE in "task-management-system-overview-doc" "risk-assessment-and-mitigation-plan-for-q3"; do
        if grep -qE -- "$PC_TOKEN_RE" <<< "$PC_SAMPLE"; then
            fail "secrets grep: skips the kebab-case word $PC_SAMPLE" "the SKILL.md token grep matched it"
        else
            pass "secrets grep: skips the kebab-case word $PC_SAMPLE"
        fi
    done
    for PC_SAMPLE in '"api_''key": "abc123"' 'DB_PASS''WORD=hunter2' 'aws_secret_''access_key = abc'; do
        if grep -qiE -- "$PC_ASSIGN_RE" <<< "$PC_SAMPLE"; then
            pass "secrets grep: flags the assignment $PC_SAMPLE"
        else
            fail "secrets grep: flags the assignment $PC_SAMPLE" "the SKILL.md assignment grep missed it"
        fi
    done
fi
if grep -qE 'sk-\[|password\\s|AKIA\[' "$PC_PLUGIN/agents/doc-sync-checker.md" 2>/dev/null; then
    fail "secrets grep: doc-sync-checker cites SKILL.md instead of keeping its own list" "found a secret regex in doc-sync-checker.md"
else
    pass "secrets grep: doc-sync-checker cites SKILL.md instead of keeping its own list"
fi

# --- Commands that ask before running tools use AskUserQuestion (the allowed-tools grant ends with the turn) ---

for PC_CMD in init-project sync-docs generate-changelog generate-readme add-adr add-runbook add-module add-reference-doc; do
    if grep -q "AskUserQuestion" "$PC_PLUGIN/commands/$PC_CMD.md" 2>/dev/null; then
        pass "asking: $PC_CMD.md asks with AskUserQuestion"
    else
        fail "asking: $PC_CMD.md asks with AskUserQuestion" "a chat reply starts a new turn, where allowed-tools no longer apply"
    fi
done

# --- Checks that meet pre-existing content report it instead of rewriting it ---

assert_contains "pre-existing: init-project reports old CHANGELOG/README issues" "$(cat "$PC_PLUGIN/commands/init-project.md" 2>/dev/null)" "pre-existing"
assert_contains "pre-existing: generate-changelog leaves released sections" "$(cat "$PC_PLUGIN/commands/generate-changelog.md" 2>/dev/null)" "pre-existing"
PC_FINISH=$(sed -n '/^## Finish$/,/^## Summary$/p' "$PC_PLUGIN/commands/init-project.md" 2>/dev/null || true)
assert_contains "init-project: Finish bilingual check covers docs/reference/INDEX.md" "$PC_FINISH" "docs/reference/INDEX.md"
assert_contains "init-project: Finish bilingual check covers the runbook template" "$PC_FINISH" "docs/runbooks/.template.md"
assert_contains "init-project: allowed-tools cover the changelog template's release dates" "$(sed -n '1,6p' "$PC_PLUGIN/commands/init-project.md" 2>/dev/null)" "Bash(git for-each-ref *)"

# --- Declined reference layers: every writer and reader of INDEX.md knows the status ---

for PC_FILE in "$PC_REFS/reference-doc-template.md" "$PC_PLUGIN/commands/init-project.md" "$PC_PLUGIN/commands/add-reference-doc.md" \
    "$PC_PLUGIN/commands/sync-docs.md" "$PC_PLUGIN/agents/doc-sync-checker.md"; do
    assert_contains "INDEX status: ${PC_FILE##*/} knows 'declined'" "$(cat "$PC_FILE" 2>/dev/null)" "declined"
done

# --- Template facts that other files contradicted ---

if grep -q 'Last verified: <today' "$PC_PLUGIN/commands/add-runbook.md" 2>/dev/null; then
    fail "runbook: a new runbook is not stamped verified today" "add-runbook writes 'Last verified: <today>'"
else
    pass "runbook: a new runbook is not stamped verified today"
fi
PC_ENV=$(sed -n '/^## Environment Template$/,$p' "$PC_REFS/docs-templates.md" 2>/dev/null || true)
if grep -q 'CLAUDE_NOTIFY_WEBHOOK=' <<< "$PC_ENV"; then
    fail ".env.example template: no CLAUDE_NOTIFY_WEBHOOK (notify.sh never reads .env)" "found CLAUDE_NOTIFY_WEBHOOK= in the Environment Template"
else
    pass ".env.example template: no CLAUDE_NOTIFY_WEBHOOK (notify.sh never reads .env)"
fi

# --- Claude 5.5 family: the subagent-model option and the verification contract ---

PC_SUBAGENT=$(sed -n '/^## Optional: Subagent Model$/,/^## /p' "$PC_REFS/settings-json-template.md" 2>/dev/null || true)
assert_contains "settings template: Optional: Subagent Model names the variable" "$PC_SUBAGENT" "CLAUDE_CODE_SUBAGENT_MODEL"
assert_contains "settings template: Subagent Model gives the Haiku 4.5 provider caveat" "$PC_SUBAGENT" "ANTHROPIC_DEFAULT_HAIKU_MODEL"
if python3 - "$PC_REFS/settings-json-template.md" <<'PY' 2>/dev/null
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
sec = re.search(r"^## Optional: Subagent Model\n(.*?)(?=^## |\Z)", text, re.S | re.M)
block = re.search(r"^```json\n(.*?)^```", sec.group(1), re.S | re.M)
assert json.loads(block.group(1))["env"]["CLAUDE_CODE_SUBAGENT_MODEL"]
PY
then
    pass "settings template: the Subagent Model block is JSON with env.CLAUDE_CODE_SUBAGENT_MODEL"
else
    fail "settings template: the Subagent Model block is JSON with env.CLAUDE_CODE_SUBAGENT_MODEL" \
        "needs a json block under ## Optional: Subagent Model"
fi
assert_contains "agents template: points lower-cost subagents to the settings section" \
    "$(cat "$PC_REFS/agents-templates.md" 2>/dev/null)" "## Optional: Subagent Model"
assert_contains "agents template: reviewers inherit effort, raised with /effort high" \
    "$(cat "$PC_REFS/agents-templates.md" 2>/dev/null)" "/effort high"
assert_contains "CLAUDE.md template: a check that failed to start does not count" \
    "$(cat "$PC_REFS/claude-md-template.md" 2>/dev/null)" "a command that failed to start, does not count"
PC_TESTALL=$(sed -n '/^### Test All Command$/,/^### /p' "$PC_REFS/skills-templates.md" 2>/dev/null || true)
assert_contains "/test-all template: a suite that could not start is reported as not run" "$PC_TESTALL" "report it as not run"
PC_RULES=$(sed -n '/^### Writing commands/,/^### Paths/p' "$PC_PLUGIN/CLAUDE.md" 2>/dev/null || true)
assert_contains "plugin rules: consumer models include Sonnet 5.5" "$PC_RULES" "Sonnet 5.5"
assert_contains "plugin rules: consumer models include Haiku 5.5" "$PC_RULES" "Haiku 5.5"
assert_contains "plugin rules: the subagent model option cites its settings section" "$PC_RULES" "## Optional: Subagent Model"
if grep -qE 'Sonnet 5 or Haiku 4\.5|Opus 5 models over-verify' <<< "$PC_RULES"; then
    fail "plugin rules: no stale model set or Opus 5 reason" "found 'Sonnet 5 or Haiku 4.5' or 'Opus 5 models over-verify'"
else
    pass "plugin rules: no stale model set or Opus 5 reason"
fi
