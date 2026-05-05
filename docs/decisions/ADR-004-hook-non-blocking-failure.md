# ADR-004: Hook Non-Blocking Failure Policy

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Context
The plugin registers four hooks in `.claude/settings.json`: SessionStart (`session-context.sh`), PreToolUse (`secret-scan.sh`), PostToolUse (`check-doc-sync.sh`), and Notification (`notify.sh`). Each hook is a Bash script invoked by Claude Code at a specific lifecycle point. A hook that exits non-zero or fails to execute can either be treated as an error that interrupts the user, or as a soft signal that is logged and ignored.

Hooks differ in intent:
- `secret-scan.sh` is a security gate. A detected secret should block the commit. It exits 1 deliberately when a secret is found.
- `session-context.sh`, `check-doc-sync.sh`, `notify.sh` are observational. They surface information (project state, doc-sync warnings, webhook notifications) but do not gate user actions. A failure here (missing tool, malformed git state, network error) should not interrupt the user.

The question is whether environmental failures of the observational hooks (Python missing, `find` failing on a permissions error, `curl` timing out) should propagate as user-visible errors.

## Options Considered

### Option 1: Strict mode -- every hook failure surfaces as an error
- **Pros**: Failures are loud; broken hooks are noticed and fixed quickly; no silent degradation.
- **Cons**: Environmental issues (missing optional dependency, transient git state, network failure) interrupt the user's actual work; hooks become a footgun for cross-platform installation.

### Option 2: Lenient mode -- observational hooks suppress all failures via `2>/dev/null || true`
- **Pros**: Hook environment issues never block the user; cross-platform installs work even when optional dependencies are missing; the user-visible experience is robust.
- **Cons**: Bugs in observational hooks can pass unnoticed; "silent failure" pattern violates the project's general preference for loud errors.

### Option 3: Per-hook policy -- security hooks exit on failure, observational hooks suppress
- **Pros**: Each hook's failure mode matches its intent; security gates remain strict, observational hooks remain robust.
- **Cons**: Reviewers must classify each hook by intent before reading the failure handling; new hook authors must consciously choose the policy.

## Decision
Adopt Option 3. The four hook scripts follow a per-hook policy:

- **Gate hooks** (`secret-scan.sh`): exit non-zero on the condition the hook is designed to gate (secret detected). Internal errors are not specially suppressed -- a broken gate hook should be visible.
- **Observational hooks** (`session-context.sh`, `check-doc-sync.sh`, `notify.sh`): wrap their invocation in `.claude/settings.json` with `2>/dev/null || true` so that any non-zero exit is swallowed by the harness. Internal failures may print stderr (which is then redirected to `/dev/null`); the user sees nothing.

The convention applies at the settings.json registration boundary, not inside the script:

```json
{
  "type": "command",
  "command": "bash .claude/hooks/check-doc-sync.sh \"$TOOL_INPUT_PATH\" 2>/dev/null || true"
}
```

Scripts themselves do not include defensive `|| true` wrappers internally; the boundary policy is the single enforcement point.

## Consequences

### Positive
- The user's actual work (running tools, committing code) is never interrupted by an observational hook bug or environmental issue.
- Security gates remain strict; a failing `secret-scan.sh` blocks the commit as intended.
- The `|| true` is centralized at the registration site, making the policy auditable in one file (`.claude/settings.json`).

### Negative
- Bugs in observational hooks fail silently. A regression in `check-doc-sync.sh` that prevents it from emitting any warnings will not be noticed by the user.
- Test coverage for hooks must compensate for the loss of runtime feedback. The 27 hook tests in `tests/hooks/test-hooks.sh` are how the project mitigates this.
- The pattern is not self-evident from the script source; readers must know to check `.claude/settings.json` registration to understand the failure-handling policy.

## References
- `.claude/settings.json`, hook registration entries
- `.claude/hooks/secret-scan.sh` (gate hook, exits 1 on detection)
- `.claude/hooks/session-context.sh`, `.claude/hooks/check-doc-sync.sh`, `.claude/hooks/notify.sh` (observational)
- `tests/hooks/test-hooks.sh` (27 tests compensating for silent-failure risk)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 배경
플러그인은 `.claude/settings.json`에 네 개의 훅을 등록합니다: SessionStart(`session-context.sh`), PreToolUse(`secret-scan.sh`), PostToolUse(`check-doc-sync.sh`), Notification(`notify.sh`). 각 훅은 Claude Code가 특정 생명주기 시점에 호출하는 Bash 스크립트입니다. 비정상 종료하거나 실행에 실패한 훅은 사용자를 중단시키는 오류로 처리하거나, 로깅 후 무시되는 약한 신호로 처리할 수 있습니다.

