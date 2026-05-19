# ADR-005: Implementation Reference Docs Structure

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Date
2026-05-19

## Supersedes
—

## Context
The plugin needs a way to record per-layer implementation knowledge that is consistent across projects so new readers (humans and LLMs) can navigate any project initialized with `project-init` the same way.

## Decision
- 8 layer-specific reference docs under `docs/reference/`: infrastructure, data, api, iac, frontend, ui, security, agent-llm.
- All docs share a 5-section skeleton: Overview / Components / Key Decisions / Code Pointers / Cross-references.
- An auto-managed `docs/reference/INDEX.md` and a `## Implementation References` block in root `CLAUDE.md` keep navigation in sync, enforced via `<!-- AUTO-MANAGED:* -->` marker regions.
- Bilingual (Korean/English) per ADR-001, with shields.io anchor badges per ADR-002.

## Alternatives Considered

### Single monolithic `docs/implementation.md`
- **Pros**: One place to find everything.
- **Cons**: Too large, no cross-project navigation parity; all eight layers crammed into one file; difficult to maintain.

### Extension of `docs/architecture.md`
- **Pros**: Centralizes all design docs; re-uses bilingual infrastructure.
- **Cons**: Architecture is intentionally high-level; mixing it with per-layer detail blurs abstraction levels; makes the architecture doc unwieldy.

### Per-module CLAUDE.md absorption
- **Pros**: Layers already in modules; no new directory.
- **Cons**: Module ≠ layer; layers cut across modules; module-level docs become scattered.

## Consequences

### Positive
- New readers can rely on identical structure across projects.
- `/sync-docs` can validate Code Pointers cheaply.
- Extension to a 9th layer (e.g., Observability) requires only adding a new fenced block in `reference-doc-template.md` plus a one-line enum update.
- Separation of concerns: architecture is high-level and stable; implementation docs are layer-specific and evolve with code.

### Negative
- 8 new files to maintain and auto-sync during code changes.
- AUTO-MANAGED markers must be present and correctly positioned in INDEX.md and root CLAUDE.md.

## References
- Spec: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
- Related: ADR-001, ADR-002, ADR-003

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 날짜
2026-05-19

## 대체
—

## 배경
플러그인은 프로젝트 전반에 걸쳐 일관되게 계층별 구현 지식을 기록할 방법이 필요하므로, `project-init`으로 초기화된 모든 프로젝트를 새로운 독자(인간과 LLM)가 동일한 방식으로 탐색할 수 있어야 합니다.

## 결정
- `docs/reference/` 아래 8개 계층별 참고 문서: infrastructure, data, api, iac, frontend, ui, security, agent-llm.
- 모든 문서는 동일한 5섹션 구조를 공유합니다: Overview / Components / Key Decisions / Code Pointers / Cross-references.
- 자동 관리되는 `docs/reference/INDEX.md`와 루트 `CLAUDE.md`의 `## Implementation References` 블록이 내비게이션을 동기화 상태로 유지하며, `<!-- AUTO-MANAGED:* -->` 마커 영역으로 강제됩니다.
- ADR-001에 따라 이중언어(한국어/영어), ADR-002에 따라 shields.io 앵커 배지 사용.

## 검토한 옵션

### 단일 모놀리식 `docs/implementation.md`
- **장점**: 한 곳에서 모든 것을 찾을 수 있음.
- **단점**: 너무 커지고, 크로스 프로젝트 내비게이션 동등성 없음; 8개 계층이 한 파일에 몰려 있음; 유지 어려움.

### `docs/architecture.md` 확장
- **장점**: 모든 설계 문서 중앙화; 기존 이중언어 인프라 재사용.
- **단점**: 아키텍처는 의도적으로 상위 수준임; 계층별 세부사항과 혼합하면 추상화 수준이 흐릿해짐; 아키텍처 문서가 부피가 커짐.

### 모듈별 CLAUDE.md 통합
- **장점**: 계층이 이미 모듈에 있음; 새 디렉토리 불필요.
- **단점**: 모듈 ≠ 계층; 계층은 모듈 전반에 걸쳐 있음; 모듈 수준 문서가 흩어짐.

## 영향

### 긍정적
- 새로운 독자는 프로젝트 전반에 걸쳐 동일한 구조에 의존할 수 있습니다.
- `/sync-docs`는 Code Pointers를 저렴하게 검증할 수 있습니다.
- 9번째 계층 확장(예: Observability)은 `reference-doc-template.md`에 새 펜스드 블록을 추가하고 한 줄의 열거형 업데이트만 필요합니다.
- 관심사의 분리: 아키텍처는 상위 수준이고 안정적; 구현 문서는 계층 특정이고 코드와 함께 진화합니다.

### 부정적
- 8개의 새로운 파일을 유지 및 자동 동기화해야 합니다.
- AUTO-MANAGED 마커는 INDEX.md 및 루트 CLAUDE.md에 존재하고 올바르게 배치되어야 합니다.

## 참고 자료
- 사양: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
- 관련: ADR-001, ADR-002, ADR-003
