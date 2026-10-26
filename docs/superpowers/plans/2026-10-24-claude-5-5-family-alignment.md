# Claude 5.5 Family Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the plugin's rules, templates, `harness-check.sh`, and docs with Opus 5.5, Sonnet 5.5, and Haiku 5.5 without changing the ADR-009 model and effort policy.

**Architecture:** Three groups of edits. (1) Fact and rule-reason refreshes in prose: the plugin rules, ADR-009, README, and CHANGELOG. (2) Template additions: an optional subagent-model settings block and a verification contract for the generated CLAUDE.md and `/test-all`. (3) One regex extension in `harness-check.sh` `compat-model-ids`. Every behavior or content change gets a failing test first in the existing Bash suites.

**Tech Stack:** Bash (`tests/run-all.sh` helpers `pass`, `fail`, `assert_eq`, `assert_contains`), Python 3 standard library for JSON checks, Markdown templates.

**Spec:** `docs/superpowers/specs/2026-10-24-claude-5-5-family-alignment-design.md`

## Global Constraints

- Agents keep omitting `model`. No `model` or `effort` pins are added anywhere.
- Reviewer agents (code-reviewer, security-auditor) keep inheriting the session effort.
- No new ADR. ADR-009 is corrected in place, both languages; its filename and title stay.
- No version bump. Entries go under `[Unreleased]`. Do not commit: the user reviews the working tree first.
- Bilingual docs keep identical structure in `# English` and `# 한국어` (ADR-001). Check them with `python3 plugins/project-init/scripts/check-bilingual.py FILE...`.
- Indentation: 4 spaces in shell and Python, 2 elsewhere. LF line endings. No emojis. No hardcoded counts of tests, files, or steps.
- Facts (fetched 2026-10-24): Opus 5.5, Sonnet 5.5, and Haiku 5.5 default to `medium` and accept `low` to `max`. Minimum Claude Code versions are v2.1.280 (Opus 5.5), v2.1.284 (Sonnet 5.5), and v2.1.293 (Haiku 5.5). `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` needs v2.1.257. On Amazon Bedrock, Google Cloud, Microsoft Foundry, and Claude Platform on AWS, `haiku` resolves to Haiku 4.5.

---

### Task 1: `harness-check.sh` flags pins to the superseded 5.0 IDs

**Files:**
- Modify: `plugins/project-init/scripts/harness-check.sh` (the `compat-model-ids` loop, `grep -qE 'claude-3([-.]|$)|claude-[a-z]+-4([-.@]|$)'`)
- Test: `tests/structure/test-harness-check.sh` (new section after the `hc_settings()` helper, before `hc_variant badjson`)

**Interfaces:**
- Consumes: test helpers `hc_variant NAME` (sets `HC_P`), `hc_run DIR`, `hc_line ID`, `hc_status DESC ID STATUS`; script function `fm_value` (strips quotes from frontmatter values).
- Produces: `compat-model-ids` reports `WARN` for `claude-opus-5`, `claude-sonnet-5`, and `claude-fable-5`, bare or followed by `[`, `@`, `:`, `-v<digit>`, or `-YYYYMMDD`. It reports `PASS` for `claude-opus-5-5`, `claude-sonnet-5-5`, `claude-haiku-5-5`, and `claude-fable-5-1`.

- [ ] **Step 1: Write the failing test**

Insert into `tests/structure/test-harness-check.sh` directly after the `hc_settings()` function and before `hc_variant badjson || true`:

```bash
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run-all.sh harness 2>&1 | grep -E 'pins:|Failed:'`
Expected: `pins: claude-sonnet-5 is an older model` FAILS (got `PASS`), and `pins: the [1m] form ...` FAILS. The `claude-sonnet-5-5` and `pins-new` assertions already pass.

- [ ] **Step 3: Extend the regex**

In `plugins/project-init/scripts/harness-check.sh`, replace

