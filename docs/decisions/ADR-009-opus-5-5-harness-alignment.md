# ADR-009: Opus 5.5 Harness Alignment

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted (extends ADR-008 and supersedes its decision 5 for the generated defaults)

## Context
Claude Opus 5.5 (`claude-opus-5-5`) became the Claude Code default model on most plans. Its default effort is `medium`, thinking cannot be turned off, and effort is the only depth control. It follows instructions literally and does not generalize an instruction given for one item to the others. Sonnet 5.5 and Haiku 5.5 followed (Claude Code v2.1.284 and v2.1.293). All three default to `medium`, accept `low` through `max`, and cannot turn thinking off, and at `low` or `medium` effort Sonnet 5.5 and Haiku 5.5 sometimes report a change as done without running a check. On Amazon Bedrock, Google Cloud, and Microsoft Foundry the `sonnet` and `haiku` aliases still resolve to 4.5 models, and Haiku 4.5 has no effort parameter, so the prompts the plugin ships must keep their output contracts explicit.

ADR-008 right-sized this repository's own harness. An audit of what the plugin generates for consumers, checked against the Claude Code documentation fetched on 2026-09-23, found five problems that ADR-008 left in place:

- **Generic components generated for everyone.** `/init-project` always wrote the code-review, refactor, release, and sync-docs skills, two agents, `notify.sh`, `tools/prompts/`, and placeholder module CLAUDE.md files. The sync-docs skill duplicated `/project-init:sync-docs`, and a project `code-review` skill shadows Claude Code's bundled `/code-review`. ADR-008 decision 5 kept these templates "for consumers who want them", but every consumer got them.
- **Pinned models.** The doc-sync-checker agent pinned `model: opus` and the generated agents pinned `model: sonnet`. A frontmatter `model` overrides `CLAUDE_CODE_SUBAGENT_MODEL`; an omitted `model` inherits the main model and still lets a team steer subagents with that variable.
- **Find-time review filters.** The code-reviewer agent and the code-review skill reported only findings scored 75 or above, and this repository's `/review` reported "only issues you are confident are real". For Opus 5.5 such a filter lowers recall; the prompting guidance is to report every finding with severity and confidence and filter downstream.
- **Procedural prompts.** Commands were long step lists (17 steps in `/init-project`, 11 phases in `/sync-docs`) ending in "verify" checklists, with inline copies of templates that had already drifted (Markdown badges that ADR-002 rejected) and relative template paths that do not resolve in a consumer project. `/health-check` had the model add up points by hand (the items summed to 195 against a 200-point grade table) and rewarded the generic skills that ADR-008 removed.
- **A gate with bypasses.** `secret-scan.sh` scanned only files staged before the command ran, so `git add . && git commit`, `git commit -am`, and `git -C <dir> commit` passed unscanned. Its `grep -P` is missing on macOS, and the AWS secret pattern's variable-width lookbehind failed with exit code 2 inside `2>/dev/null`, so it never matched. A relative registration (`bash .claude/hooks/secret-scan.sh`) exits 127 once Claude `cd`s into a subdirectory, and any exit other than 2 is non-blocking, so the gate opened without a message. A later review of the change found more gaps that predate it: renamed files and type changes went unscanned, a quoted git option value (`git -c user.name="Claude Code" commit`) hid the commit, current key formats (Anthropic keys with `_`, `sk-proj-` keys, private keys, JSON `password` keys) did not match, and the commit-msg hook's `sed -i` aborted every commit on macOS.

Verified facts that shaped the decision: Stop hooks can block with exit 2 and receive `stop_hook_active`; `${CLAUDE_PLUGIN_ROOT}` is substituted inline in plugin command, agent, and skill content and in `allowed-tools`, but is not set in the Bash tool's environment; `disable-model-invocation: true` works in command files; a top-level `effortLevel` in project settings applies to every model for everyone, while `maxEffortLevel` (Claude Code 2.1.267 or later) caps effort everywhere, including `effort` frontmatter; `Bash(x:*)` is equivalent to `Bash(x *)`; hook commands can use `$CLAUDE_PROJECT_DIR`, which stays at the session's checkout while the event's `cwd` follows Claude into a linked worktree; a command's `allowed-tools` grant lasts for the turn that invoked it and clears when the user sends the next message, while AskUserQuestion answers arrive in the same turn.

## Options Considered

### Option 1: Keep the generated harness as it is
- **Pros**: No change for consumers; nothing new to maintain.
- **Cons**: The commit gate keeps its bypasses; pinned models and find-time filters work against Opus 5.5; every consumer pays context for generic skills; inline copies and relative paths keep drifting or failing.

### Option 2: Right-size only this repository again
- **Pros**: Small change that repeats the ADR-008 pattern.
- **Cons**: The plugin's actual output, the consumer harness, keeps the generic defaults, pins, filters, and gate bypasses, and the repository drifts further from what it generates.

