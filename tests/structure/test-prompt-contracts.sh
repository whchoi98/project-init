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

# --- Claude 5.5 family and Fable 5.2: the subagent-model option and the verification contract ---

PC_SUBAGENT=$(sed -n '/^## Optional: Subagent Model$/,/^## /p' "$PC_REFS/settings-json-template.md" 2>/dev/null || true)
assert_contains "settings template: Optional: Subagent Model names the variable" "$PC_SUBAGENT" "CLAUDE_CODE_SUBAGENT_MODEL"
assert_contains "settings template: Subagent Model gives the Haiku 4.5 provider caveat" "$PC_SUBAGENT" "ANTHROPIC_DEFAULT_HAIKU_MODEL"
assert_contains "settings template: Subagent Model names the effort variable for a subagent on another model" "$PC_SUBAGENT" "CLAUDE_CODE_SUBAGENT_EFFORT"
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
assert_contains "agents template: an agent on another model takes its effort from the variable the settings section names" \
    "$(cat "$PC_REFS/agents-templates.md" 2>/dev/null)" "CLAUDE_CODE_SUBAGENT_EFFORT"
assert_contains "CLAUDE.md template: a check that failed to start does not count" \
    "$(cat "$PC_REFS/claude-md-template.md" 2>/dev/null)" "a command that failed to start, does not count"
PC_TESTALL=$(sed -n '/^### Test All Command$/,/^### /p' "$PC_REFS/skills-templates.md" 2>/dev/null || true)
assert_contains "/test-all template: a suite that could not start is reported as not run" "$PC_TESTALL" "report it as not run"
PC_RULES=$(sed -n '/^### Writing commands/,/^### Paths/p' "$PC_PLUGIN/CLAUDE.md" 2>/dev/null || true)
assert_contains "plugin rules: consumer models include Sonnet 5.5" "$PC_RULES" "Sonnet 5.5"
assert_contains "plugin rules: consumer models include Haiku 5.5" "$PC_RULES" "Haiku 5.5"
assert_contains "plugin rules: consumer models include Fable 5.2" "$PC_RULES" "Fable 5.2"
assert_contains "plugin rules: the subagent model option cites its settings section" "$PC_RULES" "## Optional: Subagent Model"
if grep -qE 'Sonnet 5 or Haiku 4\.5|Opus 5 models over-verify' <<< "$PC_RULES"; then
    fail "plugin rules: no stale model set or Opus 5 reason" "found 'Sonnet 5 or Haiku 4.5' or 'Opus 5 models over-verify'"
else
    pass "plugin rules: no stale model set or Opus 5 reason"
fi

# --- Permission rules: a routine command the user can approve asks; no rule sits in both lists ---

if python3 - "$PC_REFS/settings-json-template.md" <<'PY' 2>/dev/null
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
sec = re.search(r"^## Core Template\n(.*?)(?=^## |\Z)", text, re.S | re.M)
perms = json.loads(re.search(r"^```json\n(.*?)^```", sec.group(1), re.S | re.M).group(1))["permissions"]
deny, ask = set(perms.get("deny", [])), set(perms.get("ask", []))
assert not deny & ask                      # deny is evaluated first, so the ask copy would never prompt
for rule in ("Bash(rm -rf *)", "Bash(rm -fr *)", "Bash(rm -r *)"):
    assert rule in ask                     # under deny the user cannot approve a routine cleanup
PY
then
    pass "settings template: recursive rm asks instead of denying, and no rule is in both lists"
else
    fail "settings template: recursive rm asks instead of denying, and no rule is in both lists" \
        "the Core Template needs the three rm rules under permissions.ask, and no rule under both deny and ask"
fi
assert_contains "init-project: merges missing ask rules into an existing settings.json" \
    "$(cat "$PC_PLUGIN/commands/init-project.md" 2>/dev/null)" "deny and ask rules"

# --- /sync-docs runs on one model: the command and the agent it launches pin the same one ---

