# ADR-007: Mermaid Flowchart for Architecture Diagrams

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Date
2026-07-12

## Context
Generated documents (README, docs/architecture.md) represented architecture flows as ASCII box diagrams built from Unicode box-drawing characters (`┌─┐│└─┘▶▼`). ASCII diagrams are fragile to edit (alignment breaks on any width change), hard to diff meaningfully, render as plain text on GitHub, and are error-prone for automated regeneration during `/sync-docs`. The README template also had no Architecture section, so the critical flow was invisible at the repository entry point.

## Decision
All architecture flows and diagrams use Mermaid flowchart inside fenced ```mermaid code blocks, replacing ASCII box diagrams entirely. Conventions live in the shared writing-style-guide.md (Diagram Rules section, per ADR-003): `flowchart TB` with one `subgraph` per layer for full architecture diagrams, `flowchart LR` for data flow summaries, node labels in English in both language sections, diagrams duplicated identically across language sections. The README template gains a recommended Architecture section with a concise Mermaid flowchart and a link to docs/architecture.md.

## Alternatives Considered

### Keep ASCII box diagrams
- **Pros**: Renders identically in any plain-text viewer, including terminals.
- **Cons**: Fragile alignment; noisy diffs; no native GitHub rendering benefit; regeneration during doc sync frequently breaks layout.

### Mermaid for flows only, ASCII for structure diagrams
- **Pros**: Incremental migration; keeps familiar layer boxes.
- **Cons**: Two diagram systems to keep in sync and document; the layer structure is expressible in Mermaid `subgraph` anyway.

### Mermaid primary with ASCII fallback duplicated
- **Pros**: Covers renderers without Mermaid support.
- **Cons**: Every diagram maintained twice, doubling the bilingual duplication burden (4 copies per diagram); drift is inevitable.

## Consequences

### Positive
- GitHub renders diagrams natively; documents look professional without images.
- Diagrams are text-based and structurally editable: adding a component is a one-line change with a clean diff.
- Automated regeneration in `/sync-docs` and `doc-sync-checker` compares node names against directories reliably.
- README now surfaces the critical flow at the repository entry point.

### Negative
- Plain-text viewers (terminals, some IDE previews) show Mermaid source instead of a rendered diagram.
- Legacy documents with ASCII diagrams must be migrated; `/sync-docs` flags and converts them on the next run.

## References
- Spec: `docs/superpowers/specs/2026-07-12-mermaid-architecture-diagrams-design.md`
- Related: ADR-003 (shared writing-style-guide as single source of truth)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 날짜
2026-07-12

## 배경
생성 문서(README, docs/architecture.md)는 아키텍처 흐름을 유니코드 박스 문자(`┌─┐│└─┘▶▼`)로 구성한 ASCII 박스 다이어그램으로 표현했습니다. ASCII 다이어그램은 편집에 취약하고(폭이 바뀌면 정렬이 깨짐), 의미 있는 diff가 어렵고, GitHub에서 일반 텍스트로 렌더링되며, `/sync-docs`의 자동 재생성 시 오류가 발생하기 쉽습니다. 또한 README 템플릿에는 Architecture 섹션이 없어 핵심 흐름이 저장소 진입점에서 보이지 않았습니다.

## 결정
모든 아키텍처 흐름과 다이어그램은 ```mermaid 코드 블록 안의 Mermaid flowchart를 사용하며, ASCII 박스 다이어그램을 전면 대체합니다. 규칙은 공유 writing-style-guide.md(Diagram Rules 섹션, ADR-003 준수)에 정의합니다: 전체 아키텍처 다이어그램은 계층별 `subgraph`를 가진 `flowchart TB`, 데이터 흐름 요약은 `flowchart LR`, 노드 라벨은 양 언어 섹션 모두 영문 유지, 다이어그램은 언어 섹션 간 동일하게 복제. README 템플릿에는 간결한 Mermaid flowchart와 docs/architecture.md 링크를 포함하는 Architecture 권장 섹션이 추가됩니다.

## 검토한 옵션

### ASCII 박스 다이어그램 유지
- **장점**: 터미널을 포함한 모든 일반 텍스트 뷰어에서 동일하게 렌더링됩니다.
- **단점**: 정렬이 취약함; diff가 지저분함; GitHub 네이티브 렌더링 이점 없음; 문서 동기화 중 재생성 시 레이아웃이 자주 깨짐.

### 흐름만 Mermaid, 구조도는 ASCII 유지
- **장점**: 점진적 마이그레이션; 익숙한 계층 박스 유지.
- **단점**: 동기화하고 문서화해야 할 다이어그램 체계가 두 개가 됨; 계층 구조는 어차피 Mermaid `subgraph`로 표현 가능.

### Mermaid 기본 + ASCII 병기
- **장점**: Mermaid를 지원하지 않는 렌더러까지 커버.
- **단점**: 모든 다이어그램을 두 번 유지해야 하며, 이중 언어 복제 부담이 두 배가 됨(다이어그램당 4개 사본); 드리프트가 불가피함.

## 영향

### 긍정적
- GitHub이 다이어그램을 네이티브로 렌더링하여 이미지 없이도 문서가 전문적으로 보입니다.
- 다이어그램이 텍스트 기반이며 구조적으로 편집 가능합니다: 컴포넌트 추가가 깨끗한 diff의 한 줄 변경입니다.
- `/sync-docs`와 `doc-sync-checker`의 자동 재생성이 노드 이름과 디렉터리를 안정적으로 비교합니다.
- README가 저장소 진입점에서 핵심 흐름을 보여줍니다.

### 부정적
- 일반 텍스트 뷰어(터미널, 일부 IDE 미리보기)는 렌더링된 다이어그램 대신 Mermaid 소스를 표시합니다.
- ASCII 다이어그램이 있는 기존 문서는 마이그레이션이 필요합니다; `/sync-docs`가 다음 실행 시 플래그를 지정하고 변환합니다.

## 참고 자료
- 사양: `docs/superpowers/specs/2026-07-12-mermaid-architecture-diagrams-design.md`
- 관련: ADR-003 (모든 문서 생성 커맨드의 단일 기준점인 공유 writing-style-guide)
