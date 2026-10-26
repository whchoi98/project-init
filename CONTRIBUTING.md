# Contributing

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a> <a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

Thank you for your interest in contributing to project-init.

## How to Contribute

1. Fork the repository.
2. Create a feature branch from `main`.
   ```bash
   git checkout -b feat/my-feature
   ```
3. Make your changes and commit using [Conventional Commits](https://www.conventionalcommits.org/).
   ```bash
   git commit -m "feat: add support for Rust project detection"
   ```
4. Push to your fork.
   ```bash
   git push origin feat/my-feature
   ```
5. Open a Pull Request against the `main` branch.

## Commit Message Format

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Usage |
|--------|-------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code change that neither fixes a bug nor adds a feature |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance tasks |

## Plugin Structure

When adding or modifying plugin components, follow this structure:

```text
plugins/project-init/
├── commands/          # Slash commands (user-invocable)
│   └── <name>.md     # Frontmatter: description, allowed-tools, argument-hint, disable-model-invocation
├── agents/            # Subagents (model-invocable)
│   └── <name>.md     # Frontmatter: name, description, tools, effort, color
├── scripts/           # Deterministic checks the commands run
│   └── <name>.sh|.py # Referenced as ${CLAUDE_PLUGIN_ROOT}/scripts/<name>
└── skills/            # Knowledge skills (auto-referenced)
    └── <name>/
        ├── SKILL.md   # Frontmatter: name, description, allowed-tools, user-invocable
        └── references/
```

Agents omit `model`, so they inherit the user's main model (a team can still steer them with `CLAUDE_CODE_SUBAGENT_MODEL`), and set `effort` only for bounded or mechanical work. Commands leave `model` and `effort` unset because they run in the user's main conversation. A command that releases, deploys, pushes, or rewrites many files or a user's harness (such as `/init-project` and `/migrate-hooks`) sets `disable-model-invocation: true`, so only the user can start it. Skills use `allowed-tools`; `tools` is an agent field.

## Adding a New Command

1. Create `plugins/project-init/commands/<command-name>.md`.
2. Include YAML frontmatter with `description`, `allowed-tools`, and optionally `argument-hint` and `disable-model-invocation` (see the policy above).
3. Write the body as a brief to a capable colleague: the goal, inputs, rules with their reasons, the output contract (paths, headings, frontmatter keys, report format), a check the model can run, and the final report. Number steps only where order matters or a step is hard to undo. Ask up-front questions with the AskUserQuestion tool when it is available, because a chat reply starts a new turn and the command's `allowed-tools` no longer apply. Commands also run on smaller consumer models (Sonnet 5.5, Haiku 5.5, and the 4.5 models that `sonnet` and `haiku` resolve to on some providers), so keep every output contract explicit. The full rules are in `plugins/project-init/CLAUDE.md` under `## Rules`.
4. Reference templates and scripts as `${CLAUDE_PLUGIN_ROOT}/...`; relative paths do not resolve in a consumer project.
5. Update `README.md` (both English and Korean sections).
6. Add an entry to `CHANGELOG.md` under `[Unreleased]`.

## Adding a Reference Template

1. Place the file in `plugins/project-init/skills/project-scaffolder/references/`.
2. Update `SKILL.md` to list the new reference.
3. Reference it from the command that uses it as `${CLAUDE_PLUGIN_ROOT}/skills/project-scaffolder/references/<file>.md`.

## Code Review Checklist

- YAML frontmatter is valid and uses only supported fields
- Allowed tools match what the command actually uses
- Output contracts are explicit, and no counts of tests, files, steps, or commands are hardcoded
- Both English and Korean README sections are updated, and bilingual docs pass `python3 plugins/project-init/scripts/check-bilingual.py <file>`
- CHANGELOG entry added under `[Unreleased]`
- No broken internal file references
- `bash tests/run-all.sh` passes (in Claude Code sessions, the Stop hook runs it when a turn ends on a tree that changed since its last run)

---

<a id="korean"></a>

# 한국어

project-init에 기여해 주셔서 감사합니다.

## 기여 방법

1. 리포지토리를 Fork합니다.
2. `main`에서 기능 브랜치를 생성합니다.
   ```bash
   git checkout -b feat/my-feature
   ```
3. 변경 사항을 [Conventional Commits](https://www.conventionalcommits.org/) 형식으로 커밋합니다.
   ```bash
   git commit -m "feat: Rust 프로젝트 감지 지원 추가"
   ```
4. Fork한 리포지토리에 Push합니다.
   ```bash
   git push origin feat/my-feature
   ```
5. `main` 브랜치를 대상으로 Pull Request를 생성합니다.

## 커밋 메시지 형식

이 프로젝트는 [Conventional Commits](https://www.conventionalcommits.org/)를 따릅니다:

| 접두사 | 용도 |
|--------|------|
| `feat:` | 새로운 기능 |
| `fix:` | 버그 수정 |
| `docs:` | 문서 변경만 |
| `refactor:` | 버그 수정이나 기능 추가가 아닌 코드 변경 |
| `test:` | 테스트 추가 또는 수정 |
| `chore:` | 유지보수 작업 |

## 플러그인 구조

플러그인 구성 요소를 추가하거나 수정할 때 아래 구조를 따릅니다:

```text
plugins/project-init/
├── commands/          # 슬래시 커맨드 (사용자 호출)
│   └── <name>.md     # Frontmatter: description, allowed-tools, argument-hint, disable-model-invocation
├── agents/            # 서브에이전트 (모델 호출)
│   └── <name>.md     # Frontmatter: name, description, tools, effort, color
├── scripts/           # 커맨드가 실행하는 결정론적 검사
│   └── <name>.sh|.py # ${CLAUDE_PLUGIN_ROOT}/scripts/<name>으로 참조
└── skills/            # 지식 스킬 (자동 참조)
    └── <name>/
        ├── SKILL.md   # Frontmatter: name, description, allowed-tools, user-invocable
        └── references/
```

에이전트는 `model`을 생략해 사용자의 메인 모델을 상속하고(팀은 `CLAUDE_CODE_SUBAGENT_MODEL`로 여전히 모델을 지정할 수 있습니다), `effort`는 범위가 정해진 작업이나 기계적인 작업에만 설정합니다. 커맨드는 사용자의 메인 대화에서 실행되므로 `model`과 `effort`를 설정하지 않습니다. 릴리스, 배포, 푸시를 하거나 많은 파일 또는 사용자의 하네스를 다시 쓰는 커맨드(예: `/init-project`, `/migrate-hooks`)는 `disable-model-invocation: true`를 설정해 사용자만 시작할 수 있게 합니다. 스킬은 `allowed-tools`를 사용하며, `tools`는 에이전트 필드입니다.

## 새 커맨드 추가 방법

1. `plugins/project-init/commands/<command-name>.md` 파일을 생성합니다.
2. YAML frontmatter에 `description`, `allowed-tools`, 선택적으로 `argument-hint`와 `disable-model-invocation`을 포함합니다 (위 정책 참조).
3. 유능한 동료에게 건네는 브리프처럼 본문을 작성합니다: 목표, 입력, 이유를 붙인 규칙, 출력 계약(경로, 헤딩, frontmatter 키, 보고 형식), 모델이 실행할 수 있는 검사, 최종 보고. 번호는 순서가 중요하거나 되돌리기 어려운 단계에만 붙입니다. 사전 질문은 AskUserQuestion 도구가 있으면 그 도구로 묻습니다. 채팅 답장은 새 턴을 시작해 커맨드의 `allowed-tools`가 더는 적용되지 않기 때문입니다. 커맨드는 더 작은 소비자 모델(Sonnet 5.5, Haiku 5.5, 그리고 일부 제공자에서 `sonnet`과 `haiku`가 해석되는 4.5 모델)에서도 실행되므로 모든 출력 계약을 명시합니다. 전체 규칙은 `plugins/project-init/CLAUDE.md`의 `## Rules`에 있습니다.
4. 템플릿과 스크립트는 `${CLAUDE_PLUGIN_ROOT}/...`로 참조합니다. 상대 경로는 소비자 프로젝트에서 해석되지 않습니다.
5. `README.md`를 업데이트합니다 (영어와 한국어 섹션 모두).
6. `CHANGELOG.md`의 `[Unreleased]`에 항목을 추가합니다.

## 참조 템플릿 추가 방법

1. `plugins/project-init/skills/project-scaffolder/references/`에 파일을 배치합니다.
2. `SKILL.md`에 새 참조를 추가합니다.
3. 해당 참조를 사용하는 커맨드에서 `${CLAUDE_PLUGIN_ROOT}/skills/project-scaffolder/references/<file>.md`로 연결합니다.

## 코드 리뷰 체크리스트

- YAML frontmatter가 유효하고 지원되는 필드만 사용하는지 확인
- allowed-tools가 커맨드에서 실제 사용하는 도구와 일치하는지 확인
- 출력 계약이 명시되어 있고, 테스트·파일·단계·커맨드 개수를 하드코딩하지 않았는지 확인
- README.md의 영어/한국어 섹션이 모두 업데이트되었고, 이중 언어 문서가 `python3 plugins/project-init/scripts/check-bilingual.py <file>`를 통과하는지 확인
- CHANGELOG의 `[Unreleased]`에 항목이 추가되었는지 확인
- 내부 파일 참조가 깨지지 않았는지 확인
- `bash tests/run-all.sh`가 통과하는지 확인 (Claude Code 세션에서는 마지막 실행 이후 바뀐 트리에서 턴이 끝나면 Stop hook이 실행합니다)
