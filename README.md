# project-init

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-2.0.0-green.svg)](https://github.com/whchoi98/project-init) [![English](https://img.shields.io/badge/lang-English-blue.svg)](#english) [![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](#한국어)

A Claude Code plugin for initializing and maintaining project structures with adaptive detection, quality scoring, and auto-sync documentation workflows.

Claude Code 프로젝트 구조 초기화, 문서 품질 점수 평가, 자동 동기화 워크플로우를 지원하는 플러그인입니다.

---

# English

## Overview

project-init is a Claude Code plugin that automates **project structure generation** and **documentation maintenance**. Claude Code understands project context through `CLAUDE.md` files, but creating and keeping them in sync with code changes is a manual, error-prone process.

This plugin provides five commands: scaffolding new or existing projects with `/init-project`, synchronizing documentation with `/sync-docs`, adding modules with `/add-module`, creating runbooks with `/add-runbook`, recording architecture decisions with `/add-adr`, and objectively measuring documentation quality with a 0-100 scoring system.

## Features

- **Adaptive Project Detection** -- Detects `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, and other build files to adapt scaffolding to existing projects. A Next.js app gets `app/routes/CLAUDE.md`; a Go project gets `cmd/CLAUDE.md`.
- **CLAUDE.md Quality Scoring** -- Evaluates documentation across 6 criteria (commands, architecture clarity, non-obvious patterns, conciseness, currency, actionability) on a 0-100 scale with A-F grades. Before/After comparison on every sync.
- **4-Layer Auto-Sync Workflow** -- Generated projects include Plan mode rules, PostToolUse hooks, the `/sync-docs` command, and a Git commit-msg hook, ensuring documentation stays current as code evolves.
- **Plan Mode Integration** -- Run `/init-project` after a `/plan` session and the generated structure reflects all architectural decisions discussed, including pre-filled `architecture.md` and auto-created ADRs.
- **Confidence-Based Code Review** -- The generated `code-review` skill scores issues 0-100 and only reports those above 75, filtering out false positives.
- **Security-First Hooks** -- PreCommit secret scanning blocks commits containing API keys and passwords. The commit-msg hook removes AI Co-Authored-By lines automatically.
- **Full Project Lifecycle** -- Generated projects include slash commands (/review, /test-all, /deploy), agent definitions (code-reviewer, security-auditor), MCP configuration, onboarding docs, and operational scripts.

## Prerequisites

- Claude Code CLI (latest version)
- Git

## Installation

```bash
# Clone the repository
git clone https://github.com/whchoi98/project-init.git

# Register the local marketplace
claude plugin marketplace add ./project-init

# Install the plugin
claude plugin install project-init
```

After installation, restart your Claude Code session.

## Usage

```bash
# Initialize a new project
/init-project ./my-new-project

# Initialize Claude Code structure in an existing project
/init-project ./existing-app

# Synchronize all documentation with quality scoring
/sync-docs

# Add a new module with CLAUDE.md and architecture doc update
/add-module src/auth

# Create an operational runbook
/add-runbook deploy-production

# Record an architecture decision
/add-adr use-postgresql
```

### Example Output

```
$ /sync-docs

## Sync Report

### Quality Scores (Before -> After)
| File               | Before   | After    | Change |
|--------------------|----------|----------|--------|
| ./CLAUDE.md        | B (82)   | B (87)   | +5     |
| ./src/api/CLAUDE.md| C (62)   | C (69)   | +7     |
| ./src/auth/CLAUDE.md| F (28)  | C (58)   | +30    |

### Changes Made
- Files created: 2
- Files updated: 3
- ADRs suggested: 1
- Runbooks missing: deploy-production, incident-response
```

### Plan Mode Workflow

Run a planning session before initialization to generate a context-aware project structure:

```
/plan                              # Enter Plan mode
# Discuss architecture, modules, tech choices with Claude
# Exit Plan mode

/init-project ./my-api             # Generated structure reflects all decisions
```

| Item | Without Plan | With Plan |
|------|-------------|-----------|
| CLAUDE.md Overview | Asks user interactively | Extracted from discussion |
| Module structure | Defaults (api, persistence) | Custom (api, auth, persistence, etc.) |
| architecture.md | Empty template | Pre-filled with data flow and components |
| ADRs | Not created | Auto-created from decisions |

### Commands Reference

| Command | Description |
|---------|-------------|
| `/init-project [path]` | Initialize a Claude Code project structure. Detects existing projects and adapts. |
| `/sync-docs` | Synchronize all documentation with current code state. Includes quality scoring. |
| `/add-module <path>` | Add a new module directory with CLAUDE.md and update architecture docs. |
| `/add-runbook <name>` | Create an operational runbook from template with structured steps. |
| `/add-adr <title>` | Create an Architecture Decision Record with auto-numbering. |
| `/health-check` | Validate entire project setup and report health score (0-200). |

### Skills and Agents

| Type | Name | Invocation | Role |
|------|------|-----------|------|
| Skill | `project-scaffolder` | Auto-referenced by Claude | Project structure patterns and conventions |
| Agent | `doc-sync-checker` | Spawned as subagent (model: opus) | Documentation gap analysis and quality scoring |

## Project Structure

```
project-init/                              # Marketplace root
├── .claude-plugin/
│   └── marketplace.json                   # Marketplace manifest (v1.0.0)
├── LICENSE                                # MIT License
├── README.md
└── plugins/
    └── project-init/                      # Plugin package (v2.0.0)
        ├── .claude-plugin/
        │   └── plugin.json                # Plugin manifest
        ├── commands/
        │   ├── init-project.md            # /init-project command
        │   ├── sync-docs.md               # /sync-docs command
        │   ├── add-module.md              # /add-module command
        │   ├── add-runbook.md             # /add-runbook command
        │   ├── add-adr.md                 # /add-adr command
        │   └── health-check.md            # /health-check command
        ├── agents/
        │   └── doc-sync-checker.md        # Documentation sync checker agent
        └── skills/
            └── project-scaffolder/
                ├── SKILL.md               # Structure pattern knowledge skill
                └── references/            # 8 template reference files
                    ├── claude-md-template.md
                    ├── docs-templates.md
                    ├── hook-scripts.md
                    ├── settings-json-template.md
                    ├── skills-templates.md
                    ├── agents-templates.md
                    ├── mcp-json-template.md
                    └── scripts-templates.md
```

### Generated Project Structure

Running `/init-project` on a new project creates:

```
project/
├── CLAUDE.md                          # Project memory + Auto-Sync Rules
├── README.md
├── .gitignore
├── .env.example                       # Environment variable template
├── .editorconfig                      # Editor formatting rules
├── .mcp.json                          # MCP server configuration
├── docs/
│   ├── architecture.md                # Architecture document
│   ├── onboarding.md                  # New developer onboarding guide
│   ├── api-reference.md               # API documentation (if applicable)
│   ├── decisions/.template.md         # ADR template
│   └── runbooks/.template.md          # Runbook template
├── .claude/
│   ├── settings.json                  # All hooks registered
│   ├── hooks/
│   │   ├── check-doc-sync.sh         # PostToolUse: doc sync detection
│   │   ├── secret-scan.sh            # PreCommit: secret scanning
│   │   ├── session-context.sh        # SessionStart: context loading
│   │   └── notify.sh                 # Notification: webhook alerts
│   ├── commands/
│   │   ├── review.md                 # /review: code review on diff
│   │   ├── test-all.md               # /test-all: execute test suite
│   │   └── deploy.md                 # /deploy: build and deploy
│   ├── skills/
│   │   ├── code-review/SKILL.md      # Confidence-based code review
│   │   ├── refactor/SKILL.md         # Safe refactoring
│   │   ├── release/SKILL.md          # Semver release automation
│   │   └── sync-docs/SKILL.md        # Documentation sync
│   └── agents/
│       ├── code-reviewer.yml          # Parallel code review
│       └── security-auditor.yml       # Security audit
├── scripts/
│   ├── setup.sh                       # Project setup for new developers
│   └── install-hooks.sh              # Git hooks installer
├── tools/
│   └── prompts/
├── tests/
│   ├── unit/CLAUDE.md
│   └── integration/CLAUDE.md
└── src/
    ├── api/CLAUDE.md                  # API module context
    └── persistence/CLAUDE.md          # Persistence module context
```

### Existing Project Detection

| File Found | Project Type | Source Dirs | Auto-filled Commands |
|-----------|-------------|-------------|---------------------|
| `package.json` | Node.js | src/, app/, lib/, components/ | npm/yarn/pnpm scripts |
| `pyproject.toml` | Python | src/, app/, lib/ | pip, pytest, ruff |
| `go.mod` | Go | cmd/, pkg/, internal/ | go build, go test |
| `Cargo.toml` | Rust | src/ | cargo build, cargo test |
| `pom.xml` / `build.gradle` | Java/Kotlin | src/main/, src/test/ | mvn, gradle |
| None | New project | src/api/, src/persistence/ | (ask user) |

### Auto-Sync Mechanisms

| Mechanism | Trigger | Type | Location |
|-----------|---------|------|----------|
| Auto-Sync Rules | Plan mode exit | Auto | `CLAUDE.md` |
| PostToolUse Hook | After Write/Edit | Auto | `.claude/settings.json` + `.claude/hooks/` |
| /sync-docs | User invocation | Manual | Plugin command |
| commit-msg Hook | git commit | Auto | `.git/hooks/commit-msg` |

### CLAUDE.md Quality Scoring

`/sync-docs` and `doc-sync-checker` evaluate each CLAUDE.md on a 100-point scale:

| Criterion | Max Score | Description |
|-----------|-----------|-------------|
| Commands/workflows | 20 | Build/test/deploy commands present and copy-paste ready |
| Architecture clarity | 20 | Codebase structure understandable from this file alone |
| Non-obvious patterns | 15 | Gotchas, quirks, and conventions documented |
| Conciseness | 15 | No verbose explanations or obvious info |
| Currency | 15 | Reflects current codebase state |
| Actionability | 15 | Instructions are executable, not vague |

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29)

## Troubleshooting

**Commands not appearing after installation**
- Restart your Claude Code session completely (exit and re-enter)
- Verify the plugin is installed: `claude plugin list`
- Check that the marketplace path is correct: `claude plugin marketplace list`

**`/init-project` overwrites existing files**
- The command detects existing files and skips them by default
- If CLAUDE.md already exists, it will ask before overwriting
- Use on a clean directory if you want a fresh structure

**`/sync-docs` quality scores seem low**
- Scores reflect documentation completeness, not code quality
- Focus on adding copy-paste ready commands (20 points) and architecture clarity (20 points) first
- Run `/sync-docs` again after updates to see Before/After improvement

**`doc-sync-checker` agent timeout**
- The agent runs on model: opus, which may take longer for large projects
- For projects with 50+ source directories, the agent may need extra time

## Contributing

1. Fork the repository.
2. Create a feature branch.
   ```bash
   git checkout -b feat/my-feature
   ```
3. Commit your changes using Conventional Commits.
   ```bash
   git commit -m "feat: add support for Rust project detection"
   ```
4. Push to your fork.
   ```bash
   git push origin feat/my-feature
   ```
5. Open a Pull Request against the `main` branch.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

- Maintainer: [whchoi98](https://github.com/whchoi98)
- Email: whchoi98@gmail.com
- Issues: [GitHub Issues](https://github.com/whchoi98/project-init/issues)

---

# 한국어

## 개요

project-init은 Claude Code 프로젝트의 **구조 생성**과 **문서 유지보수**를 자동화하는 플러그인입니다. Claude Code는 `CLAUDE.md` 파일을 통해 프로젝트 컨텍스트를 이해하지만, 이를 생성하고 코드 변경에 맞춰 동기화하는 과정은 수동적이고 실수가 잦습니다.

이 플러그인은 5개의 커맨드를 제공합니다: `/init-project`로 신규/기존 프로젝트 스캐폴딩, `/sync-docs`로 문서 동기화, `/add-module`로 모듈 추가, `/add-runbook`으로 운영 런북 생성, `/add-adr`로 아키텍처 결정 기록, 그리고 0-100점 품질 점수 시스템으로 문서 품질을 객관적으로 측정합니다.

## 주요 기능

- **기존 프로젝트 적응 감지** -- `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml` 등 빌드 파일을 감지하여 기존 프로젝트에 맞게 스캐폴딩합니다. Next.js 앱이면 `app/routes/CLAUDE.md`를, Go 프로젝트면 `cmd/CLAUDE.md`를 생성합니다.
- **CLAUDE.md 품질 점수** -- 6가지 기준(명령어, 아키텍처 명확성, 비자명한 패턴, 간결성, 최신성, 실행 가능성)으로 0-100점 척도 평가합니다. 동기화 시 Before/After 점수를 비교합니다.
- **4단계 자동 동기화 워크플로우** -- 생성된 프로젝트에 Plan 모드 규칙, PostToolUse 훅, `/sync-docs` 커맨드, Git commit-msg 훅이 설치되어 코드 변경 시 문서가 자동으로 따라갑니다.
- **Plan 모드 연동** -- `/plan` 세션 이후 `/init-project`를 실행하면 논의한 아키텍처 결정이 반영된 구조가 생성됩니다. `architecture.md`가 사전 작성되고 ADR이 자동 생성됩니다.
- **confidence 기반 코드 리뷰** -- 생성되는 `code-review` 스킬은 이슈를 0-100점으로 평가하고, 75점 이상만 보고하여 거짓 양성을 필터링합니다.
- **보안 우선 훅** -- PreCommit 시크릿 스캐닝이 API 키와 비밀번호가 포함된 커밋을 차단합니다. commit-msg 훅이 AI Co-Authored-By 라인을 자동 제거합니다.
- **전체 프로젝트 라이프사이클** -- 생성된 프로젝트에 슬래시 커맨드(/review, /test-all, /deploy), 에이전트 정의(code-reviewer, security-auditor), MCP 설정, 온보딩 문서, 운영 스크립트가 포함됩니다.

## 사전 요구 사항

- Claude Code CLI (최신 버전)
- Git

## 설치 방법

```bash
# 리포지토리 클론
git clone https://github.com/whchoi98/project-init.git

# 로컬 마켓플레이스 등록
claude plugin marketplace add ./project-init

# 플러그인 설치
claude plugin install project-init
```

설치 후 Claude Code 세션을 재시작합니다.

## 사용법

```bash
# 새 프로젝트 초기화
/init-project ./my-new-project

# 기존 프로젝트에 Claude Code 구조 추가
/init-project ./existing-app

# 문서 동기화 및 품질 점수 평가
/sync-docs

# 새 모듈 추가 (CLAUDE.md + 아키텍처 문서 업데이트)
/add-module src/auth

# 운영 런북 생성
/add-runbook deploy-production

# 아키텍처 결정 기록
/add-adr use-postgresql
```

### 실행 결과 예시

```
$ /sync-docs

## Sync Report

### Quality Scores (Before -> After)
| File               | Before   | After    | Change |
|--------------------|----------|----------|--------|
| ./CLAUDE.md        | B (82)   | B (87)   | +5     |
| ./src/api/CLAUDE.md| C (62)   | C (69)   | +7     |
| ./src/auth/CLAUDE.md| F (28)  | C (58)   | +30    |

### Changes Made
- Files created: 2
- Files updated: 3
- ADRs suggested: 1
- Runbooks missing: deploy-production, incident-response
```

### Plan 모드 워크플로우

초기화 전에 Plan 세션을 실행하면 컨텍스트를 반영한 프로젝트 구조가 생성됩니다:

```
/plan                              # Plan 모드 진입
# Claude와 아키텍처, 모듈, 기술 선택 논의
# Plan 모드 종료

/init-project ./my-api             # 논의 내용이 반영된 구조 생성
```

| 항목 | Plan 없이 실행 | Plan 후 실행 |
|------|---------------|-------------|
| CLAUDE.md 개요 | 사용자에게 대화형으로 질문 | 논의 내용에서 자동 추출 |
| 모듈 구조 | 기본값 (api, persistence) | 합의한 구조 (api, auth, persistence 등) |
| architecture.md | 빈 템플릿 | Data Flow, Components 사전 작성 |
| ADR | 생성 안 됨 | 논의한 결정으로 자동 생성 |

### 커맨드 목록

| 커맨드 | 설명 |
|--------|------|
| `/init-project [path]` | Claude Code 프로젝트 구조를 초기화합니다. 기존 프로젝트를 감지하여 적응합니다. |
| `/sync-docs` | 모든 문서를 현재 코드 상태와 동기화합니다. 품질 점수를 포함합니다. |
| `/add-module <path>` | 새 모듈 디렉토리를 생성하고 CLAUDE.md와 아키텍처 문서를 업데이트합니다. |
| `/add-runbook <name>` | 운영 런북을 템플릿 기반으로 생성합니다. |
| `/add-adr <title>` | 아키텍처 결정 기록(ADR)을 자동 번호 부여로 생성합니다. |
| `/health-check` | 전체 프로젝트 설정을 검증하고 건강 점수(0-200)를 보고합니다. |

### 스킬 및 에이전트

| 유형 | 이름 | 호출 방식 | 역할 |
|------|------|----------|------|
| 스킬 | `project-scaffolder` | Claude가 대화 중 자동 참조 | 프로젝트 구조 패턴과 컨벤션 지식 |
| 에이전트 | `doc-sync-checker` | 서브에이전트로 병렬 실행 (model: opus) | 문서 갭 분석 및 품질 점수 평가 |

## 프로젝트 구조

```
project-init/                              # 마켓플레이스 루트
├── .claude-plugin/
│   └── marketplace.json                   # 마켓플레이스 매니페스트 (v1.0.0)
├── LICENSE                                # MIT 라이선스
├── README.md
└── plugins/
    └── project-init/                      # 플러그인 패키지 (v2.0.0)
        ├── .claude-plugin/
        │   └── plugin.json                # 플러그인 매니페스트
        ├── commands/
        │   ├── init-project.md            # /init-project 커맨드
        │   ├── sync-docs.md               # /sync-docs 커맨드
        │   ├── add-module.md              # /add-module 커맨드
        │   ├── add-runbook.md             # /add-runbook 커맨드
        │   ├── add-adr.md                 # /add-adr 커맨드
        │   └── health-check.md            # /health-check 커맨드
        ├── agents/
        │   └── doc-sync-checker.md        # 문서 동기화 검사 에이전트
        └── skills/
            └── project-scaffolder/
                ├── SKILL.md               # 구조 패턴 지식 스킬
                └── references/            # 8개 템플릿 참조 파일
                    ├── claude-md-template.md
                    ├── docs-templates.md
                    ├── hook-scripts.md
                    ├── settings-json-template.md
                    ├── skills-templates.md
                    ├── agents-templates.md
                    ├── mcp-json-template.md
                    └── scripts-templates.md
```

### 생성되는 프로젝트 구조

새 프로젝트에서 `/init-project`를 실행하면 다음 구조가 생성됩니다:

```
project/
├── CLAUDE.md                          # 프로젝트 메모리 + 자동 동기화 규칙
├── README.md
├── .gitignore
├── .env.example                       # 환경 변수 템플릿
├── .editorconfig                      # 에디터 포맷 규칙
├── .mcp.json                          # MCP 서버 설정
├── docs/
│   ├── architecture.md                # 아키텍처 문서
│   ├── onboarding.md                  # 신규 개발자 온보딩 가이드
│   ├── api-reference.md               # API 문서 (해당 시)
│   ├── decisions/.template.md         # ADR 템플릿
│   └── runbooks/.template.md          # 런북 템플릿
├── .claude/
│   ├── settings.json                  # 전체 훅 등록
│   ├── hooks/
│   │   ├── check-doc-sync.sh         # PostToolUse: 문서 동기화 감지
│   │   ├── secret-scan.sh            # PreCommit: 시크릿 스캐닝
│   │   ├── session-context.sh        # SessionStart: 컨텍스트 로딩
│   │   └── notify.sh                 # Notification: 웹훅 알림
│   ├── commands/
│   │   ├── review.md                 # /review: 코드 리뷰
│   │   ├── test-all.md               # /test-all: 테스트 실행
│   │   └── deploy.md                 # /deploy: 빌드 및 배포
│   ├── skills/
│   │   ├── code-review/SKILL.md      # confidence 기반 코드 리뷰
│   │   ├── refactor/SKILL.md         # 안전한 리팩토링
│   │   ├── release/SKILL.md          # Semver 릴리스 자동화
│   │   └── sync-docs/SKILL.md        # 문서 동기화
│   └── agents/
│       ├── code-reviewer.yml          # 병렬 코드 리뷰
│       └── security-auditor.yml       # 보안 감사
├── scripts/
│   ├── setup.sh                       # 신규 개발자용 프로젝트 설정
│   └── install-hooks.sh              # Git 훅 설치
├── tools/
│   └── prompts/
├── tests/
│   ├── unit/CLAUDE.md
│   └── integration/CLAUDE.md
└── src/
    ├── api/CLAUDE.md                  # API 모듈 컨텍스트
    └── persistence/CLAUDE.md          # 영속성 모듈 컨텍스트
```

### 기존 프로젝트 감지

| 감지 파일 | 프로젝트 유형 | 소스 디렉토리 | 자동 채워지는 명령어 |
|-----------|-------------|-------------|---------------------|
| `package.json` | Node.js | src/, app/, lib/, components/ | npm/yarn/pnpm 스크립트 |
| `pyproject.toml` | Python | src/, app/, lib/ | pip, pytest, ruff |
| `go.mod` | Go | cmd/, pkg/, internal/ | go build, go test |
| `Cargo.toml` | Rust | src/ | cargo build, cargo test |
| `pom.xml` / `build.gradle` | Java/Kotlin | src/main/, src/test/ | mvn, gradle |
| 없음 | 새 프로젝트 | src/api/, src/persistence/ | (사용자에게 질문) |

### 자동 동기화 메커니즘

| 메커니즘 | 트리거 | 유형 | 위치 |
|---------|--------|------|------|
| 자동 동기화 규칙 | Plan 모드 종료 | 자동 | `CLAUDE.md` |
| PostToolUse 훅 | Write/Edit 이후 | 자동 | `.claude/settings.json` + `.claude/hooks/` |
| /sync-docs | 사용자 호출 | 수동 | 플러그인 커맨드 |
| commit-msg 훅 | git commit | 자동 | `.git/hooks/commit-msg` |

### CLAUDE.md 품질 점수

`/sync-docs`와 `doc-sync-checker`는 각 CLAUDE.md를 100점 만점으로 평가합니다:

| 기준 | 배점 | 설명 |
|------|------|------|
| 명령어/워크플로우 | 20 | 빌드/테스트/배포 명령어가 복사-붙여넣기 가능한 형태로 존재하는지 |
| 아키텍처 명확성 | 20 | 이 파일만으로 코드베이스 구조를 이해할 수 있는지 |
| 비자명한 패턴 | 15 | 주의사항, 특이점, 컨벤션이 문서화되어 있는지 |
| 간결성 | 15 | 장황한 설명이나 자명한 정보가 없는지 |
| 최신성 | 15 | 현재 코드베이스 상태를 반영하는지 |
| 실행 가능성 | 15 | 지시사항이 모호하지 않고 실행 가능한지 |

등급: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29)

## 문제 해결

**설치 후 커맨드가 표시되지 않는 경우**
- Claude Code 세션을 완전히 재시작합니다 (종료 후 다시 진입)
- 플러그인 설치 확인: `claude plugin list`
- 마켓플레이스 경로 확인: `claude plugin marketplace list`

**`/init-project`가 기존 파일을 덮어쓰는 경우**
- 기존 파일을 감지하면 기본적으로 건너뜁니다
- CLAUDE.md가 이미 존재하면 덮어쓰기 전에 확인합니다
- 새 구조가 필요하면 빈 디렉토리에서 실행합니다

**`/sync-docs` 품질 점수가 낮게 나오는 경우**
- 점수는 문서 완성도를 반영하며, 코드 품질과는 무관합니다
- 복사-붙여넣기 가능한 명령어(20점)와 아키텍처 명확성(20점)을 먼저 보강합니다
- 업데이트 후 다시 실행하면 Before/After 개선을 확인할 수 있습니다

**`doc-sync-checker` 에이전트 타임아웃**
- 에이전트는 model: opus로 실행되며, 대규모 프로젝트에서 시간이 더 걸릴 수 있습니다
- 소스 디렉토리가 50개 이상인 프로젝트는 추가 시간이 필요합니다

## 기여 방법

1. 리포지토리를 Fork합니다.
2. 기능 브랜치를 생성합니다.
   ```bash
   git checkout -b feat/my-feature
   ```
3. Conventional Commits 형식으로 커밋합니다.
   ```bash
   git commit -m "feat: Rust 프로젝트 감지 지원 추가"
   ```
4. Fork한 리포지토리에 Push합니다.
   ```bash
   git push origin feat/my-feature
   ```
5. `main` 브랜치를 대상으로 Pull Request를 생성합니다.

## 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고합니다.

## 연락처

- 메인테이너: [whchoi98](https://github.com/whchoi98)
- 이메일: whchoi98@gmail.com
- 이슈: [GitHub Issues](https://github.com/whchoi98/project-init/issues)
