# ADR-001: Bilingual Documentation Policy

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Context
project-init is authored by a Korean-speaking maintainer, but Claude Code itself is a global tool and the plugin is distributed through a global marketplace. End users include both Korean speakers (the primary author audience) and the global Claude Code community. A documentation language policy must balance native-language clarity for the primary audience with global accessibility, while staying maintainable for a single-maintainer project.

## Options Considered

### Option 1: English only
- **Pros**: Single source of truth, lowest maintenance cost, conforms to global open-source norms.
- **Cons**: Korean readers lose native-language nuance for a project authored in their language; the maintainer's own first-pass writing requires translation.

### Option 2: Korean only
- **Pros**: Matches the maintainer's primary working language; lowest authoring friction.
- **Cons**: Excludes the majority of the global Claude Code marketplace audience; reduces external contribution.

### Option 3: Bilingual (English + Korean) with identical structure
- **Pros**: Serves both audiences; forces clarity by requiring direct translation; documents are self-checking (mismatched sections reveal incomplete updates).
- **Cons**: Roughly doubles documentation volume and maintenance cost; both sections must stay in sync on every change.

## Decision
Adopt Option 3. All user-facing documents (README, CHANGELOG, architecture, ADR, runbook) are bilingual with identical structure in both sections. English appears first, Korean second (see ADR-002 for ordering and navigation rationale). Code blocks, tables, commands, and file paths are duplicated identically in both sections; only descriptive text is translated.

## Consequences

### Positive
- Both Korean and global audiences can read in their preferred language without losing detail.
- Identical-structure rule turns the second section into a self-check: missing sub-sections expose incomplete updates.
- Bilingual output is a differentiator versus single-language plugins in the marketplace.

### Negative
- Documentation volume is roughly doubled, increasing review and maintenance burden.
- Every doc-modifying change must update both sections; partial updates create drift.
- A shared style guide and per-document checklists are required to keep both sections aligned (resolved by ADR-003).

## References
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`
- ADR-002 (HTML anchor navigation, the implementation mechanism)
- ADR-003 (Shared writing-style-guide as single source of truth)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 배경
project-init은 한국어 사용자가 작성한 프로젝트이지만, Claude Code 자체는 글로벌 도구이며 플러그인 마켓플레이스도 글로벌입니다. 최종 사용자는 한국어 사용자(주요 작성자 독자층)와 글로벌 Claude Code 커뮤니티를 모두 포함합니다. 문서 언어 정책은 주 독자층을 위한 모국어 명확성과 글로벌 접근성 사이의 균형을 잡으면서, 1인 메인테이너 프로젝트에서 유지 가능해야 합니다.

## 검토한 옵션

### 옵션 1: 영어 전용
- **장점**: 단일 진실원, 최저 유지 비용, 글로벌 오픈소스 관례 부합.
- **단점**: 작성자의 모국어로 작성된 프로젝트인데 한국어 독자가 모국어 뉘앙스를 잃음; 메인테이너의 초안 자체가 번역을 필요로 함.

### 옵션 2: 한국어 전용
- **장점**: 메인테이너의 주 사용 언어와 일치; 작성 마찰 최소.
- **단점**: 글로벌 Claude Code 마켓플레이스 독자 대다수를 배제; 외부 기여 감소.

### 옵션 3: 이중언어 (영어 + 한국어), 동일 구조
- **장점**: 양쪽 독자 모두 지원; 직역을 강제하므로 명확성 향상; 두 섹션 불일치가 미완성 업데이트를 자동 노출.
- **단점**: 문서 분량과 유지 비용이 약 2배 증가; 변경 시 두 섹션을 동시에 갱신해야 함.

## 결정
옵션 3을 채택합니다. 모든 사용자 대면 문서(README, CHANGELOG, architecture, ADR, runbook)는 두 섹션이 동일한 구조를 갖는 이중언어로 작성합니다. 영어가 먼저, 한국어가 다음에 배치됩니다(순서 및 내비게이션 근거는 ADR-002 참조). 코드 블록, 표, 명령어, 파일 경로는 두 섹션에서 동일하게 중복되며, 서술 텍스트만 번역합니다.

## 영향

### 긍정적
- 한국어 독자와 글로벌 독자 모두 원하는 언어로 정보 손실 없이 읽을 수 있습니다.
- 동일 구조 규칙이 두 번째 섹션을 자체 검증 장치로 변환하여, 누락된 하위 섹션이 미완성 업데이트를 드러냅니다.
- 마켓플레이스에서 단일 언어 플러그인 대비 이중언어 출력이 차별점이 됩니다.

### 부정적
- 문서 분량이 약 2배가 되어 리뷰와 유지 부담이 증가합니다.
- 문서를 수정하는 모든 변경이 두 섹션을 함께 갱신해야 하며, 부분 갱신은 드리프트를 유발합니다.
- 두 섹션 정합성을 유지하기 위해 공통 스타일 가이드와 문서별 체크리스트가 필요합니다(ADR-003에서 해결).

## 참고 자료
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`
- ADR-002 (HTML 앵커 내비게이션, 구현 메커니즘)
- ADR-003 (공통 writing-style-guide 단일 진실원)
