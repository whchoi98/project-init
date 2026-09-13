# ADR-008: Right-Sized Harness for Frontier Models

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Context
This repository is developed with frontier models (Claude Fable 5.1, Claude Opus 5). Its own harness had grown to four hooks, four skills, three commands (up to 140 lines each), and two agents, largely mirroring what the plugin generates for consumers. An audit found three classes of problems:

- **Dead components.** The PostToolUse and Notification hooks depended on `$TOOL_INPUT_PATH`, `$EVENT`, and `$MESSAGE` environment variables that Claude Code never sets (events arrive as JSON on stdin), so they exited silently. The `.claude/agents/*.yml` files were never loaded because subagents must be Markdown. The gate hook `secret-scan.sh` was registered with `|| true` and exited 1, which Claude Code treats as non-blocking, so it could not block anything.
- **Duplication.** The code-review skill, `/review` command, and code-reviewer agent described the same procedure three times. The release skill duplicated `docs/runbooks/release.md` and `/deploy`. The sync-docs skill duplicated the plugin's `/sync-docs`.
- **Instructions a frontier model does not need.** Generic refactoring principles, generic git error-recovery playbooks, confidence-scoring rubrics, and hardcoded counts (`169 tests`, `12 template files`, `27 tests`) that drifted after every change and gave the model nothing it could not derive in one command.

## Options Considered

### Option 1: Keep the harness as the plugin's showcase
- **Pros**: Repository mirrors generated output one-to-one.
- **Cons**: Keeps dead hooks and unloaded agents in place; every session pays context for guidance the model does not need; counts keep drifting.

### Option 2: Remove every hook, skill, command, and agent
- **Pros**: Minimal context, nothing to maintain.
- **Cons**: Loses deterministic guarantees that prompts cannot give (secret gate at commit time, session context, a reminder when a new plugin directory lacks a CLAUDE.md), and loses the test bed for the hook templates.

### Option 3: Keep only deterministic value, fix the hook contract, delete duplicates
- **Pros**: Hooks do what prompts cannot and are now correct; commands carry only repo-specific checks; the repository still exercises the hook templates through tests.
- **Cons**: The repository no longer mirrors the generated project structure exactly; consumers on smaller models may still want the removed generic skills, which remain in the plugin templates.

## Decision
Adopt Option 3.

1. **Hook contract.** Every hook reads the event JSON from stdin (`tool_input.file_path`, `tool_input.command`, `message`) and accepts the same value as `$1` for tests. Gate hooks block with exit 2 and a stderr message and are registered without `|| true`. PostToolUse reminders are returned as `hookSpecificOutput.additionalContext`. `secret-scan.sh` gates only `git commit`.
2. **Removed from this repository.** The Notification hook, the four generic skills, and the two `.yml` agents. `check-doc-sync.sh` keeps only the module-CLAUDE.md check relevant to `plugins/`.
3. **Commands.** `/review`, `/test-all`, and `/deploy` list repo-specific checks (bilingual parity, version sync, hook contract, template-to-command sync) and point to the runbook instead of restating generic procedures.
4. **No hardcoded counts** in CLAUDE.md files, runbooks, or command docs; the test runner prints the live total.
5. **Plugin templates** receive the same hook-contract and agent-format fixes so generated projects work; the generic skills and the Notification hook stay available in the templates for consumers who want them.

## Consequences

### Positive
- The secret gate actually blocks commits; the module-doc reminder actually reaches Claude.
- Per-session context shrinks: `.claude/` went from four hooks, four skills, three long commands, and two agents to three hooks and three short commands.
- Drift-prone numbers are gone from the docs the model reads.

### Negative
- The repository and the generated project structure differ; the README's "Generated Project Structure" describes consumers' projects, not this one.
- Hooks depend on `python3` to parse JSON; on a machine without it, the gate fails open (exit 0) and reminders are skipped.
- ADR-004's description of `secret-scan.sh` (exit 1) is superseded by this decision; ADR-004 is amended to reference exit 2.

## References
- `.claude/settings.json`, `.claude/hooks/`, `.claude/commands/`
- `plugins/project-init/skills/project-scaffolder/references/hook-scripts.md`, `settings-json-template.md`, `agents-templates.md`
- `tests/hooks/test-hooks.sh` (stdin contract and exit-2 tests)
- Claude Code documentation: hooks reference (stdin JSON, exit codes), subagents (Markdown only)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 배경
이 저장소는 최신 모델(Claude Fable 5.1, Claude Opus 5)로 개발됩니다. 저장소 자체 하네스는 훅 4개, 스킬 4개, 커맨드 3개(최대 140줄), 에이전트 2개까지 늘어나 플러그인이 소비자에게 생성해 주는 구조를 그대로 복제하고 있었습니다. 점검 결과 세 부류의 문제가 발견되었습니다.

