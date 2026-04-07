# Changelog

[![English](https://img.shields.io/badge/lang-English-blue.svg)](#english) [![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](#한국어)

---

# English

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Automated test framework (`tests/run-all.sh`) with 114 tests across 3 categories: hooks (27), secret patterns (22), structure (65)
- Test fixture files for secret pattern validation (true positives and false positives)
- Error recovery sections in all generated commands: `/deploy` (5 scenarios including full rollback), `/review` (3 scenarios), `/test-all` (failure pattern table + multi-failure diagnosis)
- Structured output schemas for agents: `code-reviewer` (Verdict: PASS/WARN/FAIL, Summary table, Guideline field) and `security-auditor` (category breakdown, Recommendations section, Passed Checks checklist)
- Deny list in `settings.json` blocking dangerous commands: `rm -rf`, `git push --force`, `git reset --hard`, `eval`, `curl|bash`, `python3 -c import os`
- `tests-templates.md` reference template for test framework generation by `/init-project`
- Module `CLAUDE.md` files for `tests/`, `docs/`, `scripts/` directories
- Harness Engineering section in README explaining the plugin as a harness automation tool
- Recommended Workflow section in README: brainstorm → plan → implement → /init-project → /sync-docs

### Changed

- **BREAKING:** `/init-project` now generates 15 steps (was 14), adding test framework generation (Step 14)
- Secret scan patterns hardened: replaced broad base64 pattern with context-aware AWS Secret Key detection; added Stripe, Google, Azure, GitHub token patterns
- Tool scoping hardened: `Bash(python3:*)` → `Bash(python3 -c:*)`, `Bash(cat:*)` removed in favor of Read tool
- `check-doc-sync.sh` hook walks parent directories to find `CLAUDE.md` instead of only checking the immediate directory
- Reference templates (9 total, was 8) fully synced with project-level improvements
- Plugin version synchronized: `marketplace.json` and `plugin.json` both at 2.0.0

### Fixed

- **`PreCommit` → `PreToolUse`**: `PreCommit` is not a valid Claude Code hook event; replaced with `PreToolUse` (matcher: `Bash`) across all templates, commands, and documentation (15 files)
- **Invalid deny pattern**: `Bash(python3 -c:*import os*)` — `:*` mid-pattern breaks Claude Code's parser; fixed to `Bash(python3 -c*import os*)`
- **Invalid deny pattern**: `Bash(curl:* | bash)` and `Bash(wget:* | bash)` — `:*` mid-pattern causes settings.json parse failure; fixed to glob wildcards `Bash(curl*| bash*)` and `Bash(wget*| bash*)` in both `settings.json` and `settings-json-template.md`
- Template count references updated from 8 to 9 in architecture.md, SKILL.md, onboarding.md, and structure tests
- Phantom `scripts/deploy.sh` reference removed from architecture.md (file doesn't exist in this repo)
- Empty `tools/prompts/` removed from CLAUDE.md project structure
- Version mismatch between `marketplace.json` (1.0.0) and `plugin.json` (2.0.0)
- `check-doc-sync.sh` false warnings for nested directories where parent has `CLAUDE.md`
- Secret scan false positives from overly broad AWS Secret Key pattern
- GitHub Push Protection blocking test fixtures (now runtime-constructed)

## [2.0.0] - 2026-04-05

### Added

- `/add-runbook` command for creating operational runbooks from template with structured steps, verification, and rollback sections
- `/add-adr` command for creating Architecture Decision Records with auto-numbering and options-considered format
- `/health-check` command for validating entire project setup with health score (0-200, A-F grades)
- PreCommit hook (`secret-scan.sh`) for scanning staged files for API keys, passwords, and tokens
- SessionStart hook (`session-context.sh`) for loading project context at session start
- Notification hook (`notify.sh`) for webhook alerts on significant events
- Git commit-msg hook enhancement for case-insensitive Co-Authored-By removal (AI contributor exclusion)
- Agent templates for generated projects: `code-reviewer` and `security-auditor`
- Slash command templates for generated projects: `/review`, `/test-all`, `/deploy`
- MCP configuration template (`.mcp.json`) with GitHub, Slack, PostgreSQL, Playwright examples
- `onboarding.md` document template for new developer onboarding
- `api-reference.md` document template for API documentation
- `.env.example` template with security rules (no real secrets)
- `scripts/setup.sh` and `scripts/install-hooks.sh` templates for generated projects
- `tests/` directory structure generation (unit, integration) with CLAUDE.md
- Production-grade architecture.md template with bilingual language switcher, layer-based components, ASCII box diagrams, data flow summaries, infrastructure tables, and key design decisions
- Architecture diagram style guide using Unicode box-drawing characters (`┌─┐│└─┘▶▼`)
- Multi-level architecture doc freshness check (component sync, diagram accuracy, layer coverage, IaC tables, bilingual consistency)
- CLAUDE.md anti-pattern detection in `doc-sync-checker` (500+ lines, vague instructions, secrets, stale deps)
- Runbook coverage check in `doc-sync-checker` agent (recommends runbooks based on project characteristics)
- ADR freshness check in `doc-sync-checker` agent (flags stale or proposed ADRs)
- Runbook audit phase in `/sync-docs` command (Phase 6)
- Troubleshooting section in README.md (both English and Korean)
- Example command output in README.md Usage section
- `.gitignore`, `.editorconfig`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`
- GitHub issue templates (bug report, feature request) and PR template

### Changed

- **BREAKING:** `/init-project` now generates 14 steps (was 11), producing a more complete project structure
- Rewrite README.md as bilingual (English/Korean) format with shields.io badges
- Expand `doc-sync-checker` agent from 6 tasks to 9 tasks (runbook, ADR freshness, anti-patterns)
- Expand settings.json template to include all 4 hook types (SessionStart, PreCommit, PostToolUse, Notification)
- Expand skills-templates.md to include common slash command templates
- Expand docs-templates.md to include onboarding, API reference, and .env templates
- Expand SKILL.md knowledge base with extension types, anti-patterns, and security best practices
- Fix installation instructions to use `git clone` workflow instead of missing setup script
- Replace `tree` command with `find` in `/sync-docs` for cross-platform portability
- Update author from "Claude Code Plugin" to "whchoi98" in plugin.json
- Update email to whchoi98@gmail.com across all manifests

## [1.0.0] - 2026-03-07

### Added

- `/init-project` command with adaptive language and framework detection for existing projects ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- `/sync-docs` command with CLAUDE.md quality scoring on a 0-100 scale (A-F grades)
- `/add-module` command with automatic architecture docs and root CLAUDE.md update
- `project-scaffolder` knowledge skill for project structure patterns and conventions
- `doc-sync-checker` subagent for parallel documentation gap analysis (model: opus)
- 4-layer auto-sync workflow: Plan mode rules, PostToolUse hook, `/sync-docs` command, and Git commit-msg hook
- Plan mode integration for context-aware project generation with pre-filled architecture docs and ADRs ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code marketplace registration support ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Existing project detection for Node.js, Python, Go, Rust, and Java/Kotlin
- Confidence-based code review skill with 75+ threshold filtering in generated projects
- 5 reference template files (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- Restructure repository as marketplace with plugin in `plugins/project-init/` subdirectory ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/whchoi98/project-init/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/whchoi98/project-init/releases/tag/v1.0.0

---

# 한국어

이 프로젝트의 모든 주요 변경 사항은 이 파일에 기록됩니다.
이 문서는 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 기반으로 하며,
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 따릅니다.

## [Unreleased]

### Added

- 자동화된 테스트 프레임워크(`tests/run-all.sh`) 추가: 3개 카테고리 114개 테스트 (훅 27, 시크릿 패턴 22, 구조 65)
- 시크릿 패턴 검증용 테스트 픽스처 파일 추가 (True Positive / False Positive)
- 모든 생성 커맨드에 에러 복구 섹션 추가: `/deploy` (전체 롤백 포함 5개 시나리오), `/review` (3개 시나리오), `/test-all` (실패 패턴 표 + 다중 실패 진단)
- 에이전트 구조화된 출력 스키마 추가: `code-reviewer` (Verdict, Summary 테이블, Guideline 필드), `security-auditor` (카테고리별 분류, Recommendations, Passed Checks 체크리스트)
- `settings.json` Deny 목록 추가: `rm -rf`, `git push --force`, `git reset --hard`, `eval`, `curl|bash`, `python3 -c import os` 차단
- `/init-project`의 테스트 프레임워크 생성을 위한 `tests-templates.md` 참조 템플릿 추가
- `tests/`, `docs/`, `scripts/` 디렉토리용 모듈 `CLAUDE.md` 추가
- README에 하네스 엔지니어링 섹션 추가: 플러그인을 하네스 자동화 도구로 설명
- README에 권장 워크플로우 섹션 추가: brainstorm → plan → implement → /init-project → /sync-docs

### Changed

- **BREAKING:** `/init-project`가 15단계로 확장 (기존 14단계), 테스트 프레임워크 생성(Step 14) 추가
- 시크릿 스캔 패턴 강화: 광범위 Base64 패턴을 컨텍스트 기반 AWS Secret Key 감지로 교체; Stripe, Google, Azure, GitHub 토큰 패턴 추가
- 도구 범위 강화: `Bash(python3:*)` → `Bash(python3 -c:*)`, `Bash(cat:*)` 제거 후 Read 도구 사용
- `check-doc-sync.sh` 훅이 부모 디렉토리를 탐색하여 `CLAUDE.md`를 찾도록 개선
- 참조 템플릿 9개(기존 8개) 전체를 프로젝트 수준 개선 사항과 동기화
- 플러그인 버전 동기화: `marketplace.json`과 `plugin.json` 모두 2.0.0

### Fixed

- **`PreCommit` → `PreToolUse`**: `PreCommit`은 유효한 Claude Code 훅 이벤트가 아님; 모든 템플릿, 커맨드, 문서에서 `PreToolUse` (matcher: `Bash`)로 교체 (15개 파일)
- **잘못된 deny 패턴**: `Bash(python3 -c:*import os*)` — 패턴 중간의 `:*`가 Claude Code 파서를 깨뜨림; `Bash(python3 -c*import os*)`로 수정
- **잘못된 deny 패턴**: `Bash(curl:* | bash)` 및 `Bash(wget:* | bash)` — 패턴 중간의 `:*`로 settings.json 파싱 실패; glob 와일드카드 `Bash(curl*| bash*)` 및 `Bash(wget*| bash*)`로 수정 (`settings.json` 및 `settings-json-template.md` 양쪽 모두)
- 템플릿 수 참조를 8에서 9로 업데이트 (architecture.md, SKILL.md, onboarding.md, 구조 테스트)
- architecture.md에서 존재하지 않는 `scripts/deploy.sh` 참조 제거
- CLAUDE.md 프로젝트 구조에서 빈 `tools/prompts/` 제거
- `marketplace.json` (1.0.0)과 `plugin.json` (2.0.0) 간 버전 불일치 수정
- 부모 디렉토리에 `CLAUDE.md`가 있는데 하위 디렉토리에서 거짓 경고하는 `check-doc-sync.sh` 버그 수정
- 지나치게 광범위한 AWS Secret Key 패턴으로 인한 시크릿 스캔 거짓 양성 수정
- GitHub Push Protection이 테스트 픽스처를 차단하는 문제 수정 (런타임 조합으로 전환)

## [2.0.0] - 2026-04-05

### Added

- 운영 런북을 템플릿 기반으로 생성하는 `/add-runbook` 커맨드 추가 (검증, 롤백 섹션 포함)
- 아키텍처 결정 기록(ADR)을 자동 번호 부여로 생성하는 `/add-adr` 커맨드 추가
- 전체 프로젝트 설정을 검증하는 `/health-check` 커맨드 추가 (건강 점수 0-200, A-F 등급)
- PreCommit 훅(`secret-scan.sh`) 추가: 스테이징된 파일에서 API 키, 비밀번호, 토큰 스캔
- SessionStart 훅(`session-context.sh`) 추가: 세션 시작 시 프로젝트 컨텍스트 로딩
- Notification 훅(`notify.sh`) 추가: 중요 이벤트 시 웹훅 알림 전송
- Git commit-msg 훅 강화: 대소문자 무관 Co-Authored-By 제거 (AI 기여자 배제)
- 생성 프로젝트용 에이전트 템플릿 추가: `code-reviewer`, `security-auditor`
- 생성 프로젝트용 슬래시 커맨드 템플릿 추가: `/review`, `/test-all`, `/deploy`
- MCP 설정 템플릿(`.mcp.json`) 추가: GitHub, Slack, PostgreSQL, Playwright 예시 포함
- `onboarding.md` 문서 템플릿 추가: 신규 개발자 온보딩 가이드
- `api-reference.md` 문서 템플릿 추가: API 문서화
- `.env.example` 템플릿 추가: 보안 규칙 적용 (실제 시크릿 미포함)
- `scripts/setup.sh`, `scripts/install-hooks.sh` 템플릿 추가
- `tests/` 디렉토리 구조 생성 (unit, integration) 및 CLAUDE.md 포함
- 이중 언어 전환기, 레이어 기반 컴포넌트, ASCII 박스 다이어그램, 데이터 플로우 요약, 인프라 테이블, 핵심 설계 결정을 포함하는 프로덕션 수준 architecture.md 템플릿 추가
- Unicode 박스 그리기 문자(`┌─┐│└─┘▶▼`)를 사용하는 아키텍처 다이어그램 스타일 가이드 추가
- 다중 레벨 아키텍처 문서 최신성 검사 추가 (컴포넌트 동기화, 다이어그램 정확성, 레이어 커버리지, IaC 테이블, 이중 언어 일관성)
- `doc-sync-checker`에 CLAUDE.md 안티패턴 감지 추가 (500줄 초과, 모호한 지시, 시크릿, 오래된 의존성)
- `doc-sync-checker` 에이전트에 런북 커버리지 검사 추가 (프로젝트 특성에 따라 런북 추천)
- `doc-sync-checker` 에이전트에 ADR 최신성 검사 추가 (오래된 Proposed 상태 ADR 감지)
- `/sync-docs` 커맨드에 런북 감사 단계(Phase 6) 추가
- README.md에 문제 해결(Troubleshooting) 섹션 및 실행 결과 예시 추가
- `.gitignore`, `.editorconfig`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` 추가
- GitHub 이슈 템플릿(버그 리포트, 기능 요청) 및 PR 템플릿 추가

### Changed

- **BREAKING:** `/init-project`가 14단계로 확장 (기존 11단계), 더 완전한 프로젝트 구조 생성
- README.md를 이중 언어(영어/한국어) 형식으로 shields.io 뱃지와 함께 전면 재작성
- `doc-sync-checker` 에이전트를 6개에서 9개 태스크로 확장 (런북, ADR 최신성, 안티패턴)
- settings.json 템플릿을 4개 훅 유형 모두 포함하도록 확장 (SessionStart, PreCommit, PostToolUse, Notification)
- skills-templates.md를 일반 슬래시 커맨드 템플릿 포함하도록 확장
- docs-templates.md를 온보딩, API 참조, .env 템플릿 포함하도록 확장
- SKILL.md를 확장 유형, 안티패턴, 보안 모범 사례 포함하도록 확장
- 설치 안내를 누락된 설정 스크립트 대신 `git clone` 워크플로우로 수정
- `/sync-docs`의 `tree` 명령어를 크로스 플랫폼 호환을 위해 `find`로 교체
- plugin.json의 author를 "Claude Code Plugin"에서 "whchoi98"로 변경
- 모든 매니페스트의 이메일을 whchoi98@gmail.com으로 변경

## [1.0.0] - 2026-03-07

### Added

- 기존 프로젝트의 언어 및 프레임워크를 자동 감지하는 `/init-project` 커맨드 추가 ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- CLAUDE.md 품질을 0-100점(A-F 등급)으로 평가하는 `/sync-docs` 커맨드 추가
- 아키텍처 문서와 루트 CLAUDE.md를 자동 업데이트하는 `/add-module` 커맨드 추가
- 프로젝트 구조 패턴과 컨벤션 지식을 제공하는 `project-scaffolder` 스킬 추가
- 문서 갭 분석을 병렬 실행하는 `doc-sync-checker` 서브에이전트 추가 (model: opus)
- Plan 모드 규칙, PostToolUse 훅, `/sync-docs` 커맨드, Git commit-msg 훅으로 구성된 4단계 자동 동기화 워크플로우 추가
- Plan 모드 연동으로 아키텍처 문서와 ADR이 사전 작성되는 컨텍스트 기반 프로젝트 생성 지원 ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code 마켓플레이스 등록 지원 ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Node.js, Python, Go, Rust, Java/Kotlin 기존 프로젝트 감지 지원
- 생성 프로젝트에 75점 이상만 보고하는 confidence 기반 코드 리뷰 스킬 포함
- 5개 참조 템플릿 파일 제공 (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- 리포지토리를 마켓플레이스 구조로 변경, 플러그인을 `plugins/project-init/` 하위 디렉토리로 이동 ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/whchoi98/project-init/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/whchoi98/project-init/releases/tag/v1.0.0
