# Runbook: Update or Remove the Plugin from the Marketplace

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Overview
End-user procedure for updating an already-installed `project-init` plugin to a new version, or removing it cleanly. This runbook is for plugin consumers; for the maintainer-side release procedure, see `release.md`.

## When to Use
- A new version is announced (check `CHANGELOG.md` or the marketplace listing) and the local installation is on an older version.
- A breaking change is reported and a downgrade or removal is required.
- The plugin is no longer needed and should be uninstalled cleanly.

## Prerequisites
- Claude Code CLI installed and authenticated.
- The marketplace entry was previously added with `claude plugin marketplace add ...`.
- No in-flight Claude Code session is using `project-init` commands (close active sessions first).

## Procedure

### 1. Identify the Current Installation

```bash
claude plugin list | grep project-init
claude plugin marketplace list | grep project-init
```

Record the currently installed version and the marketplace source path or URL. If the plugin is not listed, it is not installed; skip to Step 4 only if a removal cleanup is needed.

### 2. Pull the Latest Marketplace Metadata

The marketplace entry caches metadata. Refreshing it picks up new versions.

```bash
claude plugin marketplace update project-init
```

If the source is a local directory, the maintainer must have already pushed the new version's commits and tag (`vX.Y.Z`) into that directory.

### 3. Reinstall to the New Version

```bash
claude plugin install project-init
claude plugin list | grep project-init
```

The reported version should now be the new release. Verify by checking the published `CHANGELOG.md` for the version line.

### 4. Remove the Plugin (uninstall path)

If the goal is removal rather than update:

```bash
claude plugin uninstall project-init
claude plugin marketplace remove project-init
claude plugin list | grep project-init
```

The final command should return no result. Optionally remove any project-level traces left behind:

```bash
ls .claude/settings.local.json 2>/dev/null
ls .claude/hooks/ 2>/dev/null
```

These files belong to the consuming project (not the plugin) and are not removed by uninstall. Edit them only if you no longer want the hooks or local permissions.

## Verification

- [ ] `claude plugin list` reports the expected version (or no entry, if uninstalling).
- [ ] A previously installed slash command (for example, `/health-check`) executes the new version's behavior, or fails with "command not found" if uninstalled.
- [ ] No stale references to the old version remain in `claude plugin marketplace list` output.

## Rollback

If the new version is broken, downgrade to the previous version:

```bash
claude plugin uninstall project-init
git -C <marketplace-source-path> checkout v<previous-version>
claude plugin marketplace update project-init
claude plugin install project-init
claude plugin list | grep project-init
```

Restore the marketplace source to the latest tag once the upstream issue is fixed:

```bash
git -C <marketplace-source-path> checkout main
claude plugin marketplace update project-init
```

## Notes
- Last verified: 2026-05-05
- The marketplace source path used in `marketplace add` is recorded by Claude Code and is not changed by `update`. To switch sources (for example, from a local directory to a remote git URL), `marketplace remove` and re-add with the new source.
- Project-local files (`.claude/settings.local.json`, `.claude/hooks/`, generated `CLAUDE.md` files) are owned by the consuming project, not the plugin, and persist after uninstall.

---

<a id="korean"></a>

# 한국어

## 개요
이미 설치된 `project-init` 플러그인을 새 버전으로 업데이트하거나 깨끗이 제거하는 최종 사용자 절차입니다. 이 런북은 플러그인 소비자용입니다. 메인테이너 측 릴리스 절차는 `release.md`를 참조합니다.

## 사용 시점
- 새 버전이 공지되고(`CHANGELOG.md` 또는 마켓플레이스 목록 확인) 로컬 설치가 이전 버전인 경우.
- 호환성 깨짐이 보고되어 다운그레이드나 제거가 필요한 경우.
- 플러그인이 더 이상 필요하지 않아 깨끗하게 제거하려는 경우.

## 사전 요구 사항
- Claude Code CLI 설치 및 인증 완료.
- 이전에 `claude plugin marketplace add ...`로 마켓플레이스 항목이 추가됨.
- `project-init` 명령을 사용 중인 Claude Code 세션이 없음(활성 세션을 먼저 종료).

## 절차

### 1. 현재 설치 확인

```bash
claude plugin list | grep project-init
claude plugin marketplace list | grep project-init
```

현재 설치된 버전과 마켓플레이스 소스 경로 또는 URL을 기록합니다. 플러그인이 목록에 없으면 설치되지 않은 상태이며, 제거 정리만 필요한 경우에만 4단계로 건너뜁니다.

### 2. 최신 마켓플레이스 메타데이터 가져오기

마켓플레이스 항목은 메타데이터를 캐시합니다. 새로고침해야 새 버전이 인식됩니다.

```bash
claude plugin marketplace update project-init
```

소스가 로컬 디렉터리인 경우, 메인테이너가 이미 새 버전의 커밋과 태그(`vX.Y.Z`)를 해당 디렉터리에 반영해 두었어야 합니다.

### 3. 새 버전으로 재설치

```bash
claude plugin install project-init
claude plugin list | grep project-init
```

보고된 버전이 이제 새 릴리스 버전과 일치해야 합니다. 게시된 `CHANGELOG.md`의 버전 항목과 비교하여 확인합니다.

### 4. 플러그인 제거(제거 경로)

업데이트가 아니라 제거가 목적이라면:

```bash
claude plugin uninstall project-init
claude plugin marketplace remove project-init
claude plugin list | grep project-init
```

마지막 명령은 결과를 반환하지 않아야 합니다. 선택적으로 남은 프로젝트 수준 흔적을 제거합니다:

```bash
ls .claude/settings.local.json 2>/dev/null
ls .claude/hooks/ 2>/dev/null
```

이 파일들은 플러그인이 아니라 소비자 프로젝트에 속하며 uninstall로 제거되지 않습니다. 훅이나 로컬 권한이 더 이상 필요하지 않을 때만 편집합니다.

## 검증

- [ ] `claude plugin list`가 예상한 버전을 보고합니다(제거 시에는 항목이 없어야 함).
- [ ] 이전에 설치된 슬래시 명령(예: `/health-check`)이 새 버전의 동작을 실행하거나, 제거 시 "command not found"로 실패합니다.
- [ ] `claude plugin marketplace list` 출력에 이전 버전을 가리키는 잔존 참조가 없습니다.

## 롤백

새 버전에 문제가 있어 이전 버전으로 다운그레이드해야 한다면:

```bash
claude plugin uninstall project-init
git -C <마켓플레이스-소스-경로> checkout v<이전-버전>
claude plugin marketplace update project-init
claude plugin install project-init
claude plugin list | grep project-init
```

업스트림 이슈가 수정된 후 마켓플레이스 소스를 최신 태그로 복원합니다:

```bash
git -C <마켓플레이스-소스-경로> checkout main
claude plugin marketplace update project-init
```

## 참고
- 최종 검증일: 2026-05-05
- `marketplace add`에 사용된 마켓플레이스 소스 경로는 Claude Code가 기록하며 `update`로 바뀌지 않습니다. 소스를 전환하려면(예: 로컬 디렉터리에서 원격 git URL로) `marketplace remove` 후 새 소스로 다시 추가합니다.
- 프로젝트 로컬 파일(`.claude/settings.local.json`, `.claude/hooks/`, 생성된 `CLAUDE.md` 파일)은 플러그인이 아니라 소비자 프로젝트가 소유하며 uninstall 후에도 남습니다.
