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

```
plugins/project-init/
├── commands/          # Slash commands (user-invocable)
│   └── <name>.md     # Frontmatter: description, allowed-tools, argument-hint
├── agents/            # Subagents (model-invocable)
│   └── <name>.md     # Frontmatter: name, description, tools, model, color
└── skills/            # Knowledge skills (auto-referenced)
    └── <name>/
        ├── SKILL.md   # Frontmatter: name, description, tools, user-invocable
        └── references/
```

## Adding a New Command

1. Create `plugins/project-init/commands/<command-name>.md`.
2. Include YAML frontmatter with `description`, `allowed-tools`, and optionally `argument-hint`.
3. Write step-by-step instructions that Claude will follow.
4. Update `README.md` (both English and Korean sections).
5. Add an entry to `CHANGELOG.md` under `[Unreleased]`.

## Adding a Reference Template

1. Place the file in `plugins/project-init/skills/project-scaffolder/references/`.
2. Update `SKILL.md` to list the new reference.
3. Reference it from the command that uses it.

## Code Review Checklist

- YAML frontmatter is valid and complete
- Allowed tools match what the command actually uses
- Both English and Korean README sections are updated
- CHANGELOG entry added under `[Unreleased]`
- No broken internal file references

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

```
plugins/project-init/
├── commands/          # 슬래시 커맨드 (사용자 호출)
│   └── <name>.md     # Frontmatter: description, allowed-tools, argument-hint
├── agents/            # 서브에이전트 (모델 호출)
│   └── <name>.md     # Frontmatter: name, description, tools, model, color
└── skills/            # 지식 스킬 (자동 참조)
    └── <name>/
        ├── SKILL.md   # Frontmatter: name, description, tools, user-invocable
        └── references/
```

## 새 커맨드 추가 방법

1. `plugins/project-init/commands/<command-name>.md` 파일을 생성합니다.
2. YAML frontmatter에 `description`, `allowed-tools`, 선택적으로 `argument-hint`를 포함합니다.
3. Claude가 따를 단계별 지침을 작성합니다.
4. `README.md`를 업데이트합니다 (영어와 한국어 섹션 모두).
5. `CHANGELOG.md`의 `[Unreleased]`에 항목을 추가합니다.

## 참조 템플릿 추가 방법

1. `plugins/project-init/skills/project-scaffolder/references/`에 파일을 배치합니다.
2. `SKILL.md`에 새 참조를 추가합니다.
3. 해당 참조를 사용하는 커맨드에서 연결합니다.

## 코드 리뷰 체크리스트

- YAML frontmatter가 유효하고 완전한지 확인
- allowed-tools가 커맨드에서 실제 사용하는 도구와 일치하는지 확인
- README.md의 영어/한국어 섹션이 모두 업데이트되었는지 확인
- CHANGELOG의 `[Unreleased]`에 항목이 추가되었는지 확인
- 내부 파일 참조가 깨지지 않았는지 확인