훅마다 의도가 다릅니다:
- `secret-scan.sh`는 보안 게이트입니다. 시크릿이 발견되면 커밋을 차단해야 합니다. 발견 시 의도적으로 1로 종료합니다.
- `session-context.sh`, `check-doc-sync.sh`, `notify.sh`는 관찰성 훅입니다. 정보(프로젝트 상태, 문서 동기화 경고, 웹훅 알림)를 표면화하지만 사용자 동작을 막지 않습니다. 환경 실패(도구 누락, 잘못된 git 상태, 네트워크 오류)가 사용자를 중단시켜서는 안 됩니다.

쟁점은 관찰성 훅의 환경적 실패(Python 누락, 권한 오류로 인한 `find` 실패, `curl` 타임아웃)가 사용자에게 보이는 오류로 전파되어야 하는가입니다.

## 검토한 옵션

### 옵션 1: 엄격 모드 -- 모든 훅 실패가 오류로 표면화
- **장점**: 실패가 시끄럽게 드러남; 깨진 훅이 빠르게 발견되고 수정됨; 무음 저하 없음.
- **단점**: 환경 문제(선택 의존성 누락, 일시적 git 상태, 네트워크 실패)가 사용자의 실제 작업을 중단시킴; 훅이 크로스 플랫폼 설치의 발에 차이는 돌이 됨.

### 옵션 2: 관대 모드 -- 관찰성 훅이 `2>/dev/null || true`로 모든 실패 억제
- **장점**: 훅 환경 문제가 사용자를 절대 막지 않음; 선택 의존성이 없어도 크로스 플랫폼 설치가 동작; 사용자 경험이 견고함.
- **단점**: 관찰성 훅의 버그가 무음으로 통과 가능; "조용한 실패" 패턴이 프로젝트의 일반적 "시끄러운 오류" 선호와 충돌.

### 옵션 3: 훅별 정책 -- 보안 훅은 실패 시 종료, 관찰성 훅은 억제
- **장점**: 각 훅의 실패 모드가 의도와 일치; 보안 게이트는 엄격, 관찰성 훅은 견고.
- **단점**: 리뷰어가 실패 처리를 읽기 전에 각 훅을 의도별로 분류해야 함; 신규 훅 작성자가 정책을 의식적으로 선택해야 함.

## 결정
옵션 3을 채택합니다. 네 개 훅 스크립트는 훅별 정책을 따릅니다:

- **게이트 훅**(`secret-scan.sh`): 훅이 게이트하도록 설계된 조건(시크릿 발견)에서 비정상 종료합니다. 내부 오류는 특별히 억제하지 않습니다 -- 깨진 게이트 훅은 보여야 합니다.
- **관찰성 훅**(`session-context.sh`, `check-doc-sync.sh`, `notify.sh`): `.claude/settings.json`의 호출을 `2>/dev/null || true`로 감싸 비정상 종료를 하니스가 삼키도록 합니다. 내부 실패는 stderr로 출력될 수 있으나(이후 `/dev/null`로 리다이렉트) 사용자에게는 보이지 않습니다.

이 관례는 스크립트 내부가 아니라 settings.json 등록 경계에서 적용합니다:

```json
{
  "type": "command",
  "command": "bash .claude/hooks/check-doc-sync.sh \"$TOOL_INPUT_PATH\" 2>/dev/null || true"
}
```

스크립트 자체에는 방어적 `|| true` 래퍼를 내부에 두지 않으며, 경계 정책이 단일 강제 지점입니다.

## 영향

### 긍정적
- 관찰성 훅의 버그나 환경 문제로 사용자의 실제 작업(도구 실행, 코드 커밋)이 중단되지 않습니다.
- 보안 게이트는 엄격하게 유지됩니다. 실패한 `secret-scan.sh`는 의도대로 커밋을 차단합니다.
- `|| true`가 등록 지점에 집중되어 있어 정책을 단일 파일(`.claude/settings.json`)에서 감사할 수 있습니다.

### 부정적
- 관찰성 훅의 버그가 무음으로 실패합니다. `check-doc-sync.sh`가 어떤 경고도 내보내지 못하게 만드는 회귀가 사용자에게 보이지 않습니다.
- 훅 테스트 커버리지가 런타임 피드백 손실을 보완해야 합니다. `tests/hooks/test-hooks.sh`의 27개 테스트가 프로젝트가 이를 완화하는 방식입니다.
- 패턴이 스크립트 소스에서 자명하지 않습니다. 독자는 실패 처리 정책을 이해하기 위해 `.claude/settings.json` 등록을 확인해야 합니다.

## 참고 자료
- `.claude/settings.json`, 훅 등록 항목
- `.claude/hooks/secret-scan.sh` (게이트 훅, 발견 시 1로 종료)
- `.claude/hooks/session-context.sh`, `.claude/hooks/check-doc-sync.sh`, `.claude/hooks/notify.sh` (관찰성)
- `tests/hooks/test-hooks.sh` (조용한 실패 위험을 보완하는 27개 테스트)
