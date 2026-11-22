# ADR-010: Infographic Architecture Figures with a Mermaid Fallback

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Status
Accepted (supersedes ADR-007 in part: Mermaid becomes the fallback format instead of the only one)

## Context
ADR-007 made the Mermaid flowchart the only format for architecture figures in the README and `docs/architecture.md`, with English labels in both language halves and byte-identical blocks. That keeps a figure diffable and cheap to regenerate, but the Korean half shows an English-only diagram, and a flowchart carries boxes and arrows without saying what each layer does.

On 2026-11-22 the maintainer decided that architecture figures are made with the `aws-infographic` skill, in an English and a Korean version. The skill belongs to another plugin (`my-plugins`), needs Playwright Chromium and the NanumSquare and D2Coding fonts, and takes several minutes per figure. A consumer of project-init who does not have it could build no figure at all if it were the only format.

## Options Considered

### Option 1: Keep Mermaid only (ADR-007)
- **Pros**: Text that diffs; no dependency; GitHub renders it; `/sync-docs` and doc-sync-checker compare node names with the code.
- **Cons**: English-only labels in the Korean half; no room for the explanation a reader needs.

### Option 2: Infographics only
- **Pros**: One format; explanatory figures in both languages.
- **Cons**: A session without the skill gets no figure; every document sync depends on a build that takes minutes; the figures are binary files.

### Option 3: Infographics where the skill is available, Mermaid otherwise
- **Pros**: Explanatory figures in both languages where the skill exists; everyone else keeps the ADR-007 behavior unchanged.
- **Cons**: Two forms to describe and check; binary files in the repository; the figure itself cannot be diffed, only its page module.

### Option 4: Both forms in every document
- **Pros**: Keeps the automated node-name check and the diff next to the infographic.
- **Cons**: Every figure is maintained twice in each language.

## Decision
Adopt Option 3.

1. **One source.** The rule lives in `writing-style-guide.md` under `## Diagram Rules` (ADR-003). The README and architecture templates, `/init-project`, `/generate-readme`, `/sync-docs`, and the doc-sync-checker agent cite that section instead of restating it.
2. **Availability.** The skill is available when the session's skill list has `aws-infographic`, with or without a plugin prefix. Without it, the commands write Mermaid flowcharts as ADR-007 describes. ASCII box diagrams stay removed in both cases.
3. **Brief.** The skill gets a fixed brief in place of its own scope questions: one 16:9 page per figure in the dark and light themes, no 4:5 version and no PowerPoint deck, an English and a Korean version with the same sections and layout (slugs ending in `-en` and `-ko`), content from the code and `docs/architecture.md` only, and the work folder `docs/images/architecture/`.
4. **Embedding.** Each half embeds its own language's 2x PNG in a `<picture>` element, light by default and dark for a dark color scheme, with an `alt` text and one sentence of prose that says what the flow is. The PNG is used because the SVG needs fonts the reader may not have.
5. **Existing figures.** A figure that still matches the code stays in the form it has. A stale figure is rebuilt in that form, and a stale infographic in a session without the skill is reported, not replaced with Mermaid. This repository's own Mermaid diagrams stay until they are rebuilt in a later change.
6. **Check.** `check-bilingual.py` reports a document whose halves have different numbers of `<picture>` figures. Mermaid blocks stay byte-identical in both halves.
7. **Asking.** `/init-project` asks whether to build infographics or write Mermaid only when the skill is available, because the build takes several minutes and asks for permission for the skill and its commands.

## Consequences

### Positive
- The Korean half carries a Korean figure, and the figure explains the layers instead of only connecting them.
- A consumer without the skill sees no change from ADR-007.
- A figure missing from one language half now fails the bilingual check.

### Negative
- Built figures are binary files, and a change shows up in the page module's diff, not in the image.
- A figure takes several minutes and several permission prompts to build.
- The rule depends on a skill outside this plugin, whose brief, file names, or requirements can change without notice here.
- doc-sync-checker compares the text of the page modules with the code, which is a weaker check than Mermaid node names.

## References
- ADR-001 (bilingual structure), ADR-003 (shared writing-style-guide), ADR-007 (Mermaid flowcharts)
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md` (`## Diagram Rules`), `readme-template.md`, `docs-templates.md`
- `plugins/project-init/scripts/check-bilingual.py`, `tests/fixtures/bilingual/good-infographic.md`, `tests/fixtures/bilingual/bad-figure-missing.md`
- The `aws-infographic` skill of the `my-plugins` plugin, version 1.7.0 (read 2026-11-22)

---

<a id="korean"></a>

# 한국어

## 상태
승인됨 (ADR-007을 일부 대체: Mermaid는 유일한 형식에서 대체 형식으로 바뀜)

## 배경
ADR-007은 README와 `docs/architecture.md`의 아키텍처 그림 형식을 Mermaid flowchart 하나로 정했고, 라벨은 양쪽 언어 절반에서 영어로 두며 블록은 바이트 단위로 같게 했습니다. 그림을 diff로 볼 수 있고 다시 만드는 비용이 적지만, 한국어 절반에 영어로만 된 다이어그램이 들어가고, flowchart는 상자와 화살표만 보여 줄 뿐 각 계층이 하는 일을 설명하지 못합니다.

2026-11-22에 관리자는 아키텍처 그림을 `aws-infographic` 스킬로 영어판과 한국어판으로 만들기로 결정했습니다. 이 스킬은 다른 플러그인(`my-plugins`)에 속하고, Playwright Chromium과 NanumSquare, D2Coding 폰트가 필요하며, 그림 하나에 몇 분이 걸립니다. 이 형식만 허용하면 스킬이 없는 project-init 소비자는 그림을 전혀 만들 수 없습니다.