### Option 3: Tiered generation, a written prompt and model policy, and deterministic scripts
- **Pros**: Consumers get a lean Core and choose the rest; one written policy covers commands, agents, and templates; the checks a model can get wrong (scoring, hook-contract detection, bilingual structure, tests) move into code that returns the same answer on every model.
- **Cons**: A larger change; two new scripts with fixtures to maintain; existing consumers see behavior changes (see Consequences).

## Decision
Adopt Option 3.

1. **Tiers.** `/init-project` generates the **Core** tier always, the **Default** tier unless the user unchecks it, and the **Optional** tier only when the user checks it. It asks once, in its single up-front question round, with the accept/edit pattern of ADR-006, and each Optional item says when it helps.
   - Core: root CLAUDE.md; module CLAUDE.md only for modules with rules or gotchas the code does not show; `.claude/settings.json`; `secret-scan.sh` and `check-doc-sync.sh`; `scripts/setup.sh` and `scripts/install-hooks.sh`; architecture, onboarding, ADR and runbook templates; `docs/reference/` per detection; `tests/`; README, CHANGELOG, `.editorconfig`, `.gitignore`, `.env.example`; `.mcp.json` as `{"mcpServers": {}}`.
   - Default: `/test-all`, and `/review` with the code-reviewer agent as the single review path. Checking the Optional code-review skill replaces that pair, so the project still has one review path.
   - Optional: `/deploy` (runbook-driven, user-invoked only), the security-auditor agent, the code-review, refactor, and release skills, and the `session-context.sh`, `notify.sh`, and `verify-on-stop.sh` hooks.
   - Removed: the sync-docs skill template and `tools/prompts/`. This supersedes ADR-008 decision 5 for the generated defaults: the generic skills and the Notification hook stay in the templates, but only a user who checks them gets them.
2. **Model and effort.** Agents omit `model` and set `effort` only for bounded or mechanical work (doc-sync-checker: `effort: medium`). Plugin commands set neither, because they run in the user's main conversation. Generated templates follow the same policy, except the generated `/test-all` (`effort: low`). Generated settings never set `model` or a top-level `effortLevel`; `maxEffortLevel` is documented as an optional team cap. A team that wants lower-cost subagents sets `CLAUDE_CODE_SUBAGENT_MODEL` (`settings-json-template.md`, `## Optional: Subagent Model`) instead of pinning `model`, because a pin overrides that variable and `haiku` resolves to Haiku 4.5 on Amazon Bedrock, Google Cloud, and Microsoft Foundry. Because Opus 5.5, Sonnet 5.5, and Haiku 5.5 default to `medium`, the reviewers run at the user's level; the agent templates advise `/effort high` for a review that must catch edge cases instead of an `effort` pin, which would also lower an `xhigh` or `max` session.
3. **Report-all reviewers.** Reviewer and audit prompts (code-reviewer, security-auditor, the code-review skill, doc-sync-checker, this repository's `/review`) report every finding with severity and confidence, and filtering happens downstream.
4. **Prompt authoring rule.** A command is a goal, its inputs, rules with a reason each, an explicit output contract, a check the model can run, and the final report. Steps are numbered only where order matters or a step is hard to undo. No ALL-CAPS emphasis, one source of truth cited by path and heading, one up-front question round, and `<!-- TODO -->` instead of invented content. The question round uses the AskUserQuestion tool when it is available, split over several calls for a long checklist, because a chat reply starts a new turn and the command's `allowed-tools` grant does not carry over; without the tool, the command asks in one chat message. Generated prompts name the check too: the generated CLAUDE.md asks for its verify command to run before a change is reported done, and the generated `/test-all` reports a suite whose command could not start as not run, because Sonnet 5.5 and Haiku 5.5 at `low` or `medium` effort sometimes report a change done without a check that ran. The rule lives in `plugins/project-init/CLAUDE.md` under `## Rules`.
5. **Plugin file references.** Commands and agents reference `${CLAUDE_PLUGIN_ROOT}/skills/project-scaffolder/references/<file>.md` and `${CLAUDE_PLUGIN_ROOT}/scripts/<script>`, and stop instead of writing from memory when a template cannot be read.
6. **Deterministic checks in scripts.** `scripts/harness-check.sh` computes the deterministic part of `/health-check` and its score (the percentage of applicable points, graded A >= 80%, B >= 60%, C >= 40%, D >= 20%, F < 20%); with `--contract-only` it is the hook-contract detector that `/migrate-hooks` also uses. `scripts/check-bilingual.py` checks the ADR-001/002 structure; the document commands run it instead of prose checklists. The model keeps the judgment: CLAUDE.md quality, whether a pattern match is a real secret, whether an uncovered module needs a CLAUDE.md, recommended actions, and translation fidelity. Module CLAUDE.md coverage is a report, not a quota: a source root's own CLAUDE.md covers the modules below it, and `docs-modules` is INFO worth no points, because a correct lean project may have no module CLAUDE.md at all.
7. **Stop gates.** This repository registers `.claude/hooks/test-gate.sh` on `Stop` with a 180-second `timeout`; consumers get the same contract as the Optional `verify-on-stop.sh`, which runs a fast check (lint, typecheck, or unit tests) with a 120-second `timeout`. When the working tree is dirty, the gate runs its command and exits 2 with the failure summary. Every run records the tree's fingerprint, green or red, and a tree identical to the last run is skipped. With `stop_hook_active` set, the gate runs again only if the fingerprint changed, that is, Claude attempted a fix; otherwise the turn ends. Re-blocking is bounded to turns that changed something, and a red tree is reported once instead of on every prompt. A run starts by marking the tree pending, so a run the hook `timeout` kills is reported once in a `systemMessage` on the next Stop instead of counting as checked.
8. **Secret-scan commit scope.** `secret-scan.sh` scans what the commit will contain: staged files read from the index, renames and type changes included; modified tracked files for `-a`, `--all`, `-am`, or a pathspec; and untracked, non-ignored files, plus ignored files named by `add -f`, when the same command line runs `git add` or `git stage`. It detects `git -C <dir> commit`, `git -c k=v commit` with quoted values, a `cd` earlier on the line, and chained commits, matches with python3 `re`, and skips by path: its own script (`*secret-scan.sh`), the secret-pattern test, the two sample fixtures, Markdown files other than CLAUDE.md, `.env.example`, and lock files, so a key pasted into other Markdown, such as a README, runbook, or ADR, is not caught. A commit it cannot scan goes through (fail open, as ADR-008 documents) with a warning in `systemMessage` for the user and `additionalContext` for Claude, because stderr from a hook that exits 0 reaches neither. It carries the `project-init:commit-scope` marker, and `check-doc-sync.sh` the `project-init:module-coverage` marker, so that `harness-check.sh` and `/migrate-hooks` can find older copies. It reads the command text, so it is best effort: commits made by rebase, a git alias, or a script are not seen.
9. **Hook registration.** Every registration is `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh`. Gates have nothing after `.sh`; observational hooks end with `2>/dev/null || true` (ADR-004). Scripts resolve the project root as `${CLAUDE_PROJECT_DIR:-$PWD}`, and detection accepts both the relative and the anchored form. A hook that acts on the working tree uses the event's `cwd` instead (check-doc-sync: the edited file's directory) when it lies in the same repository, compared by `git rev-parse --git-common-dir`, so a linked worktree is checked where Claude works.

