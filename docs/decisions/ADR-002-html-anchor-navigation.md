# ADR-002: HTML Anchor Navigation with ASCII-only IDs

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted

## Context
ADR-001 established that all user-facing documents are bilingual. Each document needs an in-page language toggle so readers can jump directly to the section in their preferred language. Two implementation problems surfaced when this policy was applied to GitHub-rendered Markdown:

1. **Markdown badge link rendering**: GitHub sometimes renders `[![alt](img-url)](#anchor)` by stripping the surrounding anchor wrapper, producing a bare `<img>`. Clicking the badge opens the SVG file at `img-url` instead of jumping to `#anchor`.
2. **Korean auto-anchor instability**: GitHub auto-generates anchor IDs from headings. A `# 한국어` heading produces an anchor like `#한국어` whose URL-encoded form (`#%ED%95%9C%EA%B5%AD%EC%96%B4`) varies across renderers and browsers, breaking links.

The bug was first observed when language toggle badges in README.md and CHANGELOG.md opened the shields.io SVG instead of navigating, and Korean section anchors failed silently on GitHub mobile.

## Options Considered

### Option 1: Markdown badges with Unicode auto-anchors
- **Pros**: Pure Markdown, idiomatic, no HTML in the document body.
- **Cons**: Breaks on GitHub when the renderer drops the anchor wrapper; Korean anchor IDs unreliable across browsers.

### Option 2: HTML `<a><img></a>` with Unicode IDs
- **Pros**: Anchor wrapper guaranteed; click navigates correctly.
- **Cons**: URL encoding of Korean anchor IDs still inconsistent across renderers; intermittent failures remain.

### Option 3: HTML `<a><img></a>` with explicit ASCII-only IDs (`#english`, `#korean`)
- **Pros**: Click navigation guaranteed by explicit `<a>` wrapper; ASCII anchors universally reliable across browsers, mobile, and external Markdown viewers.
- **Cons**: Mixes HTML into Markdown body; requires explicit `<a id="english"></a>` and `<a id="korean"></a>` sentinel tags before each language heading; every bilingual document must follow the same pattern.

## Decision
Adopt Option 3. All bilingual documents use the following pattern at the top:

```html
<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>
```

Explicit `<a id="english"></a>` and `<a id="korean"></a>` tags are placed immediately before each language heading. Anchor IDs are restricted to ASCII (`english`, `korean`) regardless of the section heading's natural-language text. The shared writing-style-guide enforces this pattern for all document types.

## Consequences

### Positive
- Language toggle navigates correctly on GitHub web, GitHub mobile, and external Markdown viewers.
- ASCII anchors eliminate URL encoding ambiguity entirely.
- The pattern is uniform across all bilingual documents (README, CHANGELOG, architecture, ADR, runbook), reducing cognitive load when reviewing.

### Negative
- Markdown body contains raw HTML, which slightly reduces readability and conflicts with "pure Markdown" preferences.
- Every new bilingual document must include the two sentinel `<a id="...">` tags; missing one breaks navigation silently.
- Document generation commands and the writing-style-guide must enforce this pattern; ad-hoc bilingual documents will likely diverge.

