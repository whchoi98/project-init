# Runbook: Release a New Version

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Overview
Release a new version of the project-init plugin to the marketplace. The procedure synchronizes versions in both manifest files (`marketplace.json` and `plugin.json`), updates `CHANGELOG.md` in both language sections, creates an annotated git tag, and verifies the release through a clean install.

## When to Use
- After user-facing changes land on `main` (new commands, command signature changes, hook behavior changes).
- After a batch of bug fixes that warrants a patch release.
- After a security fix that must reach users.

## Prerequisites
- Working tree on `main` is clean (`git status` empty).
- Local `main` is up to date with the remote (`git pull --ff-only` succeeds).
- All 114 tests pass (`bash tests/run-all.sh`).
- Semantic version classification (major / minor / patch) decided based on the change set.

## Procedure

### 1. Pre-flight Verification

```bash
git status
git branch --show-current
git pull --ff-only
bash tests/run-all.sh
```

Stop if any step reports an error or test failure. The release procedure assumes a clean baseline.

### 2. Determine Current and New Version

```bash
python3 -c "import json; print('marketplace:', json.load(open('.claude-plugin/marketplace.json'))['metadata']['version'])"
python3 -c "import json; print('plugin:', json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])"
```

The two versions must already match. If they do not, stop -- the project is in an inconsistent state and must be repaired before a release.

Apply semantic versioning:

| Change type | Bump |
|-------------|------|
| Breaking change (command removed, manifest schema changed, hook contract changed) | MAJOR |
| New feature (new command, new hook, new agent) | MINOR |
| Bug fix, documentation, internal refactor | PATCH |

Choose the new version `X.Y.Z` accordingly.

### 3. Atomic Version Bump

Update both manifest files in a single commit. Replace `X.Y.Z` with the chosen version.

```bash
NEW_VERSION="X.Y.Z"

python3 -c "
import json
p = '.claude-plugin/marketplace.json'
d = json.load(open(p))
d['metadata']['version'] = '$NEW_VERSION'
d['plugins'][0]['version'] = '$NEW_VERSION'
with open(p, 'w') as f: json.dump(d, f, indent=2); f.write('\n')
"

python3 -c "
import json
p = 'plugins/project-init/.claude-plugin/plugin.json'
d = json.load(open(p))
d['version'] = '$NEW_VERSION'
with open(p, 'w') as f: json.dump(d, f, indent=2); f.write('\n')
"

git diff .claude-plugin/marketplace.json plugins/project-init/.claude-plugin/plugin.json
bash tests/run-all.sh structure
```

The structure tests verify that both manifest versions match. A failure here means the bump was not atomic; investigate before continuing.

### 4. Update CHANGELOG

Run the `/generate-changelog` slash command from inside Claude Code, or update `CHANGELOG.md` manually. Either way, the result must satisfy:

- Both English and Korean sections contain a new heading `## [X.Y.Z] - YYYY-MM-DD`.
- The new entry lists every user-facing change since the previous version.
- The `[Unreleased]` section above the new entry is empty or removed.

Use `git log v<previous>..HEAD --oneline` to enumerate the changes that should appear.

### 5. Commit and Tag

```bash
git add .claude-plugin/marketplace.json \
        plugins/project-init/.claude-plugin/plugin.json \
        CHANGELOG.md
git commit -m "Release vX.Y.Z"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
git push origin main
git push origin "vX.Y.Z"
```

### 6. Marketplace Verification

Verify the release installs cleanly from a fresh location.

```bash
cd /tmp && rm -rf release-verify && mkdir release-verify && cd release-verify
claude plugin marketplace add /home/ec2-user/my-project/project-init
claude plugin install project-init
claude plugin list | grep project-init
```

The version reported by `claude plugin list` must equal `X.Y.Z`.

## Verification