```bash
        if printf '%s' "$v" | grep -qE 'claude-3([-.]|$)|claude-[a-z]+-4([-.@]|$)'; then
```

with

```bash
        # 4.x and earlier, and the 5.0 IDs that Opus 5.5, Sonnet 5.5, and Fable 5.1 superseded
        if printf '%s' "$v" | grep -qE 'claude-3([-.]|$)|claude-[a-z]+-4([-.@]|$)|claude-(opus|sonnet|fable)-5($|\[|@|:|-v[0-9]|-[0-9]{8})'; then
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/run-all.sh harness 2>&1 | tail -6`
Expected: `Failed:  0`. Also run `bash -n plugins/project-init/scripts/harness-check.sh` (expected: no output).

- [ ] **Step 5: Do not commit** (user review pending)

---

### Task 2: Templates gain the subagent-model option and the verification contract

**Files:**
- Modify: `plugins/project-init/skills/project-scaffolder/references/settings-json-template.md` (append after `## Optional: Team Effort Cap`)
- Modify: `plugins/project-init/skills/project-scaffolder/references/agents-templates.md:9-10`
- Modify: `plugins/project-init/skills/project-scaffolder/references/claude-md-template.md:41`
- Modify: `plugins/project-init/skills/project-scaffolder/references/skills-templates.md` (`### Test All Command` body)
- Modify: `plugins/project-init/commands/init-project.md` (verify-on-stop line in the Components checklist)
- Modify: `plugins/project-init/skills/project-scaffolder/SKILL.md` (the `settings-json-template.md` line in the references list)
- Test: `tests/structure/test-prompt-contracts.sh` (append a new section at the end of the file)

**Interfaces:**
- Consumes: `PC_PLUGIN`, `PC_REFS` variables defined at the top of `test-prompt-contracts.sh`.
- Produces: the heading `## Optional: Subagent Model` in `settings-json-template.md`, which `agents-templates.md`, the plugin rules (Task 3), and ADR-009 (Task 4) cite verbatim.

- [ ] **Step 1: Write the failing tests**

Append to the end of `tests/structure/test-prompt-contracts.sh`:

```bash

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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/run-all.sh prompt 2>&1 | grep -E 'settings template:|agents template:|CLAUDE.md template:|/test-all template:|Failed:'`
Expected: all seven new assertions FAIL.

- [ ] **Step 3: Add `## Optional: Subagent Model` to `settings-json-template.md`**

Append at the end of the file (after the `maxEffortLevel` JSON block), separated by one blank line:

````markdown
## Optional: Subagent Model

Add `CLAUDE_CODE_SUBAGENT_MODEL` only when the team wants subagents on a lower-cost model than the session, for example read-heavy audits on Haiku 5.5 while sessions run Opus 5.5. It applies to every subagent without a `model` field, the generated agents included; a frontmatter `model`, or a model Claude passes for one run, still wins. The built-in Explore and Plan subagents keep their own model unless `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is also `"1"` (Claude Code 2.1.257 or later), which also overrides frontmatter `model`. On the Anthropic API, `haiku` resolves to Haiku 5.5 (Claude Code 2.1.293 or later). On Amazon Bedrock, Google Cloud, Microsoft Foundry, and Claude Platform on AWS it resolves to Haiku 4.5, which has no effort levels, so there also set `ANTHROPIC_DEFAULT_HAIKU_MODEL` to the provider's Haiku 5.5 model ID; that variable also sets the model for background tasks. A developer can set the variable in their own environment instead.

```json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```
````

- [ ] **Step 4: Update `agents-templates.md` `## Model, effort, and tools`**

Replace line 9:

```markdown
- **No `model`**, so the agents run on the main model and a team can steer every subagent with `CLAUDE_CODE_SUBAGENT_MODEL` (in the `env` block of `.claude/settings.json`, or per developer); `model: inherit` would block that variable. `/init-project` never adds a model. A team whose sessions run on Haiku can pin `model: sonnet` in one agent afterwards for stronger reviews.
```