## References
- Commit `c985118` -- "Unify bilingual layout: shields.io badges + English-first for all documents"
- Commit `bd20496` -- "Fix language badge navigation with HTML anchor tags and ASCII-only IDs"
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`, section "Bilingual Structure"
- ADR-001 (bilingual documentation policy this implements)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨

## 배경
ADR-001에서 모든 사용자 대면 문서를 이중언어로 작성하기로 결정했습니다. 각 문서는 독자가 선호 언어 섹션으로 바로 이동할 수 있도록 페이지 내 언어 토글이 필요합니다. 이 정책을 GitHub에서 렌더링되는 Markdown에 적용할 때 두 가지 구현 문제가 드러났습니다:

1. **Markdown 배지 링크 렌더링**: GitHub은 때때로 `[![alt](img-url)](#anchor)`를 렌더링할 때 바깥쪽 앵커 래퍼를 떼어내고 `<img>`만 남깁니다. 배지를 클릭하면 `#anchor`로 이동하지 않고 `img-url`의 SVG 파일이 열립니다.
2. **한국어 자동 앵커 불안정성**: GitHub은 헤딩에서 앵커 id를 자동 생성합니다. `# 한국어` 헤딩은 `#한국어` 앵커를 만들고, 이 URL 인코딩 형태(`#%ED%95%9C%EA%B5%AD%EC%96%B4`)는 렌더러와 브라우저마다 달라 링크가 깨집니다.

이 버그는 README.md와 CHANGELOG.md의 언어 토글 배지가 이동 대신 shields.io SVG를 여는 현상과, 한국어 섹션 앵커가 GitHub 모바일에서 조용히 실패하는 현상으로 처음 발견되었습니다.

## 검토한 옵션

### 옵션 1: Markdown 배지 + 유니코드 자동 앵커
- **장점**: 순수 Markdown, 관용적, 본문에 HTML 미사용.
- **단점**: GitHub 렌더러가 앵커 래퍼를 떼어내면 깨짐; 한국어 앵커 id가 브라우저마다 불안정.

### 옵션 2: HTML `<a><img></a>` + 유니코드 id
- **장점**: 앵커 래퍼 보장; 클릭 이동 정상.
- **단점**: 한국어 앵커 id의 URL 인코딩이 여전히 렌더러마다 불일치; 간헐적 실패 잔존.

### 옵션 3: HTML `<a><img></a>` + 명시적 ASCII-only id (`#english`, `#korean`)
- **장점**: 명시적 `<a>` 래퍼로 클릭 이동 보장; ASCII 앵커는 브라우저, 모바일, 외부 Markdown 뷰어에서 일관 동작.
- **단점**: Markdown 본문에 HTML 혼재; 각 언어 헤딩 직전에 `<a id="english"></a>`, `<a id="korean"></a>` 센티넬 태그 필요; 모든 이중언어 문서가 동일 패턴을 따라야 함.

## 결정
옵션 3을 채택합니다. 모든 이중언어 문서 상단에 다음 패턴을 사용합니다:

```html
<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>
```

각 언어 헤딩 직전에 `<a id="english"></a>`와 `<a id="korean"></a>` 태그를 명시적으로 배치합니다. 앵커 id는 섹션 헤딩의 자연어 표기와 무관하게 ASCII(`english`, `korean`)로 제한합니다. 공통 writing-style-guide가 모든 문서 유형에 이 패턴을 강제합니다.

## 영향

### 긍정적
- GitHub 웹, GitHub 모바일, 외부 Markdown 뷰어에서 언어 토글이 정상 동작합니다.
- ASCII 앵커가 URL 인코딩 모호성을 완전히 제거합니다.
- 모든 이중언어 문서(README, CHANGELOG, architecture, ADR, runbook)가 동일 패턴을 사용하여 리뷰 시 인지 부담이 감소합니다.

### 부정적
- Markdown 본문에 HTML 원본이 포함되어 가독성이 약간 저하되고 "순수 Markdown" 선호와 충돌합니다.
- 모든 신규 이중언어 문서가 두 개의 센티넬 `<a id="...">` 태그를 포함해야 하며, 하나라도 누락되면 내비게이션이 조용히 깨집니다.
- 문서 생성 명령과 writing-style-guide가 이 패턴을 강제해야 하며, 즉석으로 작성된 이중언어 문서는 쉽게 이탈할 수 있습니다.

## 참고 자료
- 커밋 `c985118` -- "Unify bilingual layout: shields.io badges + English-first for all documents"
- 커밋 `bd20496` -- "Fix language badge navigation with HTML anchor tags and ASCII-only IDs"
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`, "Bilingual Structure" 섹션
- ADR-001 (이 결정이 구현하는 이중언어 문서 정책)