# pc_model <file>: the frontmatter `model` value, or "none"
pc_model() {
    awk 'NR == 1 && /^---$/ { fm = 1; next }
         fm && /^---$/ { exit }
         fm && /^model:/ { sub(/^model:[[:space:]]*/, ""); print; found = 1 }
         END { if (!found) print "none" }' "$1" 2>/dev/null || echo "none"
}
assert_eq "sync-docs: the command runs on Sonnet" "sonnet" "$(pc_model "$PC_PLUGIN/commands/sync-docs.md")"
assert_eq "sync-docs: the doc-sync-checker agent pins the same model as the command" \
    "$(pc_model "$PC_PLUGIN/commands/sync-docs.md")" "$(pc_model "$PC_PLUGIN/agents/doc-sync-checker.md")"

# --- README rules: an existing README keeps its language and its section order, and the three
# commands that update one agree with the template's Update Rules ---

PC_README_RULES=$(sed -n '/^## Update Rules$/,$p' "$PC_REFS/readme-template.md" 2>/dev/null || true)
assert_contains "readme template: an existing single-language README stays single-language" "$PC_README_RULES" "single-language"
if grep -q 'Reorder' <<< "$PC_README_RULES"; then
    fail "readme template: an update keeps the user's section order" \
        "Update Rules reorder sections, which contradicts sync-docs (a sync fixes drift, not style)"
else
    pass "readme template: an update keeps the user's section order"
fi
for PC_CMD in generate-readme sync-docs init-project; do
    assert_contains "single-language README: $PC_CMD leaves it out of the bilingual check" \
        "$(cat "$PC_PLUGIN/commands/$PC_CMD.md" 2>/dev/null)" "single-language"
done

# --- Architecture figures: the style guide's Diagram Rules are the one source (ADR-010): an
# infographic from the aws-infographic skill when the session has it, a Mermaid flowchart otherwise ---

PC_DIAGRAM=$(sed -n '/^## Diagram Rules$/,/^## Bilingual Sync Validation$/p' "$PC_REFS/writing-style-guide.md" 2>/dev/null || true)
assert_contains "diagram rules: name the aws-infographic skill" "$PC_DIAGRAM" "aws-infographic"
assert_contains "diagram rules: keep the Mermaid flowchart for a session without the skill" "$PC_DIAGRAM" "flowchart TB"
assert_contains "diagram rules: one figure per language, embedded as <picture>" "$PC_DIAGRAM" "<picture>"
for PC_FILE in "$PC_REFS/readme-template.md" "$PC_REFS/docs-templates.md" "$PC_PLUGIN/commands/sync-docs.md" \
    "$PC_PLUGIN/commands/generate-readme.md" "$PC_PLUGIN/commands/init-project.md" "$PC_PLUGIN/agents/doc-sync-checker.md"; do
    assert_contains "architecture figures: ${PC_FILE##*/} cites the Diagram Rules" "$(cat "$PC_FILE" 2>/dev/null)" "Diagram Rules"
done

# --- CHANGELOG rules: the command can run what the template tells it to (stale tags put released
# changes under [Unreleased]) ---

PC_CL_TPL=$(cat "$PC_REFS/changelog-template.md" 2>/dev/null || true)
PC_CL_CMD=$(cat "$PC_PLUGIN/commands/generate-changelog.md" 2>/dev/null || true)
assert_contains "changelog template: lists the command that compares local tags with the remote" "$PC_CL_TPL" "git ls-remote --tags origin"
assert_contains "generate-changelog: pre-approves the remote tag check" "$(sed -n '1,6p' "$PC_PLUGIN/commands/generate-changelog.md" 2>/dev/null)" "Bash(git ls-remote --tags *)"
assert_contains "generate-changelog: stops when the remote has a release tag the local repository lacks" "$PC_CL_CMD" "git fetch --tags"
assert_contains "generate-changelog: a breaking entry needs a major version" "$PC_CL_CMD" "**BREAKING:**"