with:

```markdown
- **No `model`**, so the agents run on the main model and a team can steer every subagent with `CLAUDE_CODE_SUBAGENT_MODEL` (in the `env` block of `.claude/settings.json`, or per developer); `model: inherit` would block that variable. `/init-project` never adds a model. For lower-cost subagents, such as Haiku 5.5 under an Opus 5.5 session, set that variable as `settings-json-template.md` `## Optional: Subagent Model` shows instead of pinning `model: haiku`, which resolves to Haiku 4.5 on Amazon Bedrock, Google Cloud, and Microsoft Foundry. A team whose sessions run on Haiku can pin `model: sonnet` in one agent afterwards for stronger reviews.
```

Replace line 10:

```markdown
- **No `effort`**: both agents do judgment work, so they inherit the session's level.
```

with:

```markdown
- **No `effort`**: both agents do judgment work, so they inherit the session's level, which is `medium` by default on Opus 5.5, Sonnet 5.5, and Haiku 5.5. For a review that must catch edge cases on Sonnet or Haiku, raise the session with `/effort high` instead of adding `effort` here, because frontmatter `effort` also lowers a session the user set to `xhigh` or `max`.
```

- [ ] **Step 5: Add the verification rule to `claude-md-template.md`**

Replace line 41:

```markdown
Verify a change: `<!-- the fastest command that proves a change works: unit tests, lint, or typecheck -->`
```

with:

```markdown
Verify a change: `<!-- the fastest command that proves a change works: unit tests, lint, or typecheck -->`
Run it before reporting a change done. A syntax-only check, or a command that failed to start, does not count; if it cannot run here, say which check you skipped and why.
```

- [ ] **Step 6: Add the not-run rule to the generated `/test-all`**

In `skills-templates.md` under `### Test All Command`, replace:

```markdown
Report the totals for each suite first (passed, failed, skipped), then each failure with `file:line` and the assertion message. If the cause is evident from the output, name it in one line. Do not change code unless asked, because the user decides whether a red test is a bug or a stale test.
```

with:

```markdown
Report the totals for each suite first (passed, failed, skipped), then each failure with `file:line` and the assertion message. When a suite's command could not start, for example because a tool or the project's dependencies are missing, report it as not run, with the error, never as passed. If the cause is evident from the output, name it in one line. Do not change code unless asked, because the user decides whether a red test is a bug or a stale test.
```

- [ ] **Step 7: Name the reason on the verify-on-stop option in `init-project.md`**

Replace:

```text
     [ ] verify-on-stop.sh: Stop gate that runs `<fast check>` when a turn ends on a changed tree and hands failures back to Claude; most useful with smaller models (Optional)
```

with:

```text
     [ ] verify-on-stop.sh: Stop gate that runs `<fast check>` when a turn ends on a changed tree and hands failures back to Claude; most useful with Sonnet or Haiku at low or medium effort, which sometimes report a change done without running a check (Optional)
```

- [ ] **Step 8: Update the references list in `SKILL.md`**

Replace:

```markdown
- [settings-json-template.md](references/settings-json-template.md) - settings.json deny list and hook registrations
```

with:

```markdown
- [settings-json-template.md](references/settings-json-template.md) - settings.json deny list, hook registrations, and the optional team effort cap and subagent model
```

- [ ] **Step 9: Run the tests to verify they pass**

Run: `bash tests/run-all.sh prompt 2>&1 | tail -6` then `bash tests/run-all.sh harness 2>&1 | tail -6`
Expected: `Failed:  0` for both. The harness `template:` checks extract the first `json` block of `settings-json-template.md`, so the new block, which comes last, does not affect them.

- [ ] **Step 10: Check the readers of the changed templates**

