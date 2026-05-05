# ADR-003: Shared Writing Style Guide as Single Source of Truth

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Context
Five document-generating commands (`generate-readme`, `generate-changelog`, `add-adr`, `add-runbook`, `sync-docs`) all need to follow the same bilingual structure (ADR-001), the same HTML anchor navigation pattern (ADR-002), and the same writing-style rules (English imperative mood, Korean 경어체, no emojis, ISO 8601 dates, code-block language tags). Before this decision, each command embedded its own copy of these rules inline.

The duplication caused two concrete failure modes:
1. **Drift**: A rule update in one command(for example, switching from Markdown badges to HTML anchors per ADR-002) had to be applied in five places. Some commands inevitably lagged, producing documents that did not match across the project.
2. **Inconsistency between document types**: Per-command rules diverged in subtle ways. README badges used different colors than CHANGELOG badges; ADR section headings used different translations than runbook sections.

## Options Considered

### Option 1: Inline style rules in each command
- **Pros**: Each command file is self-contained; reading one command requires no cross-references; commands can be modified independently.
- **Cons**: Five copies of the same rules drift apart; policy updates require five edits; no single place for a future maintainer to learn the project-wide style.

### Option 2: Single shared `writing-style-guide.md` referenced by all commands
- **Pros**: Single edit point for cross-cutting style policy; commands become thinner and focused on their unique logic; new document-generating commands inherit the policy by referencing the guide.
- **Cons**: Each command requires an explicit "read the style guide first" step; a reader of one command must follow the reference to understand the full output specification.

### Option 3: Per-command rules plus a shared guide (overlapping)
- **Pros**: Self-contained commands plus central reference.
- **Cons**: Worst of both worlds -- the dual sources will themselves drift, and which one wins becomes ambiguous.

## Decision
Adopt Option 2. A single `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md` defines all bilingual, formatting, and writing-style rules. All five document-generating commands include an explicit step to read this guide before generating output, and reference it as the authoritative source for cross-cutting rules. Per-document rules (for example, the ADR section schema or runbook procedure layout) live in the per-document templates inside `docs-templates.md`, which extend but do not override the style guide.

## Consequences

### Positive
- A single edit to `writing-style-guide.md` propagates to all five commands without per-command code changes.
- New document-generating commands can inherit the policy with one line: "Follow `writing-style-guide.md`".
- The style guide becomes a single onboarding document for new contributors writing project documentation.

### Negative
- No command is fully self-contained; reading a command file alone does not give the complete output specification.
- A change to the style guide can change the output of all five commands at once, making the blast radius of guide edits large.
- The guide must be kept consistent with `docs-templates.md` (per-document templates); the boundary between cross-cutting and per-document rules requires care.

