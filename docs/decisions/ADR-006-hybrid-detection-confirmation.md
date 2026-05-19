# ADR-006: Hybrid Detection + User Confirmation for Reference Doc Generation

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Date
2026-05-19

## Context
`/init-project` must decide which of the 8 implementation reference layers to generate. Three pure approaches exist: fully automatic (silent miss risk), fully interactive (cognitive load), and preset (edge-case mismatch).

## Decision
Run detection first (signal matrix in spec §5.1.1), then present results to the user with pre-checked boxes for the detected set, allowing edit before generation. Security is always pre-checked regardless of detection.

## Alternatives Considered

### Automatic only
- **Pros**: Requires no user interaction; minimal cognitive load.
- **Cons**: Empty projects produce nothing; detection errors propagate silently; user has no chance to add layers they know they need.

### Interactive only (pure checkbox menu)
- **Pros**: User retains full control; no silent misses.
- **Cons**: User repeats work the plugin can infer; cognitive overload for users unfamiliar with all 8 layers.

### Preset profiles (`web-app`, `cli-tool`, etc.)
- **Pros**: Speed; caters to common patterns.
- **Cons**: Any project that does not match a preset falls back to interactive anyway; adds complexity without solving the empty-project problem.

## Consequences

### Positive
- Empty projects work: zero detections + Security pre-checked + ability to add layers later with `/add-reference-doc`.
- False positives in detection are corrected by the user before they produce stale files.
- Users who know what they need can skip (or accelerate) manual selection for accurately detected layers.
- Maintains a single code path in `/init-project` Step 4.5 (no conditional branches).

### Negative
- Detection signal matrix must be kept accurate as code patterns evolve.
- If a layer is mis-detected and user approves without checking, stale reference docs are generated.

## References
- Spec: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
- Related: ADR-005

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 날짜
2026-05-19

## 배경
`/init-project`는 8개 구현 참고 계층 중 어느 것을 생성할지 결정해야 합니다. 세 가지 순수한 접근 방식이 존재합니다: 완전 자동(침묵의 누락 위험), 완전 상호작용(인지 부하), 프리셋(엣지 케이스 불일치).

## 결정
먼저 감지를 실행한 후(사양 §5.1.1의 신호 매트릭스), 감지된 집합에 대해 사전 체크된 체크박스를 사용자에게 제시하여 생성 전에 편집할 수 있도록 합니다. 보안은 감지 여부에 관계없이 항상 사전 체크됩니다.

## 검토한 옵션

### 완전 자동
- **장점**: 사용자 상호작용 불필요; 최소 인지 부하.
- **단점**: 빈 프로젝트는 아무것도 생성 안 함; 감지 오류가 침묵으로 전파됨; 사용자가 필요한 계층을 추가할 기회 없음.

### 완전 상호작용(순수 체크박스 메뉴)
- **장점**: 사용자가 전체 제어권 유지; 침묵의 누락 없음.
- **단점**: 사용자가 플러그인이 추론할 수 있는 작업을 반복; 8개 계층에 익숙하지 않은 사용자에게 인지 과부하.

### 프리셋 프로필(`web-app`, `cli-tool` 등)
- **장점**: 속도; 일반적인 패턴에 최적화.
- **단점**: 프리셋과 일치하지 않는 프로젝트는 어쨌든 상호작용으로 폴백; 빈 프로젝트 문제를 해결하지 않으면서 복잡성만 추가.

## 영향

### 긍정적
- 빈 프로젝트가 작동합니다: 감지 없음 + 보안 사전 체크 + 나중에 `/add-reference-doc`으로 계층 추가 가능.
- 감지 오류는 사용자가 생성 전에 수정하여 오래된 파일 생성을 방지합니다.
- 필요한 것을 아는 사용자는 정확하게 감지된 계층에 대해 수동 선택을 건너뛸 수 있습니다(또는 가속화).
- `/init-project` Step 4.5에서 단일 코드 경로 유지(조건부 분기 없음).

### 부정적
- 감지 신호 매트릭스는 코드 패턴이 진화함에 따라 정확하게 유지되어야 합니다.
- 계층이 잘못 감지되고 사용자가 확인 없이 승인하면 오래된 참고 문서가 생성됩니다.

## 참고 자료
- 사양: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
- 관련: ADR-005