## 검토한 옵션

### 옵션 1: Mermaid만 유지 (ADR-007)
- **장점**: diff가 되는 텍스트. 의존성 없음. GitHub이 렌더링함. `/sync-docs`와 doc-sync-checker가 노드 이름을 코드와 비교함.
- **단점**: 한국어 절반의 라벨이 영어뿐임. 독자에게 필요한 설명을 담을 자리가 없음.

### 옵션 2: 인포그래픽만 사용
- **장점**: 형식이 하나. 양쪽 언어로 설명이 담긴 그림.
- **단점**: 스킬이 없는 세션은 그림을 만들지 못함. 문서 동기화가 매번 몇 분짜리 빌드에 의존함. 그림이 바이너리 파일임.

### 옵션 3: 스킬이 있으면 인포그래픽, 없으면 Mermaid
- **장점**: 스킬이 있는 곳에서는 양쪽 언어로 설명이 담긴 그림. 그 밖의 사용자는 ADR-007 동작 그대로.
- **단점**: 설명하고 검사할 형식이 둘. 저장소에 바이너리 파일이 들어감. 그림 자체는 diff가 안 되고 page module만 됨.

### 옵션 4: 모든 문서에 두 형식을 함께 넣기
- **장점**: 인포그래픽 옆에 노드 이름 자동 검사와 diff가 유지됨.
- **단점**: 그림마다 언어별로 두 번씩 관리해야 함.

## 결정
옵션 3을 채택합니다.

1. **단일 출처.** 규칙은 `writing-style-guide.md`의 `## Diagram Rules`에 둡니다(ADR-003). README와 architecture 템플릿, `/init-project`, `/generate-readme`, `/sync-docs`, doc-sync-checker 에이전트는 규칙을 다시 적지 않고 그 섹션을 가리킵니다.
2. **사용 가능 여부.** 세션의 스킬 목록에 플러그인 접두사가 있든 없든 `aws-infographic`이 있으면 스킬을 쓸 수 있습니다. 없으면 커맨드는 ADR-007대로 Mermaid flowchart를 씁니다. ASCII 박스 다이어그램은 두 경우 모두 쓰지 않습니다.
3. **브리프.** 스킬에는 스킬 자체의 범위 질문 대신 정해진 브리프를 줍니다. 그림마다 16:9 한 장을 다크와 라이트 테마로 만들고, 4:5 버전과 PowerPoint 덱은 만들지 않으며, 섹션과 배치가 같은 영어판과 한국어판을 만들고(slug는 `-en`, `-ko`로 끝남), 내용은 코드와 `docs/architecture.md`에서만 가져오고, 작업 폴더는 `docs/images/architecture/`입니다.
4. **삽입.** 각 절반은 자기 언어의 2x PNG를 `<picture>` 요소로 넣습니다. 기본은 라이트, 다크 색 구성표에서는 다크이며, `alt` 텍스트와 흐름을 설명하는 문장 하나를 함께 둡니다. SVG는 독자에게 없을 수 있는 폰트가 필요하므로 PNG를 씁니다.
5. **기존 그림.** 코드와 맞는 그림은 지금 형식 그대로 둡니다. 낡은 그림은 같은 형식으로 다시 만들고, 스킬이 없는 세션에서 낡은 인포그래픽은 Mermaid로 바꾸지 않고 보고합니다. 이 저장소의 Mermaid 다이어그램은 이후 변경에서 다시 만들 때까지 그대로 둡니다.
6. **검사.** `check-bilingual.py`는 양쪽 절반의 `<picture>` 그림 수가 다른 문서를 보고합니다. Mermaid 블록은 양쪽 절반에서 계속 바이트 단위로 같아야 합니다.
7. **질문.** `/init-project`는 스킬이 있을 때만 인포그래픽을 만들지 Mermaid를 쓸지 묻습니다. 빌드에 몇 분이 걸리고 스킬과 그 명령마다 권한을 묻기 때문입니다.

## 영향

### 긍정적
- 한국어 절반에 한국어 그림이 들어가고, 그림이 계층을 잇기만 하지 않고 설명합니다.
- 스킬이 없는 소비자에게는 ADR-007에서 달라지는 것이 없습니다.
- 한쪽 언어 절반에서 그림이 빠지면 이제 이중 언어 검사가 실패합니다.

### 부정적
- 빌드한 그림은 바이너리 파일이고, 변경은 이미지가 아니라 page module의 diff에 나타납니다.
- 그림 하나를 만드는 데 몇 분이 걸리고 권한 확인을 여러 번 거칩니다.
- 이 플러그인 밖의 스킬에 의존하므로, 브리프나 파일 이름, 요구 사항이 여기에 알리지 않고 바뀔 수 있습니다.
- doc-sync-checker는 page module의 텍스트를 코드와 비교하는데, 이는 Mermaid 노드 이름 비교보다 약한 검사입니다.

## 참고 자료
- ADR-001(이중 언어 구조), ADR-003(공유 writing-style-guide), ADR-007(Mermaid flowchart)
- `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`(`## Diagram Rules`), `readme-template.md`, `docs-templates.md`
- `plugins/project-init/scripts/check-bilingual.py`, `tests/fixtures/bilingual/good-infographic.md`, `tests/fixtures/bilingual/bad-figure-missing.md`
- `my-plugins` 플러그인의 `aws-infographic` 스킬, 버전 1.7.0(2026-11-22 확인)