Run: `grep -rn -E 'settings-json-template|agents-templates|claude-md-template|skills-templates' plugins/project-init/commands plugins/project-init/agents`
Expected: each hit cites the template by path for shapes it copies. No hit restates the changed sentences, so no command needs an edit. If one does restate them, update it to match.

- [ ] **Step 11: Do not commit** (user review pending)

---

### Task 3: Plugin rules name the 5.5 family and the new check reason

**Files:**
- Modify: `plugins/project-init/CLAUDE.md` `## Rules` > `### Writing commands, agents, skills, and templates` (three bullets)
- Test: `tests/structure/test-prompt-contracts.sh` (append to the section added in Task 2)

**Interfaces:**
- Consumes: the heading `## Optional: Subagent Model` from Task 2.
- Produces: the rule text that ADR-009 decision 4 points to (`plugins/project-init/CLAUDE.md` `## Rules`).

- [ ] **Step 1: Write the failing tests**

Append to `tests/structure/test-prompt-contracts.sh`:

```bash
PC_RULES=$(sed -n '/^### Writing commands/,/^### Paths/p' "$PC_PLUGIN/CLAUDE.md" 2>/dev/null || true)
assert_contains "plugin rules: consumer models include Sonnet 5.5" "$PC_RULES" "Sonnet 5.5"
assert_contains "plugin rules: consumer models include Haiku 5.5" "$PC_RULES" "Haiku 5.5"
assert_contains "plugin rules: the subagent model option cites its settings section" "$PC_RULES" "## Optional: Subagent Model"
if grep -qE 'Sonnet 5 or Haiku 4\.5|Opus 5 models over-verify' <<< "$PC_RULES"; then
    fail "plugin rules: no stale model set or Opus 5 reason" "found 'Sonnet 5 or Haiku 4.5' or 'Opus 5 models over-verify'"
else
    pass "plugin rules: no stale model set or Opus 5 reason"
fi
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/run-all.sh prompt 2>&1 | grep -E 'plugin rules:|Failed:'`
Expected: all four `plugin rules:` assertions FAIL.

- [ ] **Step 3: Rewrite the three bullets**

Replace:

```markdown
- Prompts run on the consumer's model (Opus 5.5 by default, also Sonnet 5 or Haiku 4.5), so keep every output contract explicit (file paths, section headings, frontmatter keys, bilingual structure, exit codes, report format); smaller models do not infer them. Cut procedure, never contract.
```

with:

```markdown
- Prompts run on the consumer's model: Opus 5.5 by default, or Sonnet 5.5 or Haiku 5.5, and on Amazon Bedrock, Google Cloud, and Microsoft Foundry the `sonnet` and `haiku` aliases still resolve to 4.5 models. Keep every output contract explicit (file paths, section headings, frontmatter keys, bilingual structure, exit codes, report format); smaller models do not infer them. Cut procedure, never contract.
```

In the next bullet, replace the clause:

```markdown
and the final report; Opus 5 models over-verify and write long otherwise.
```

with:

```markdown
and the final report; a named check bounds verification on Opus, and Sonnet 5.5 and Haiku 5.5 at `low` or `medium` effort sometimes report work done without running any check unless the prompt names one.
```

Replace the model and effort bullet:

```markdown
- Model and effort: agents omit `model`, so `CLAUDE_CODE_SUBAGENT_MODEL` can still steer them, and set `effort` only for bounded or mechanical work. Plugin commands set neither, because they run in the user's main conversation. Generated templates follow the same policy, except the generated `/test-all` (`effort: low`). Generated settings never set `model` or top-level `effortLevel`, which would apply to every model for everyone; document `maxEffortLevel` as an option.
```

with:

```markdown
- Model and effort: agents omit `model`, so `CLAUDE_CODE_SUBAGENT_MODEL` can still steer them, and set `effort` only for bounded or mechanical work. Opus 5.5, Sonnet 5.5, and Haiku 5.5 all default to `medium`, so an agent without `effort` runs at the level the user chose. Plugin commands set neither, because they run in the user's main conversation. Generated templates follow the same policy, except the generated `/test-all` (`effort: low`). Generated settings never set `model` or top-level `effortLevel`, which would apply to every model for everyone; document `maxEffortLevel` and `CLAUDE_CODE_SUBAGENT_MODEL` (`settings-json-template.md` `## Optional: Subagent Model`) as options.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/run-all.sh prompt 2>&1 | tail -6`
Expected: `Failed:  0`.

- [ ] **Step 5: Do not commit** (user review pending)

---

### Task 4: ADR-009, README, and CHANGELOG reflect the 5.5 family

**Files:**
- Modify: `docs/decisions/ADR-009-opus-5-5-harness-alignment.md` (Context, Decision 2, Decision 4, References; both languages)
- Modify: `README.md` (Requirements and doc-sync-checker notes; both languages)
- Modify: `CHANGELOG.md` `[Unreleased]` (Added and Changed; both languages)
- Test: `python3 plugins/project-init/scripts/check-bilingual.py` on the three files, and `bash tests/run-all.sh structure`

**Interfaces:**
- Consumes: the heading `## Optional: Subagent Model` (Task 2), the regex scope (Task 1), and the rule text (Task 3).
- Produces: nothing that later tasks read.

- [ ] **Step 1: Record the bilingual baseline**

Run: `python3 plugins/project-init/scripts/check-bilingual.py docs/decisions/ADR-009-opus-5-5-harness-alignment.md README.md CHANGELOG.md; echo "exit=$?"`
Expected: `exit=0`. If it is not 0, note the pre-existing findings and leave them out of this task's scope.

- [ ] **Step 2: ADR-009 Context (English)**

Replace:

```markdown
Consumers of this plugin may still run Sonnet 5 or Haiku 4.5 (which has no effort parameter), and the `opus`/`sonnet` aliases resolve differently per provider, so the prompts the plugin ships must keep their output contracts explicit.
```

with:

```markdown
Sonnet 5.5 and Haiku 5.5 followed (Claude Code v2.1.284 and v2.1.293). All three default to `medium`, accept `low` through `max`, and cannot turn thinking off, and at `low` or `medium` effort Sonnet 5.5 and Haiku 5.5 sometimes report a change as done without running a check. On Amazon Bedrock, Google Cloud, and Microsoft Foundry the `sonnet` and `haiku` aliases still resolve to 4.5 models, and Haiku 4.5 has no effort parameter, so the prompts the plugin ships must keep their output contracts explicit.
```

- [ ] **Step 3: ADR-009 Context (Korean)**

Replace:

```markdown
이 플러그인의 소비자는 여전히 Sonnet 5나 Haiku 4.5(effort 파라미터 없음)를 쓸 수 있고, `opus`/`sonnet` 별칭은 제공자마다 다르게 해석됩니다. 따라서 플러그인이 배포하는 프롬프트는 출력 계약을 명시적으로 유지해야 합니다.
```

with:

```markdown
이어서 Sonnet 5.5와 Haiku 5.5가 나왔습니다(Claude Code v2.1.284, v2.1.293). 세 모델 모두 기본 effort가 `medium`이고, `low`부터 `max`까지 지원하며, thinking을 끌 수 없습니다. Sonnet 5.5와 Haiku 5.5는 `low`나 `medium` effort에서 검사를 실행하지 않고 변경을 완료했다고 보고하는 경우가 있습니다. Amazon Bedrock, Google Cloud, Microsoft Foundry에서는 `sonnet`과 `haiku` 별칭이 여전히 4.5 모델로 해석되고, Haiku 4.5에는 effort 파라미터가 없습니다. 따라서 플러그인이 배포하는 프롬프트는 출력 계약을 명시적으로 유지해야 합니다.
```

- [ ] **Step 4: ADR-009 Decision 2 (both languages)**

English: append to the end of the decision 2 paragraph (after `` `maxEffortLevel` is documented as an optional team cap.``):