## Consequences

### Positive
- The commit gate catches `git add && git commit`, `git commit -am`, `git -C`, renames, and quoted git options, works on macOS, and the AWS secret pattern and current key formats match; a gate no longer opens silently after a `cd`, and a commit it cannot scan is reported instead of passing unnoticed.
- New consumer projects start smaller, and each Optional component says when it helps.
- `/health-check` gives the same score on every run and every model, and `/health-check` and `/migrate-hooks` share one contract detector.
- Subagents follow the session's model or a team-wide `CLAUDE_CODE_SUBAGENT_MODEL`, and reviews keep low-confidence findings visible to the reader.
- Bilingual structure drift and README or CHANGELOG version drift now fail the test suite, and in this repository the Stop gate keeps a red suite from ending a turn unnoticed.

### Negative
- Consumers who relied on the always-generated generic skills, security-auditor, `notify.sh`, or `session-context.sh` must opt in on the next `/init-project` run or copy them from the templates. Existing files are kept, not removed.
- The python3 dependency grows: secret-scan matching, `check-bilingual.py`, and JSON validity in `harness-check.sh` need it. Without python3, the commit gate lets commits through with a warning to the user and Claude, and the bilingual check does not run.
- In this repository, a turn that ends on a tree changed since the gate's last run ends with a full test run, and a red suite blocks once per changed tree, including a suite that is red on purpose.
- Quoted `password`, `secret`, and `api_key` values now block in any case and as JSON keys, so a committed local default such as `POSTGRES_PASSWORD: "postgres"` needs a `${VAR}` reference or a SKIP_PATTERNS entry.
- Projects generated by v2.3 or v2.4 get `secret-scan-scope` and `doc-sync-scope` warnings in `/health-check` until they run `/project-init:migrate-hooks`, and the new percentage score is not comparable with the former 0-200 scale.
- Two scripts and their fixtures are new code to maintain and test.