- [ ] `bash tests/run-all.sh` reports 114/114 passed.
- [ ] Both manifest files report version `X.Y.Z`.
- [ ] `CHANGELOG.md` contains the `[X.Y.Z]` entry in both English and Korean sections.
- [ ] The annotated tag `vX.Y.Z` exists on `main` and is pushed to the remote.
- [ ] `claude plugin install project-init` from a clean directory installs version `X.Y.Z`.
- [ ] `/health-check` runs without errors against the installed plugin.

## Rollback

If a regression is found before the tag is pushed:

```bash
git reset --hard HEAD~1
git tag -d "vX.Y.Z"
```

If the tag and commit have already been pushed, revert rather than force-push:

```bash
git revert HEAD
git push origin main
git tag -d "vX.Y.Z"
git push origin :refs/tags/vX.Y.Z
```

Then issue a new patch version `X.Y.(Z+1)` containing the fix and follow this runbook from Step 1.

## Notes
- Last verified: 2026-05-05
- The structure test `tests/structure/test-plugin-structure.sh` validates manifest version synchronization. Step 3 deliberately runs only that subset because a mismatch must halt the release before any further work.
- The `commit-msg` hook strips `Co-Authored-By` lines automatically; do not add them manually.

---

<a id="korean"></a>

# 한국어

## 개요
project-init 플러그인의 새 버전을 마켓플레이스에 릴리스합니다. 절차는 두 매니페스트 파일(`marketplace.json`, `plugin.json`)의 버전을 동기화하고, `CHANGELOG.md`의 영어와 한국어 섹션을 모두 갱신하며, 어노테이션 git 태그를 생성하고, 깨끗한 설치를 통해 릴리스를 검증합니다.

## 사용 시점
- 사용자 대면 변경(새 명령, 명령 시그니처 변경, 훅 동작 변경)이 `main`에 반영된 후.
- 패치 릴리스가 필요한 버그 수정이 누적된 후.
- 사용자에게 도달해야 하는 보안 수정 후.

## 사전 요구 사항
- 작업 트리가 `main`에서 깨끗합니다(`git status`가 비어 있음).
- 로컬 `main`이 원격과 동기화되어 있습니다(`git pull --ff-only` 성공).
- 114개 테스트 전체 통과(`bash tests/run-all.sh`).
- 변경 집합에 따라 시맨틱 버전 분류(major / minor / patch)가 결정되어 있습니다.

## 절차

### 1. 사전 검증

```bash
git status
git branch --show-current
git pull --ff-only
bash tests/run-all.sh
```

어느 단계라도 오류나 테스트 실패를 보고하면 중단합니다. 릴리스 절차는 깨끗한 기준선을 전제합니다.

### 2. 현재 버전과 새 버전 결정

```bash
python3 -c "import json; print('marketplace:', json.load(open('.claude-plugin/marketplace.json'))['metadata']['version'])"
python3 -c "import json; print('plugin:', json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])"
```

두 버전은 이미 일치해야 합니다. 일치하지 않으면 중단합니다 -- 프로젝트가 비정상 상태이며 릴리스 전에 복구해야 합니다.

시맨틱 버저닝을 적용합니다:

| 변경 유형 | 증가 |
|----------|-----|
| 호환성 깨짐(명령 제거, 매니페스트 스키마 변경, 훅 계약 변경) | MAJOR |
| 신규 기능(새 명령, 새 훅, 새 에이전트) | MINOR |
| 버그 수정, 문서, 내부 리팩터 | PATCH |

이에 따라 새 버전 `X.Y.Z`를 선택합니다.

### 3. 원자적 버전 갱신

두 매니페스트 파일을 단일 커밋으로 갱신합니다. `X.Y.Z`를 선택한 버전으로 치환합니다.