# --- Prose rules: the style guide is the one source for readable writing and AI-slop removal in
# English and Korean (ADR-003); it covers a document kept in one language, and every command that
# writes a document runs its Prose Check on the text it wrote ---

PC_GUIDE_FILE="$PC_REFS/writing-style-guide.md"
PC_STYLE=$(sed -n '/^## Writing Style$/,/^## Formatting Rules$/p' "$PC_GUIDE_FILE" 2>/dev/null || true)
assert_contains "prose rules: the guide has a Readability section for both languages" "$PC_STYLE" "### Readability (Both Languages)"
assert_contains "prose rules: the guide has a No AI Slop section for both languages" "$PC_STYLE" "### No AI Slop (Both Languages)"
assert_contains "prose rules: the English rules name the words to avoid" "$PC_STYLE" "leverage"
assert_contains "prose rules: the Korean rules cover translationese" "$PC_STYLE" "번역투"
assert_contains "prose rules: a rewrite for style keeps every fact" "$PC_STYLE" "never remove a fact"
assert_contains "prose rules: the guide covers a document kept in one language" \
    "$(sed -n '1,4p' "$PC_GUIDE_FILE" 2>/dev/null)" "one language"

# The Prose Check holds two marker patterns in one text block, English first and Korean second.
# Each line of a slop fixture carries one marker, and the plain fixtures carry none.
PC_PROSE=$(sed -n '/^## Prose Check$/,$p' "$PC_GUIDE_FILE" 2>/dev/null || true)
PC_PATTERNS=$(awk '/^```text$/ { f = 1; next } /^```$/ { f = 0 } f' <<< "$PC_PROSE")
PC_PAT_EN=$(sed -n '1p' <<< "$PC_PATTERNS")
PC_PAT_KO=$(sed -n '2p' <<< "$PC_PATTERNS")
# pc_hits <pattern> <file>: the number of lines the pattern matches, ignoring case
pc_hits() { grep -c -i -E -- "$1" "$2" 2>/dev/null || true; }
pc_lines() { grep -c '' "$1" 2>/dev/null || true; }
PC_FIX="tests/fixtures/prose"
if [[ -n "$PC_PAT_EN" && -n "$PC_PAT_KO" ]]; then
    pass "prose check: the guide gives an English and a Korean marker pattern"
    assert_eq "prose check: the English pattern finds every line of the slop fixture" \
        "$(pc_lines "$PC_FIX/slop-en.txt")" "$(pc_hits "$PC_PAT_EN" "$PC_FIX/slop-en.txt")"
    assert_eq "prose check: the English pattern leaves plain sentences alone" "0" "$(pc_hits "$PC_PAT_EN" "$PC_FIX/plain-en.txt")"
    assert_eq "prose check: the Korean pattern finds every line of the slop fixture" \
        "$(pc_lines "$PC_FIX/slop-ko.txt")" "$(pc_hits "$PC_PAT_KO" "$PC_FIX/slop-ko.txt")"
    assert_eq "prose check: the Korean pattern leaves plain sentences alone" "0" "$(pc_hits "$PC_PAT_KO" "$PC_FIX/plain-ko.txt")"
else
    fail "prose check: the guide gives an English and a Korean marker pattern" \
        "writing-style-guide.md needs a '## Prose Check' section whose text block has the English pattern on line 1 and the Korean pattern on line 2"
fi
for PC_CMD in generate-readme generate-changelog add-adr add-runbook add-reference-doc sync-docs init-project; do
    assert_contains "prose check: $PC_CMD runs the style guide's Prose Check" \
        "$(cat "$PC_PLUGIN/commands/$PC_CMD.md" 2>/dev/null)" "Prose Check"
done
assert_contains "prose rules: the plugin rules name the guide as their source" "$(cat "$PC_PLUGIN/CLAUDE.md" 2>/dev/null)" "Prose Check"