## References
- ADR-004 (hook failure policy), ADR-006 (detection plus confirmation), ADR-008 (right-sized repository harness)
- `plugins/project-init/CLAUDE.md` (`## Rules`), `plugins/project-init/commands/init-project.md` (Questions, Artifacts), `plugins/project-init/skills/project-scaffolder/SKILL.md`
- `plugins/project-init/scripts/harness-check.sh`, `plugins/project-init/scripts/check-bilingual.py`
- `plugins/project-init/skills/project-scaffolder/references/hook-scripts.md`, `settings-json-template.md`, `agents-templates.md`, `skills-templates.md`
- `.claude/settings.json`, `.claude/hooks/secret-scan.sh`, `.claude/hooks/test-gate.sh`
- `tests/hooks/test-hooks.sh`, `tests/structure/test-plugin-structure.sh`, `tests/structure/test-harness-check.sh`, `tests/structure/test-bilingual-docs.sh`
- Claude Code documentation (fetched 2026-09-23): model configuration (effort, `maxEffortLevel`), subagents (model resolution), skills (frontmatter, `disable-model-invocation`), hooks (Stop, exit 2, `$CLAUDE_PROJECT_DIR`), permissions (`:*` equivalence), plugins reference (`${CLAUDE_PLUGIN_ROOT}`); Anthropic prompting guidance for Opus 5.5
- Claude Code documentation (fetched 2026-10-24): model configuration (alias resolution per provider, per-model effort defaults, minimum versions for Opus 5.5, Sonnet 5.5, and Haiku 5.5), subagents (model order, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`); Anthropic migration guidance for Sonnet 5.5 and Haiku 5.5 (verification at low effort)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨 (ADR-008을 확장하며, 생성 기본값에 대해서는 ADR-008의 결정 5를 대체)

## 배경
Claude Opus 5.5(`claude-opus-5-5`)가 대부분의 요금제에서 Claude Code 기본 모델이 되었습니다. 기본 effort는 `medium`이고, thinking은 끌 수 없으며, 깊이를 조절하는 수단은 effort뿐입니다. 이 모델은 지시를 문자 그대로 따르고, 한 항목에 준 지시를 다른 항목으로 일반화하지 않습니다. 이어서 Sonnet 5.5와 Haiku 5.5가 나왔습니다(Claude Code v2.1.284, v2.1.293). 세 모델 모두 기본 effort가 `medium`이고, `low`부터 `max`까지 지원하며, thinking을 끌 수 없습니다. Sonnet 5.5와 Haiku 5.5는 `low`나 `medium` effort에서 검사를 실행하지 않고 변경을 완료했다고 보고하는 경우가 있습니다. Amazon Bedrock, Google Cloud, Microsoft Foundry에서는 `sonnet`과 `haiku` 별칭이 여전히 4.5 모델로 해석되고, Haiku 4.5에는 effort 파라미터가 없습니다. 따라서 플러그인이 배포하는 프롬프트는 출력 계약을 명시적으로 유지해야 합니다.

ADR-008은 이 저장소 자체의 하네스를 적정화했습니다. 플러그인이 소비자에게 생성하는 결과물을 2026-09-23에 받은 Claude Code 문서와 대조해 점검한 결과, ADR-008이 남겨 둔 문제 다섯 가지가 발견되었습니다.

- **모두에게 생성되는 범용 구성 요소.** `/init-project`는 code-review, refactor, release, sync-docs 스킬, 에이전트 2개, `notify.sh`, `tools/prompts/`, 자리표시자 모듈 CLAUDE.md를 항상 생성했습니다. sync-docs 스킬은 `/project-init:sync-docs`와 중복되고, 프로젝트의 `code-review` 스킬은 Claude Code 내장 `/code-review`를 가립니다. ADR-008 결정 5는 이 템플릿을 "원하는 소비자를 위해" 남겨 두었지만, 실제로는 모든 소비자가 받았습니다.
- **고정된 모델.** doc-sync-checker 에이전트는 `model: opus`를, 생성 에이전트는 `model: sonnet`을 고정했습니다. frontmatter의 `model`은 `CLAUDE_CODE_SUBAGENT_MODEL`보다 우선합니다. `model`을 생략하면 메인 모델을 상속하고, 팀은 그 변수로 서브에이전트 모델을 여전히 지정할 수 있습니다.
- **찾는 단계의 리뷰 필터.** code-reviewer 에이전트와 code-review 스킬은 75점 이상인 finding만 보고했고, 이 저장소의 `/review`는 "확신하는 이슈만" 보고했습니다. Opus 5.5에서 이런 필터는 재현율을 떨어뜨립니다. 프롬프팅 가이드는 모든 finding을 심각도와 확신도와 함께 보고하고 필터링은 다운스트림에서 하라고 권합니다.
- **절차 중심 프롬프트.** 커맨드는 긴 단계 목록(`/init-project` 17단계, `/sync-docs` 11단계)과 끝의 "verify" 체크리스트로 되어 있었습니다. 그 안에는 이미 어긋난 템플릿 인라인 사본(ADR-002가 기각한 Markdown 배지)과 소비자 프로젝트에서 해석되지 않는 상대 템플릿 경로가 있었습니다. `/health-check`는 모델이 점수를 손으로 합산하게 했고(항목 합계 195점에 200점 기준 등급표), ADR-008이 제거한 범용 스킬에 점수를 주었습니다.
- **우회로가 있는 게이트.** `secret-scan.sh`는 명령 실행 전에 이미 stage된 파일만 검사했으므로 `git add . && git commit`, `git commit -am`, `git -C <dir> commit`이 검사 없이 통과했습니다. `grep -P`는 macOS에 없고, AWS secret 패턴의 가변폭 lookbehind는 `2>/dev/null` 안에서 종료 코드 2로 실패해 한 번도 매칭되지 않았습니다. 상대 경로 등록(`bash .claude/hooks/secret-scan.sh`)은 Claude가 하위 디렉터리로 `cd`하면 127로 종료하고, 2가 아닌 종료 코드는 비차단이므로 게이트가 메시지 없이 열렸습니다. 이후 이 변경을 리뷰하면서 그 이전부터 있던 틈이 더 발견되었습니다. 이름을 바꾼 파일과 유형 변경은 검사하지 않았고, 따옴표로 감싼 git 옵션 값(`git -c user.name="Claude Code" commit`)이 커밋을 가렸으며, 현재 키 형식(`_`가 든 Anthropic 키, `sk-proj-` 키, 개인 키, JSON `password` 키)이 매칭되지 않았고, commit-msg 훅의 `sed -i`가 macOS에서 모든 커밋을 중단시켰습니다.

결정에 영향을 준 확인된 사실은 다음과 같습니다. Stop 훅은 exit 2로 차단할 수 있고 `stop_hook_active`를 받습니다. `${CLAUDE_PLUGIN_ROOT}`는 플러그인 커맨드, 에이전트, 스킬 본문과 `allowed-tools`에서 인라인으로 치환되지만 Bash 도구의 환경 변수로는 설정되지 않습니다. `disable-model-invocation: true`는 커맨드 파일에서도 동작합니다. 프로젝트 settings의 최상위 `effortLevel`은 모든 사람의 모든 모델에 적용되고, `maxEffortLevel`(Claude Code 2.1.267 이상)은 `effort` frontmatter를 포함해 모든 곳에서 effort 상한을 겁니다. `Bash(x:*)`는 `Bash(x *)`와 같습니다. 훅 명령은 `$CLAUDE_PROJECT_DIR`를 쓸 수 있는데, 이 값은 세션의 체크아웃에 머물고 이벤트의 `cwd`만 Claude를 따라 linked worktree로 들어갑니다. 커맨드의 `allowed-tools` 승인은 커맨드를 호출한 턴 동안만 유지되고 사용자가 다음 메시지를 보내면 사라지며, AskUserQuestion의 답은 같은 턴에 도착합니다.

## 검토한 옵션

### 옵션 1: 생성 하네스를 그대로 유지
- **장점**: 소비자에게 변화가 없고, 새로 유지보수할 것이 없음.
- **단점**: 커밋 게이트의 우회로가 남음; 고정 모델과 찾는 단계 필터가 Opus 5.5에 불리하게 작동; 모든 소비자가 범용 스킬에 컨텍스트를 지불; 인라인 사본과 상대 경로가 계속 어긋나거나 실패.

### 옵션 2: 이 저장소만 다시 적정화
- **장점**: ADR-008 방식을 반복하는 작은 변경.
- **단점**: 플러그인의 실제 결과물인 소비자 하네스에 범용 기본값, 모델 고정, 필터, 게이트 우회로가 그대로 남고, 저장소는 자신이 생성하는 구조와 더 멀어짐.

### 옵션 3: 티어 생성, 문서화된 프롬프트·모델 정책, 결정론적 스크립트
- **장점**: 소비자는 가벼운 Core를 받고 나머지를 직접 고름; 하나의 문서화된 정책이 커맨드, 에이전트, 템플릿에 모두 적용; 모델이 틀릴 수 있는 검사(점수 계산, 훅 계약 감지, 이중 언어 구조, 테스트)를 어떤 모델에서도 같은 답을 내는 코드로 옮김.
- **단점**: 변경 범위가 큼; 픽스처를 포함해 유지보수할 새 스크립트 2개; 기존 소비자에게 동작 변화가 생김(영향 참조).

## 결정
옵션 3을 채택합니다.

1. **티어.** `/init-project`는 **Core** 티어를 항상, **Default** 티어는 사용자가 해제하지 않는 한, **Optional** 티어는 사용자가 선택할 때만 생성합니다. 질문은 사전 질문 한 번에 ADR-006의 accept/edit 방식으로 묻고, Optional 항목마다 언제 유용한지 한 줄로 설명합니다.
   - Core: 루트 CLAUDE.md; 코드가 보여 주지 않는 규칙이나 주의점이 있는 모듈에만 모듈 CLAUDE.md; `.claude/settings.json`; `secret-scan.sh`, `check-doc-sync.sh`; `scripts/setup.sh`, `scripts/install-hooks.sh`; architecture, onboarding, ADR·런북 템플릿; 감지 결과에 따른 `docs/reference/`; `tests/`; README, CHANGELOG, `.editorconfig`, `.gitignore`, `.env.example`; `{"mcpServers": {}}`인 `.mcp.json`.
   - Default: `/test-all`, 그리고 유일한 리뷰 경로인 `/review`와 code-reviewer 에이전트. Optional code-review 스킬을 선택하면 이 둘을 대체하므로 리뷰 경로는 여전히 하나입니다.
   - Optional: `/deploy`(런북 기반, 사용자만 호출), security-auditor 에이전트, code-review·refactor·release 스킬, `session-context.sh`·`notify.sh`·`verify-on-stop.sh` 훅.
   - 제거: sync-docs 스킬 템플릿과 `tools/prompts/`. 이 항목은 생성 기본값에 대해 ADR-008 결정 5를 대체합니다. 범용 스킬과 Notification 훅은 템플릿에 남지만, 선택한 사용자만 받습니다.
2. **모델과 effort.** 에이전트는 `model`을 생략하고, `effort`는 범위가 정해졌거나 기계적인 작업에만 설정합니다(doc-sync-checker: `effort: medium`). 플러그인 커맨드는 사용자의 메인 대화에서 실행되므로 둘 다 설정하지 않습니다. 생성 템플릿도 같은 정책을 따르며, 예외는 생성되는 `/test-all`(`effort: low`)뿐입니다. 생성 settings에는 `model`이나 최상위 `effortLevel`을 넣지 않고, `maxEffortLevel`은 팀 상한 옵션으로 문서화합니다. 더 저렴한 서브에이전트를 원하는 팀은 `model`을 고정하지 않고 `CLAUDE_CODE_SUBAGENT_MODEL`(`settings-json-template.md`의 `## Optional: Subagent Model`)을 설정합니다. 고정 값은 이 변수보다 우선하고, `haiku`는 Amazon Bedrock, Google Cloud, Microsoft Foundry에서 Haiku 4.5로 해석되기 때문입니다. Opus 5.5, Sonnet 5.5, Haiku 5.5의 기본값이 `medium`이므로 리뷰어는 사용자가 정한 수준으로 실행됩니다. 에이전트 템플릿은 edge case를 놓치면 안 되는 리뷰에 `effort` 고정 대신 `/effort high`를 권합니다. 고정 값은 `xhigh`나 `max` 세션도 낮추기 때문입니다.
3. **모든 finding을 보고하는 리뷰어.** 리뷰·감사 프롬프트(code-reviewer, security-auditor, code-review 스킬, doc-sync-checker, 이 저장소의 `/review`)는 모든 finding을 심각도와 확신도와 함께 보고하고, 필터링은 다운스트림에서 합니다.
4. **프롬프트 작성 규칙.** 커맨드는 목표, 입력, 이유를 붙인 규칙, 명시적 출력 계약, 모델이 실행할 수 있는 검사, 최종 보고로 구성합니다. 순서가 중요하거나 되돌리기 어려운 단계에만 번호를 붙입니다. ALL-CAPS 강조를 쓰지 않고, 경로와 헤딩으로 인용하는 단일 출처를 두며, 사전 질문은 한 번만 하고, 내용을 지어내는 대신 `<!-- TODO -->`를 씁니다. 사전 질문은 AskUserQuestion 도구가 있으면 그 도구로 묻고, 긴 체크리스트는 여러 호출로 나눕니다. 채팅 답장은 새 턴을 시작하고 커맨드의 `allowed-tools` 승인은 그 턴으로 넘어가지 않기 때문입니다. 도구가 없으면 채팅 메시지 한 번으로 묻습니다. 생성되는 프롬프트도 검사를 명시합니다. 생성 CLAUDE.md는 변경을 완료로 보고하기 전에 검증 명령을 실행하라고 요구하고, 생성 `/test-all`은 명령이 시작되지 못한 스위트를 통과가 아니라 실행 안 됨으로 보고합니다. Sonnet 5.5와 Haiku 5.5는 `low`나 `medium` effort에서 실제로 실행된 검사 없이 변경을 완료로 보고하는 경우가 있기 때문입니다. 이 규칙은 `plugins/project-init/CLAUDE.md`의 `## Rules`에 있습니다.
5. **플러그인 파일 참조.** 커맨드와 에이전트는 `${CLAUDE_PLUGIN_ROOT}/skills/project-scaffolder/references/<file>.md`와 `${CLAUDE_PLUGIN_ROOT}/scripts/<script>`로 참조하고, 템플릿을 읽지 못하면 기억에 의존해 쓰지 않고 멈춥니다.
6. **스크립트로 옮긴 결정론적 검사.** `scripts/harness-check.sh`는 `/health-check`의 결정론적 부분과 점수(적용 가능한 점수 대비 백분율, 등급 A >= 80%, B >= 60%, C >= 40%, D >= 20%, F < 20%)를 계산합니다. `--contract-only`로 실행하면 `/migrate-hooks`도 쓰는 훅 계약 감지기가 됩니다. `scripts/check-bilingual.py`는 ADR-001/002 구조를 검사하며, 문서 커맨드는 산문 체크리스트 대신 이 스크립트를 실행합니다. 판단은 모델이 맡습니다: CLAUDE.md 품질, 패턴 매칭이 실제 시크릿인지 여부, 커버되지 않은 모듈에 CLAUDE.md가 필요한지 여부, 권장 조치, 번역 충실도. 모듈 CLAUDE.md 커버리지는 할당량이 아니라 보고입니다. source root 자신의 CLAUDE.md가 그 아래 모듈을 커버하고, `docs-modules`는 점수가 없는 INFO입니다. 올바르게 만든 가벼운 프로젝트에는 모듈 CLAUDE.md가 하나도 없을 수 있기 때문입니다.
7. **Stop 게이트.** 이 저장소는 `.claude/hooks/test-gate.sh`를 180초 `timeout`과 함께 `Stop`에 등록합니다. 소비자는 같은 계약을 Optional `verify-on-stop.sh`로 받으며, 이 훅은 120초 `timeout`으로 빠른 검사(lint, typecheck, 단위 테스트)를 실행합니다. 작업 트리에 변경이 있으면 게이트는 명령을 실행하고 실패 요약과 함께 exit 2로 종료합니다. 통과든 실패든 실행마다 트리 fingerprint를 기록하고, 마지막 실행과 같은 트리는 건너뜁니다. `stop_hook_active`가 설정되어 있으면 fingerprint가 바뀐 경우, 즉 Claude가 수정을 시도한 경우에만 다시 실행하고, 그렇지 않으면 턴이 끝납니다. 따라서 다시 차단하는 것은 무언가를 바꾼 턴으로 한정되고, 실패한 트리는 프롬프트마다가 아니라 한 번만 보고됩니다. 실행은 트리를 pending으로 표시하고 시작하므로, 훅 `timeout`으로 중단된 실행은 검사된 것으로 치지 않고 다음 Stop에서 `systemMessage`로 한 번 알립니다.
8. **secret-scan 커밋 범위.** `secret-scan.sh`는 커밋에 실제로 들어갈 내용을 검사합니다: index에서 읽은 stage된 파일(이름 변경과 유형 변경 포함); `-a`, `--all`, `-am`, pathspec이면 수정된 tracked 파일; 같은 명령줄에 `git add`나 `git stage`가 있으면 untracked·non-ignored 파일과 `add -f`로 지정한 ignore 파일까지. 따옴표로 감싼 값을 쓴 `git -C <dir> commit`, `git -c k=v commit`, 같은 줄 앞쪽의 `cd`, 체인으로 이은 커밋을 감지하고, python3 `re`로 매칭하며, 경로 기준으로 건너뛰는 대상은 자기 스크립트(`*secret-scan.sh`), 시크릿 패턴 테스트, 샘플 픽스처 2개, CLAUDE.md를 제외한 Markdown 파일, `.env.example`, lock 파일입니다. 따라서 README, 런북, ADR 같은 다른 Markdown에 붙여 넣은 키는 잡지 못합니다. 검사할 수 없는 커밋은 통과시키되(ADR-008이 기록한 fail open), 0으로 종료하는 훅의 stderr는 어느 쪽에도 닿지 않으므로 사용자에게는 `systemMessage`, Claude에게는 `additionalContext`로 경고합니다. `harness-check.sh`와 `/migrate-hooks`가 옛 사본을 찾을 수 있도록 `secret-scan.sh`는 `project-init:commit-scope` 마커를, `check-doc-sync.sh`는 `project-init:module-coverage` 마커를 담습니다. 명령 텍스트를 읽는 방식이므로 최선의 노력입니다: rebase, git alias, 스크립트가 만드는 커밋은 보지 못합니다.
9. **훅 등록.** 모든 등록은 `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh` 형식입니다. 게이트는 `.sh` 뒤에 아무것도 두지 않고, 관찰형 훅은 `2>/dev/null || true`로 끝납니다(ADR-004). 스크립트는 프로젝트 루트를 `${CLAUDE_PROJECT_DIR:-$PWD}`로 정하고, 감지 로직은 상대 경로 형식과 고정 경로 형식을 모두 받아들입니다. 작업 트리를 다루는 훅은 이벤트의 `cwd`(check-doc-sync는 편집한 파일의 디렉터리)가 같은 저장소에 있으면(`git rev-parse --git-common-dir`로 비교) 그쪽을 쓰므로, linked worktree는 Claude가 작업하는 곳에서 검사됩니다.

## 영향

### 긍정적
- 커밋 게이트가 `git add && git commit`, `git commit -am`, `git -C`, 이름 변경, 따옴표로 감싼 git 옵션을 잡고, macOS에서도 동작하며, AWS secret 패턴과 현재 키 형식이 매칭됩니다. `cd` 이후에도 게이트가 조용히 열리지 않고, 검사할 수 없는 커밋은 모르는 사이에 통과하지 않고 보고됩니다.
- 새 소비자 프로젝트가 더 작게 시작하고, Optional 구성 요소마다 언제 유용한지 설명이 붙습니다.
- `/health-check`는 실행할 때마다, 어떤 모델에서든 같은 점수를 내고, `/health-check`와 `/migrate-hooks`가 하나의 계약 감지기를 공유합니다.
- 서브에이전트가 세션 모델이나 팀 전체의 `CLAUDE_CODE_SUBAGENT_MODEL`을 따르고, 리뷰에서 확신도가 낮은 finding도 독자에게 보입니다.
- 이중 언어 구조 드리프트와 README·CHANGELOG 버전 드리프트가 이제 테스트 스위트를 실패시키고, 이 저장소에서는 Stop 게이트 덕분에 실패한 스위트가 눈에 띄지 않은 채 턴을 끝내지 않습니다.

### 부정적
- 항상 생성되던 범용 스킬, security-auditor, `notify.sh`, `session-context.sh`에 의존하던 소비자는 다음 `/init-project` 실행에서 직접 선택하거나 템플릿에서 복사해야 합니다. 기존 파일은 삭제되지 않고 유지됩니다.
- python3 의존이 커집니다. secret-scan 매칭, `check-bilingual.py`, `harness-check.sh`의 JSON 유효성 검사에 필요합니다. python3가 없으면 커밋 게이트는 사용자와 Claude에게 경고하고 커밋을 통과시키며, 이중 언어 검사는 실행되지 않습니다.
- 이 저장소에서는 게이트의 마지막 실행 이후 바뀐 트리에서 끝나는 턴이 전체 테스트 실행으로 끝나고, 실패한 스위트는 의도적으로 실패 상태를 유지하는 경우를 포함해 바뀐 트리마다 한 번 차단합니다.
- 따옴표로 감싼 `password`, `secret`, `api_key` 값은 이제 대소문자와 JSON 키 여부에 관계없이 차단되므로, `POSTGRES_PASSWORD: "postgres"` 같은 로컬 기본값을 커밋하려면 `${VAR}` 참조나 SKIP_PATTERNS 항목이 필요합니다.
- v2.3이나 v2.4로 생성한 프로젝트는 `/project-init:migrate-hooks`를 실행하기 전까지 `/health-check`에서 `secret-scan-scope`와 `doc-sync-scope` 경고를 받고, 새 백분율 점수는 기존 0-200 척도와 비교할 수 없습니다.
- 스크립트 2개와 그 픽스처가 유지보수하고 테스트할 새 코드가 됩니다.

## 참고 자료
- ADR-004(훅 실패 정책), ADR-006(감지와 사용자 확인), ADR-008(저장소 하네스 적정화)
- `plugins/project-init/CLAUDE.md`(`## Rules`), `plugins/project-init/commands/init-project.md`(Questions, Artifacts), `plugins/project-init/skills/project-scaffolder/SKILL.md`
- `plugins/project-init/scripts/harness-check.sh`, `plugins/project-init/scripts/check-bilingual.py`
- `plugins/project-init/skills/project-scaffolder/references/hook-scripts.md`, `settings-json-template.md`, `agents-templates.md`, `skills-templates.md`
- `.claude/settings.json`, `.claude/hooks/secret-scan.sh`, `.claude/hooks/test-gate.sh`
- `tests/hooks/test-hooks.sh`, `tests/structure/test-plugin-structure.sh`, `tests/structure/test-harness-check.sh`, `tests/structure/test-bilingual-docs.sh`
- Claude Code 문서(2026-09-23 수집): 모델 설정(effort, `maxEffortLevel`), 서브에이전트(모델 결정 순서), 스킬(frontmatter, `disable-model-invocation`), 훅(Stop, exit 2, `$CLAUDE_PROJECT_DIR`), 권한(`:*` 동등성), 플러그인 레퍼런스(`${CLAUDE_PLUGIN_ROOT}`); Opus 5.5용 Anthropic 프롬프팅 가이드
- Claude Code 문서(2026-10-24 수집): 모델 설정(제공자별 별칭 해석, 모델별 기본 effort, Opus 5.5·Sonnet 5.5·Haiku 5.5의 최소 버전), 서브에이전트(모델 결정 순서, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`); Sonnet 5.5와 Haiku 5.5용 Anthropic 마이그레이션 가이드(낮은 effort에서의 검증)