```bash
NEW_VERSION="X.Y.Z"

python3 -c "
import json
p = '.claude-plugin/marketplace.json'
d = json.load(open(p))
d['metadata']['version'] = '$NEW_VERSION'
d['plugins'][0]['version'] = '$NEW_VERSION'
with open(p, 'w') as f: json.dump(d, f, indent=2); f.write('\n')
"

python3 -c "
import json
p = 'plugins/project-init/.claude-plugin/plugin.json'
d = json.load(open(p))
d['version'] = '$NEW_VERSION'
with open(p, 'w') as f: json.dump(d, f, indent=2); f.write('\n')
"

git diff .claude-plugin/marketplace.json plugins/project-init/.claude-plugin/plugin.json
bash tests/run-all.sh structure
```

구조 테스트가 두 매니페스트 버전이 일치하는지 검증합니다. 여기서 실패하면 갱신이 원자적이지 않았다는 뜻이므로, 계속하기 전에 조사합니다.

### 4. CHANGELOG 갱신

Claude Code 안에서 `/generate-changelog` 슬래시 명령을 실행하거나, `CHANGELOG.md`를 수동으로 갱신합니다. 어느 쪽이든 결과는 다음을 만족해야 합니다:

- 영어와 한국어 섹션 모두에 새 헤딩 `## [X.Y.Z] - YYYY-MM-DD`이 존재합니다.
- 새 항목이 이전 버전 이후의 모든 사용자 대면 변경을 나열합니다.
- 새 항목 위의 `[Unreleased]` 섹션은 비어 있거나 제거되어 있습니다.

`git log v<이전>..HEAD --oneline`으로 포함될 변경을 열거합니다.

### 5. 커밋과 태그

```bash
git add .claude-plugin/marketplace.json \
        plugins/project-init/.claude-plugin/plugin.json \
        CHANGELOG.md
git commit -m "Release vX.Y.Z"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
git push origin main
git push origin "vX.Y.Z"
```

### 6. 마켓플레이스 검증

새 위치에서 릴리스가 깨끗하게 설치되는지 검증합니다.

```bash
cd /tmp && rm -rf release-verify && mkdir release-verify && cd release-verify
claude plugin marketplace add /home/ec2-user/my-project/project-init
claude plugin install project-init
claude plugin list | grep project-init
```

`claude plugin list`가 보고하는 버전은 `X.Y.Z`와 일치해야 합니다.

## 검증

- [ ] `bash tests/run-all.sh`가 114/114 통과를 보고합니다.
- [ ] 두 매니페스트 파일이 모두 `X.Y.Z` 버전을 보고합니다.
- [ ] `CHANGELOG.md`의 영어와 한국어 섹션 모두에 `[X.Y.Z]` 항목이 존재합니다.
- [ ] 어노테이션 태그 `vX.Y.Z`가 `main`에 존재하고 원격에 푸시되었습니다.
- [ ] 깨끗한 디렉터리에서 `claude plugin install project-init`이 `X.Y.Z` 버전을 설치합니다.
- [ ] 설치된 플러그인에 대해 `/health-check`가 오류 없이 실행됩니다.

## 롤백

태그 푸시 전에 회귀가 발견되면:

```bash
git reset --hard HEAD~1
git tag -d "vX.Y.Z"
```

태그와 커밋이 이미 푸시된 경우, 강제 푸시 대신 revert를 사용합니다:

```bash
git revert HEAD
git push origin main
git tag -d "vX.Y.Z"
git push origin :refs/tags/vX.Y.Z
```

이후 수정을 포함한 새 패치 버전 `X.Y.(Z+1)`를 발행하고 이 런북을 1단계부터 다시 따릅니다.

## 참고
- 최종 검증일: 2026-05-05
- 구조 테스트 `tests/structure/test-plugin-structure.sh`가 매니페스트 버전 동기화를 검증합니다. 3단계는 의도적으로 이 부분 집합만 실행하는데, 불일치가 발견되면 추가 작업 전에 릴리스를 중단해야 하기 때문입니다.
- `commit-msg` 훅이 `Co-Authored-By` 라인을 자동 제거하므로 수동으로 추가하지 않습니다.
