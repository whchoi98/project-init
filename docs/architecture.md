# Architecture

<p align="center">
  <a href="#-한국어"><kbd>한국어</kbd></a>&nbsp;&nbsp;&nbsp;
  <a href="#-english"><kbd>English</kbd></a>
</p>

---

# 한국어

## System Overview

project-init은 Claude Code 플러그인으로, 프로젝트 구조 초기화와 문서 자동 동기화를 제공합니다.
마켓플레이스 저장소로 배포되며, 단일 플러그인(`project-init`)을 포함합니다.
사용자가 `/init-project`을 실행하면 감지된 프로젝트에 맞춤 구조를 생성합니다.

## Components

### Plugin Layer
- **plugins/project-init/commands/** -- 8개의 슬래시 커맨드 (init-project, sync-docs, generate-readme, generate-changelog, add-adr, add-module, add-runbook, health-check). 각 `.md` 파일이 하나의 커맨드를 정의.
- **plugins/project-init/agents/** -- doc-sync-checker 에이전트. 문서 동기화 상태를 병렬로 분석.
- **plugins/project-init/skills/** -- project-scaffolder 스킬. `references/` 디렉토리에 12개의 템플릿 파일 포함 (공통 writing-style-guide 포함).

### Generated Project Layer
- **.claude/hooks/** -- PostToolUse(문서 동기화 감지), PreToolUse(시크릿 스캔), SessionStart(컨텍스트 로드), Notification(웹훅).
- **.claude/skills/** -- code-review(신뢰도 기반 필터링), refactor, release, sync-docs 스킬.
- **.claude/commands/** -- review, test-all, deploy 커맨드.
- **.claude/agents/** -- code-reviewer(green), security-auditor(red) 에이전트.

### Documentation Layer
- **docs/architecture.md** -- 이중언어 아키텍처 문서 (이 파일).
- **docs/decisions/** -- ADR(Architecture Decision Records).
- **docs/runbooks/** -- 운영 런북.
- **docs/onboarding.md** -- 개발자 온보딩 가이드.

### Distribution Layer
- **.claude-plugin/marketplace.json** -- 마켓플레이스 매니페스트.
- **plugins/project-init/.claude-plugin/plugin.json** -- 플러그인 매니페스트.

## Full Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Plugin Marketplace                         │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────┐     │
│  │ marketplace.json │───▶│ plugins/project-init/       │     │
│  │ (distribution)   │    │                             │     │
│  └─────────────────┘    │  ┌──────────┐ ┌──────────┐  │     │
│                         │  │ commands/ │ │ agents/  │  │     │
│                         │  │ (8 cmds)  │ │ (1 agent)│  │     │
│                         │  └──────────┘ └──────────┘  │     │
│                         │  ┌──────────────────────┐   │     │
│                         │  │ skills/scaffolder/    │   │     │
│                         │  │  references/(12 tmpl) │   │     │
│                         │  └──────────────────────┘   │     │
│                         └─────────────────────────────┘     │
└─────────────────────────────┬───────────────────────────────┘
                              │ /init-project
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Generated Project Structure                   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ .claude/     │  │ docs/        │  │ scripts/     │      │
│  │  hooks/ (4)  │  │  decisions/  │  │  setup.sh    │      │
│  │  skills/ (4) │  │  runbooks/   │  │  install.sh  │      │
│  │  commands/(3)│  │  arch.md     │  └──────────────┘      │
│  │  agents/ (2) │  │  onboard.md  │                        │
│  │  settings.json│ └──────────────┘                        │
│  └──────────────┘                                          │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ CLAUDE.md    │  │ .mcp.json    │                        │
│  │ (auto-sync)  │  │ .env.example │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Summary

```
User -> /init-project -> Detect Project -> Read Templates -> Generate Structure -> Install Hooks
                                                                                       |
                                            ┌──────────────────────────────────────────┘
                                            ▼
                                     4-Layer Auto-Sync
                                            |
                           ┌────────────────┼────────────────┐
                           ▼                ▼                ▼
                     CLAUDE.md Rules   PostToolUse Hook   /sync-docs
                     (Plan mode)       (Write/Edit)       (Manual)
                           |                |                |
                           └────────────────┼────────────────┘
                                            ▼
                                      Docs Updated
```

## Key Design Decisions

- **마켓플레이스 구조** -- 플러그인을 `plugins/` 하위 디렉토리로 구성하여 단일 저장소에서 여러 플러그인을 관리할 수 있도록 확장성 확보.
- **Markdown 기반 정의** -- 모든 커맨드/스킬/에이전트를 Markdown으로 정의하여 버전 관리와 코드 리뷰가 용이하도록 함.
- **4계층 자동 동기화** -- Plan mode 규칙, PostToolUse 훅, /sync-docs 커맨드, commit-msg 훅의 4단계로 문서 동기화를 보장.
- **신뢰도 기반 코드 리뷰** -- 75점 이상의 이슈만 보고하여 거짓 양성을 필터링하고 리뷰 피로 감소.
- **이중언어 지원** -- 모든 사용자 대면 문서(README, CHANGELOG, architecture, ADR, runbook)를 한국어/영어 병기로 제공. 공통 writing-style-guide로 일관성 유지.

## Operations
- Deployment: see [docs/runbooks/](runbooks/) (create deployment runbook as needed)
- Release: use `/release` skill

---

# English

## System Overview

project-init is a Claude Code plugin that provides project structure initialization and automated documentation synchronization.
It is distributed as a marketplace repository containing a single plugin (`project-init`).
When users run `/init-project`, it detects the existing project and generates a tailored structure.

## Components

### Plugin Layer
- **plugins/project-init/commands/** -- 8 slash commands (init-project, sync-docs, generate-readme, generate-changelog, add-adr, add-module, add-runbook, health-check). Each `.md` file defines one command.
- **plugins/project-init/agents/** -- doc-sync-checker agent. Analyzes documentation sync status in parallel.
- **plugins/project-init/skills/** -- project-scaffolder skill. Contains 12 reference template files in `references/` (includes shared writing-style-guide).

### Generated Project Layer
- **.claude/hooks/** -- PostToolUse (doc sync detection), PreToolUse (secret scanning), SessionStart (context loading), Notification (webhook).
- **.claude/skills/** -- code-review (confidence-based filtering), refactor, release, sync-docs skills.
- **.claude/commands/** -- review, test-all, deploy commands.
- **.claude/agents/** -- code-reviewer (green), security-auditor (red) agents.

### Documentation Layer
- **docs/architecture.md** -- Bilingual architecture document (this file).
- **docs/decisions/** -- Architecture Decision Records (ADRs).
- **docs/runbooks/** -- Operational runbooks.
- **docs/onboarding.md** -- Developer onboarding guide.

### Distribution Layer
- **.claude-plugin/marketplace.json** -- Marketplace manifest.
- **plugins/project-init/.claude-plugin/plugin.json** -- Plugin manifest.

## Full Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Plugin Marketplace                         │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────┐     │
│  │ marketplace.json │───▶│ plugins/project-init/       │     │
│  │ (distribution)   │    │                             │     │
│  └─────────────────┘    │  ┌──────────┐ ┌──────────┐  │     │
│                         │  │ commands/ │ │ agents/  │  │     │
│                         │  │ (8 cmds)  │ │ (1 agent)│  │     │
│                         │  └──────────┘ └──────────┘  │     │
│                         │  ┌──────────────────────┐   │     │
│                         │  │ skills/scaffolder/    │   │     │
│                         │  │  references/(12 tmpl) │   │     │
│                         │  └──────────────────────┘   │     │
│                         └─────────────────────────────┘     │
└─────────────────────────────┬───────────────────────────────┘
                              │ /init-project
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Generated Project Structure                   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ .claude/     │  │ docs/        │  │ scripts/     │      │
│  │  hooks/ (4)  │  │  decisions/  │  │  setup.sh    │      │
│  │  skills/ (4) │  │  runbooks/   │  │  install.sh  │      │
│  │  commands/(3)│  │  arch.md     │  └──────────────┘      │
│  │  agents/ (2) │  │  onboard.md  │                        │
│  │  settings.json│ └──────────────┘                        │
│  └──────────────┘                                          │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ CLAUDE.md    │  │ .mcp.json    │                        │
│  │ (auto-sync)  │  │ .env.example │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Summary

```
User -> /init-project -> Detect Project -> Read Templates -> Generate Structure -> Install Hooks
                                                                                       |
                                            ┌──────────────────────────────────────────┘
                                            ▼
                                     4-Layer Auto-Sync
                                            |
                           ┌────────────────┼────────────────┐
                           ▼                ▼                ▼
                     CLAUDE.md Rules   PostToolUse Hook   /sync-docs
                     (Plan mode)       (Write/Edit)       (Manual)
                           |                |                |
                           └────────────────┼────────────────┘
                                            ▼
                                      Docs Updated
```

## Key Design Decisions

- **Marketplace structure** -- Plugins organized under `plugins/` subdirectory to support multiple plugins from a single repository.
- **Markdown-based definitions** -- All commands/skills/agents defined as Markdown for easy version control and code review.
- **4-layer auto-sync** -- Plan mode rules, PostToolUse hooks, /sync-docs command, and commit-msg hook ensure documentation stays current.
- **Confidence-based code review** -- Only reports issues scoring 75+ to filter false positives and reduce review fatigue.
- **Bilingual support** -- All user-facing documents (README, CHANGELOG, architecture, ADR, runbook) provided in Korean/English. Shared writing-style-guide ensures consistency.

## Operations
- Deployment: see [docs/runbooks/](runbooks/) (create deployment runbook as needed)
- Release: use `/release` skill