## References
- Commit `44dc1fd` -- "Add shared writing-style-guide and apply bilingual rules to all document types"
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`
- Commands that reference the guide:
  - `plugins/project-init/commands/generate-readme.md`
  - `plugins/project-init/commands/generate-changelog.md`
  - `plugins/project-init/commands/add-adr.md`
  - `plugins/project-init/commands/add-runbook.md`
  - `plugins/project-init/commands/sync-docs.md`
- ADR-001 (the bilingual policy this guide enforces)
- ADR-002 (the navigation pattern this guide enforces)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 배경
다섯 개의 문서 생성 명령(`generate-readme`, `generate-changelog`, `add-adr`, `add-runbook`, `sync-docs`)은 모두 동일한 이중언어 구조(ADR-001), 동일한 HTML 앵커 내비게이션 패턴(ADR-002), 동일한 작성 스타일(영어 명령형, 한국어 경어체, 이모지 금지, ISO 8601 날짜, 코드 블록 언어 태그)을 따라야 합니다. 이 결정 이전에는 각 명령이 동일한 규칙을 자체적으로 인라인으로 포함하고 있었습니다.

이 중복은 두 가지 구체적 실패 양상을 낳았습니다:
1. **드리프트**: 한 명령에서 규칙을 갱신하면(예: ADR-002에 따라 Markdown 배지에서 HTML 앵커로 전환) 다섯 곳에 동일하게 적용해야 했습니다. 일부 명령이 필연적으로 뒤처져 프로젝트 전체에서 일치하지 않는 문서를 생성했습니다.
2. **문서 유형 간 불일치**: 명령별 규칙이 미묘하게 발산했습니다. README 배지가 CHANGELOG 배지와 다른 색상을 썼고, ADR 섹션 헤딩이 runbook 섹션과 다른 번역을 사용했습니다.

## 검토한 옵션

### 옵션 1: 각 명령에 스타일 규칙 인라인
- **장점**: 각 명령 파일이 자족적; 한 명령을 읽을 때 상호 참조 불필요; 명령을 독립적으로 수정 가능.
- **단점**: 동일 규칙의 다섯 사본이 드리프트; 정책 갱신 시 다섯 곳 수정 필요; 미래 메인테이너가 프로젝트 전체 스타일을 한 곳에서 학습할 수 없음.

### 옵션 2: 모든 명령이 참조하는 단일 공유 `writing-style-guide.md`
- **장점**: 전반적 스타일 정책의 단일 편집 지점; 명령은 더 얇아지고 자체 로직에 집중; 신규 문서 생성 명령은 가이드를 참조하는 것만으로 정책 상속.
- **단점**: 각 명령에 "스타일 가이드 먼저 읽기" 단계 명시 필요; 한 명령을 읽는 독자가 전체 출력 사양을 이해하려면 참조를 따라가야 함.

### 옵션 3: 명령별 규칙 + 공유 가이드(중복)
- **장점**: 자족적 명령과 중앙 참조를 모두 보유.
- **단점**: 양쪽 단점 모두 -- 이중 진실원이 다시 드리프트하고, 어느 쪽이 우선인지 모호해짐.

## 결정
옵션 2를 채택합니다. 단일 `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`가 모든 이중언어, 포맷팅, 작성 스타일 규칙을 정의합니다. 다섯 개 문서 생성 명령 모두 출력 생성 전에 이 가이드를 읽는 명시적 단계를 포함하며, 전반적 규칙의 권위 있는 출처로 참조합니다. 문서별 규칙(예: ADR 섹션 스키마, runbook 절차 레이아웃)은 `docs-templates.md`의 문서별 템플릿에 위치하며, 스타일 가이드를 확장하되 덮어쓰지는 않습니다.

## 영향

### 긍정적
- `writing-style-guide.md` 한 곳 편집이 명령별 코드 변경 없이 다섯 명령 모두에 전파됩니다.
- 신규 문서 생성 명령은 한 줄("`writing-style-guide.md`를 따른다")로 정책을 상속할 수 있습니다.
- 스타일 가이드가 프로젝트 문서를 작성하는 신규 기여자에게 단일 온보딩 문서가 됩니다.

### 부정적
- 어떤 명령도 완전히 자족적이지 않으며, 명령 파일만 읽어서는 완전한 출력 사양을 알 수 없습니다.
- 스타일 가이드 변경이 다섯 명령의 출력을 한 번에 바꿀 수 있어 가이드 편집의 영향 반경이 큽니다.
- 가이드와 `docs-templates.md`(문서별 템플릿)의 일관성을 유지해야 하며, 전반적 규칙과 문서별 규칙의 경계 설정에 주의가 필요합니다.

## 참고 자료
- 커밋 `44dc1fd` -- "Add shared writing-style-guide and apply bilingual rules to all document types"
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`
- 가이드를 참조하는 명령:
  - `plugins/project-init/commands/generate-readme.md`
  - `plugins/project-init/commands/generate-changelog.md`
  - `plugins/project-init/commands/add-adr.md`
  - `plugins/project-init/commands/add-runbook.md`
  - `plugins/project-init/commands/sync-docs.md`
- ADR-001 (이 가이드가 강제하는 이중언어 정책)
- ADR-002 (이 가이드가 강제하는 내비게이션 패턴)