- **동작하지 않는 구성 요소.** PostToolUse·Notification 훅은 Claude Code가 설정하지 않는 `$TOOL_INPUT_PATH`, `$EVENT`, `$MESSAGE` 환경변수에 의존해(이벤트는 stdin JSON으로 전달됨) 조용히 종료되었습니다. `.claude/agents/*.yml` 파일은 서브에이전트가 Markdown이어야 하므로 로드되지 않았습니다. 게이트 훅 `secret-scan.sh`는 `|| true`로 등록되고 exit 1을 사용해(Claude Code는 비차단으로 처리) 아무것도 차단할 수 없었습니다.
- **중복.** code-review 스킬, `/review` 커맨드, code-reviewer 에이전트가 같은 절차를 세 번 서술했습니다. release 스킬은 `docs/runbooks/release.md`와 `/deploy`를, sync-docs 스킬은 플러그인의 `/sync-docs`를 중복했습니다.
- **최신 모델에 불필요한 지시.** 범용 리팩터링 원칙, 범용 git 오류 복구 절차, 신뢰도 점수 기준표, 변경마다 어긋나는 하드코딩 개수(`169 tests`, `12 template files`, `27 tests`)는 모델이 한 번의 명령으로 얻을 수 없는 정보를 주지 못했습니다.

## 검토한 옵션

### 옵션 1: 플러그인 쇼케이스로서 하네스 유지
- **장점**: 저장소가 생성 결과물과 1:1로 일치.
- **단점**: 죽은 훅과 로드되지 않는 에이전트가 그대로 남음; 매 세션마다 모델에 불필요한 지침에 컨텍스트를 지불; 개수 드리프트 지속.

### 옵션 2: 훅·스킬·커맨드·에이전트 전부 제거
- **장점**: 최소 컨텍스트, 유지보수 대상 없음.
- **단점**: 프롬프트가 보장할 수 없는 결정론적 장치(커밋 시 시크릿 게이트, 세션 컨텍스트, 새 플러그인 디렉터리에 CLAUDE.md가 없을 때의 리마인드)를 잃고, 훅 템플릿의 테스트 베드도 잃음.

### 옵션 3: 결정론적 가치만 유지, 훅 계약 수정, 중복 삭제
- **장점**: 훅은 프롬프트가 못 하는 일을 하며 이제 올바르게 동작; 커맨드는 저장소 고유 점검만 담음; 저장소가 테스트를 통해 훅 템플릿을 계속 검증.
- **단점**: 저장소가 생성 프로젝트 구조와 정확히 일치하지 않음; 소형 모델을 쓰는 소비자는 제거된 범용 스킬을 여전히 원할 수 있으며, 이는 플러그인 템플릿에 남겨둠.

## 결정
옵션 3을 채택합니다.

1. **훅 계약.** 모든 훅은 stdin의 이벤트 JSON(`tool_input.file_path`, `tool_input.command`, `message`)을 읽고, 테스트를 위해 같은 값을 `$1`로도 받습니다. 게이트 훅은 exit 2와 stderr 메시지로 차단하며 `|| true` 없이 등록합니다. PostToolUse 리마인드는 `hookSpecificOutput.additionalContext`로 반환합니다. `secret-scan.sh`는 `git commit`만 게이트합니다.
2. **이 저장소에서 제거.** Notification 훅, 범용 스킬 4개, `.yml` 에이전트 2개. `check-doc-sync.sh`는 `plugins/`에 관련된 모듈 CLAUDE.md 검사만 남깁니다.
3. **커맨드.** `/review`, `/test-all`, `/deploy`는 저장소 고유 점검(양언어 동일 구조, 버전 동기화, 훅 계약, 템플릿-커맨드 동기화)만 나열하고, 범용 절차를 반복하는 대신 런북을 가리킵니다.
4. **하드코딩 개수 금지.** CLAUDE.md, 런북, 커맨드 문서에 개수를 적지 않습니다. 테스트 러너가 실시간 합계를 출력합니다.
5. **플러그인 템플릿**에도 같은 훅 계약·에이전트 형식 수정을 적용해 생성 프로젝트가 동작하게 합니다. 범용 스킬과 Notification 훅은 원하는 소비자를 위해 템플릿에 남겨둡니다.

## 영향

### 긍정적
- 시크릿 게이트가 실제로 커밋을 차단하고, 모듈 문서 리마인드가 실제로 Claude에 전달됩니다.
- 세션당 컨텍스트가 줄어듭니다. `.claude/`는 훅 4개·스킬 4개·긴 커맨드 3개·에이전트 2개에서 훅 3개·짧은 커맨드 3개로 축소되었습니다.
- 모델이 읽는 문서에서 드리프트가 잦은 숫자가 사라졌습니다.

### 부정적
- 저장소와 생성 프로젝트 구조가 달라집니다. README의 "Generated Project Structure"는 소비자 프로젝트를 설명하며 이 저장소와는 다릅니다.
- 훅이 JSON 파싱에 `python3`를 필요로 합니다. 없는 환경에서는 게이트가 열린 채(exit 0) 동작하고 리마인드는 생략됩니다.
- ADR-004의 `secret-scan.sh` 설명(exit 1)은 이 결정으로 대체되며, ADR-004는 exit 2를 참조하도록 보완했습니다.

## 참고 자료
- `.claude/settings.json`, `.claude/hooks/`, `.claude/commands/`
- `plugins/project-init/skills/project-scaffolder/references/hook-scripts.md`, `settings-json-template.md`, `agents-templates.md`
- `tests/hooks/test-hooks.sh` (stdin 계약 및 exit 2 테스트)
- Claude Code 문서: hooks 레퍼런스(stdin JSON, 종료 코드), subagents(Markdown 전용)