```markdown
 A team that wants lower-cost subagents sets `CLAUDE_CODE_SUBAGENT_MODEL` (`settings-json-template.md`, `## Optional: Subagent Model`) instead of pinning `model`, because a pin overrides that variable and `haiku` resolves to Haiku 4.5 on Amazon Bedrock, Google Cloud, and Microsoft Foundry. Because Opus 5.5, Sonnet 5.5, and Haiku 5.5 default to `medium`, the reviewers run at the user's level; the agent templates advise `/effort high` for a review that must catch edge cases instead of an `effort` pin, which would also lower an `xhigh` or `max` session.
```

Korean: append to the end of decision 2 (after ``옵션으로 문서화합니다.``):

```markdown
 더 저렴한 서브에이전트를 원하는 팀은 `model`을 고정하지 않고 `CLAUDE_CODE_SUBAGENT_MODEL`(`settings-json-template.md`의 `## Optional: Subagent Model`)을 설정합니다. 고정 값은 이 변수보다 우선하고, `haiku`는 Amazon Bedrock, Google Cloud, Microsoft Foundry에서 Haiku 4.5로 해석되기 때문입니다. Opus 5.5, Sonnet 5.5, Haiku 5.5의 기본값이 `medium`이므로 리뷰어는 사용자가 정한 수준으로 실행됩니다. 에이전트 템플릿은 edge case를 놓치면 안 되는 리뷰에 `effort` 고정 대신 `/effort high`를 권합니다. 고정 값은 `xhigh`나 `max` 세션도 낮추기 때문입니다.
```

- [ ] **Step 5: ADR-009 Decision 4 (both languages)**

English: insert before ``The rule lives in `plugins/project-init/CLAUDE.md` under `## Rules`.``:

```markdown
Generated prompts name the check too: the generated CLAUDE.md asks for its verify command to run before a change is reported done, and the generated `/test-all` reports a suite whose command could not start as not run, because Sonnet 5.5 and Haiku 5.5 at `low` or `medium` effort sometimes report a change done without a check that ran. 
```

Korean: insert before ``이 규칙은 `plugins/project-init/CLAUDE.md`의 `## Rules`에 있습니다.``:

```markdown
생성되는 프롬프트도 검사를 명시합니다. 생성 CLAUDE.md는 변경을 완료로 보고하기 전에 검증 명령을 실행하라고 요구하고, 생성 `/test-all`은 명령이 시작되지 못한 스위트를 통과가 아니라 실행 안 됨으로 보고합니다. Sonnet 5.5와 Haiku 5.5는 `low`나 `medium` effort에서 실제로 실행된 검사 없이 변경을 완료로 보고하는 경우가 있기 때문입니다. 
```

- [ ] **Step 6: ADR-009 References (both languages)**

English: add after the `- Claude Code documentation (fetched 2026-09-23): ...` bullet:

```markdown
- Claude Code documentation (fetched 2026-10-24): model configuration (alias resolution per provider, per-model effort defaults, minimum versions for Opus 5.5, Sonnet 5.5, and Haiku 5.5), subagents (model order, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`); Anthropic migration guidance for Sonnet 5.5 and Haiku 5.5 (verification at low effort)
```

Korean: add after the `- Claude Code 문서(2026-09-23 수집): ...` bullet:

```markdown
- Claude Code 문서(2026-10-24 수집): 모델 설정(제공자별 별칭 해석, 모델별 기본 effort, Opus 5.5·Sonnet 5.5·Haiku 5.5의 최소 버전), 서브에이전트(모델 결정 순서, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`); Sonnet 5.5와 Haiku 5.5용 Anthropic 마이그레이션 가이드(낮은 effort에서의 검증)
```

- [ ] **Step 7: README (both languages)**

Replace the English requirement line:

```markdown
- Claude Code CLI (latest version; the optional `maxEffortLevel` setting needs Claude Code 2.1.267 or later)
```

with:

```markdown
- Claude Code CLI (latest version; Opus 5.5 needs Claude Code 2.1.280 or later, Sonnet 5.5 2.1.284, Haiku 5.5 2.1.293, and the optional `maxEffortLevel` setting 2.1.267)
```

Replace the Korean requirement line:

```markdown
- Claude Code CLI (최신 버전. 선택 설정 `maxEffortLevel`은 Claude Code 2.1.267 이상 필요)
```

with:

```markdown
- Claude Code CLI (최신 버전. Opus 5.5는 Claude Code 2.1.280 이상, Sonnet 5.5는 2.1.284 이상, Haiku 5.5는 2.1.293 이상, 선택 설정 `maxEffortLevel`은 2.1.267 이상 필요)
```

Replace the English doc-sync-checker note:

```markdown
- The agent inherits the session's model and runs at `effort: medium`; to run it on another model, set `CLAUDE_CODE_SUBAGENT_MODEL` (for example `sonnet`)
```

with:

```markdown
- The agent inherits the session's model and runs at `effort: medium`; to run it on another model, set `CLAUDE_CODE_SUBAGENT_MODEL` (for example `haiku` for a lower-cost audit; on Amazon Bedrock, Google Cloud, and Microsoft Foundry `haiku` resolves to Haiku 4.5)
```

Replace the Korean doc-sync-checker note:

```markdown
- 에이전트는 세션 모델을 상속하고 `effort: medium`으로 실행됩니다. 다른 모델로 실행하려면 `CLAUDE_CODE_SUBAGENT_MODEL`을 설정합니다(예: `sonnet`)
```

with:

```markdown
- 에이전트는 세션 모델을 상속하고 `effort: medium`으로 실행됩니다. 다른 모델로 실행하려면 `CLAUDE_CODE_SUBAGENT_MODEL`을 설정합니다(예: 비용을 낮추려면 `haiku`. Amazon Bedrock, Google Cloud, Microsoft Foundry에서는 `haiku`가 Haiku 4.5로 해석됨)
```

- [ ] **Step 8: CHANGELOG `[Unreleased]` (both languages)**

English `### Added`: insert directly after the `- Add `## Optional: Team Effort Cap` ...` line:

```markdown
- Add `## Optional: Subagent Model` to `settings-json-template.md`, documenting `CLAUDE_CODE_SUBAGENT_MODEL` (for example `haiku` for Haiku 5.5) as an optional team-wide subagent model, with its precedence and the Haiku 4.5 resolution on Amazon Bedrock, Google Cloud, and Microsoft Foundry
```

Korean `### Added`: insert directly after the `- `settings-json-template.md`에 `## Optional: Team Effort Cap` 추가: ...` line:

```markdown
- `settings-json-template.md`에 `## Optional: Subagent Model` 추가: `CLAUDE_CODE_SUBAGENT_MODEL`(예: Haiku 5.5용 `haiku`)을 팀 전체 서브에이전트 모델 옵션으로 문서화하고, 우선순위와 Amazon Bedrock, Google Cloud, Microsoft Foundry에서 Haiku 4.5로 해석되는 점을 안내
```

English `### Changed`: insert directly after the `- Mark ADR-008 as extended by ADR-009, ...` line (the last Changed item):

```markdown
- Align the plugin rules, ADR-009, and the README with the Claude 5.5 family: Opus 5.5, Sonnet 5.5, and Haiku 5.5 all default to `medium` effort, the `sonnet` and `haiku` aliases still resolve to 4.5 models on Amazon Bedrock, Google Cloud, and Microsoft Foundry, and the README lists the minimum Claude Code version for each model
- Ask the generated CLAUDE.md's verify command to run before a change is reported done (a syntax-only check or a command that failed to start does not count), and have the generated `/test-all` report a suite that could not start as not run, because Sonnet 5.5 and Haiku 5.5 at low or medium effort sometimes report a change done without a check
- Flag pins to the superseded `claude-opus-5`, `claude-sonnet-5`, and `claude-fable-5` IDs in the `harness-check.sh` `compat-model-ids` check
```

Korean `### Changed`: insert directly after the `- ADR-008을 ADR-009로 확장된 것으로 표시: ...` line:

```markdown
- 플러그인 규칙, ADR-009, README를 Claude 5.5 세대에 맞춤: Opus 5.5, Sonnet 5.5, Haiku 5.5는 모두 기본 effort가 `medium`이고, Amazon Bedrock, Google Cloud, Microsoft Foundry에서는 `sonnet`과 `haiku` 별칭이 여전히 4.5 모델로 해석되며, README에 모델별 최소 Claude Code 버전을 명시
- 생성 CLAUDE.md의 검증 명령을 변경 완료 보고 전에 실행하도록 하고(문법 검사나 시작에 실패한 명령은 검증으로 치지 않음), 생성 `/test-all`이 시작하지 못한 스위트를 실행 안 됨으로 보고하도록 변경. Sonnet 5.5와 Haiku 5.5는 low나 medium effort에서 검사 없이 변경을 완료로 보고하는 경우가 있기 때문
- `harness-check.sh`의 `compat-model-ids` 검사가 대체된 `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5` ID 고정도 표시
```

- [ ] **Step 9: Run the bilingual and structure checks**

Run: `python3 plugins/project-init/scripts/check-bilingual.py docs/decisions/ADR-009-opus-5-5-harness-alignment.md README.md CHANGELOG.md; echo "exit=$?"` then `bash tests/run-all.sh structure 2>&1 | tail -6`
Expected: `exit=0` (or only the pre-existing findings from Step 1), and `Failed:  0`.

- [ ] **Step 10: Do not commit** (user review pending)

---

### Task 5: Full verification and memory

**Files:**
- Modify: `/home/ec2-user/.claude/projects/-home-ec2-user-my-project-project-init/memory/harness-right-sizing-2026-09.md` (append a follow-up line)
- Modify: `/home/ec2-user/.claude/projects/-home-ec2-user-my-project-project-init/memory/MEMORY.md` (update the hook line if needed)

- [ ] **Step 1: Run the full suite**

Run: `bash tests/run-all.sh 2>&1 | tail -6`
Expected: `Failed:  0`.

- [ ] **Step 2: Run harness-check on this repository**

Run: `bash plugins/project-init/scripts/harness-check.sh . | grep -E 'compat-model|TOTAL'`
Expected: `PASS compat-model-ids` and `PASS compat-model-alias`. This repository pins no models.

- [ ] **Step 3: Grep for leftover stale model facts**

Run: `grep -rn -E 'Sonnet 5 or Haiku 4\.5|Opus 5 models over-verify|Sonnet 5나 Haiku 4\.5' --include='*.md' . | grep -v '^docs/superpowers/'`
Expected: no output.

- [ ] **Step 4: Update memory**

Append to `harness-right-sizing-2026-09.md`:

```markdown
Follow-up 2026-10-24: aligned with the Claude 5.5 family (Sonnet 5.5 and Haiku 5.5 joined Opus 5.5) without changing the ADR-009 policy. The user chose to keep inheriting the session model (Haiku 5.5 is documented as `CLAUDE_CODE_SUBAGENT_MODEL` in `settings-json-template.md` `## Optional: Subagent Model`) and to keep reviewers on the session effort (`/effort high` advice instead of a pin). ADR-009 was corrected in place, with no new ADR, because nothing was reversed. The generated CLAUDE.md and `/test-all` now name a real check, because Sonnet 5.5 and Haiku 5.5 at low or medium effort can report work done without one. Still uncommitted and in `[Unreleased]`.
```

- [ ] **Step 5: Report to the user**

List each file changed with a one-line reason, show the test totals and the harness-check result, and remind the user that nothing is committed.
