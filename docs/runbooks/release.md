# Runbook: Release a New Version

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Overview
Release a new version of the project-init plugin to the marketplace. The procedure bumps the version everywhere it appears (`plugin.json`, `metadata.version` and `plugins[0].version` in `marketplace.json`, the README version badge and structure-tree `(vX.Y.Z)` labels in both languages, and a new `CHANGELOG.md` release in both language sections), creates an annotated git tag, and verifies the release through a clean install. `tests/structure/test-plugin-structure.sh` fails when any of these differ from `plugin.json`, and this repository's SessionStart hook reports the drift.

## When to Use
- After user-facing changes land on `main` (new commands, command signature changes, hook behavior changes).
- After a batch of bug fixes that warrants a patch release.
- After a security fix that must reach users.

## Prerequisites
- Working tree on `main` is clean (`git status` empty).
- Local `main` is up to date with the remote (`git pull --ff-only` succeeds).
- All tests pass (`bash tests/run-all.sh`).
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

Update both manifest files and the README version strings; Step 5 commits them together with the CHANGELOG. Replace `X.Y.Z` with the chosen version.

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

python3 -c "
import re
p = 'README.md'
s = open(p, encoding='utf-8').read()
s = re.sub(r'badge/version-\d+\.\d+\.\d+-', 'badge/version-$NEW_VERSION-', s)
s = re.sub(r'\(v\d+\.\d+\.\d+\)', '(v$NEW_VERSION)', s)
open(p, 'w', encoding='utf-8').write(s)
"

git diff .claude-plugin/marketplace.json plugins/project-init/.claude-plugin/plugin.json README.md
```

The diff must show only version strings. The structure tests run at the end of Step 4, because they also compare the latest CHANGELOG release with `plugin.json` and fail until Step 4 is done.

In a Claude Code session in this repository, the Stop hook (`.claude/hooks/test-gate.sh`) runs the full suite when a turn ends on a tree that changed since its last run, so a turn that ends between Step 3 and Step 4 comes back once with the version-sync failures. Do Steps 3 and 4 in one turn.

### 4. Update CHANGELOG

Run the `/generate-changelog` slash command from inside Claude Code, or update `CHANGELOG.md` manually. Either way, the result must satisfy:

- Both English and Korean sections contain a new heading `## [X.Y.Z] - YYYY-MM-DD`.
- The new entry lists every user-facing change since the previous version.
- The `[Unreleased]` section above the new entry is empty, and its heading stays in both language sections.

Use `git log v<previous>..HEAD --oneline` to enumerate the changes that should appear. Then run the structure tests:

```bash
bash tests/run-all.sh structure
```

They check that `plugin.json`, both `marketplace.json` fields, the README badge and `(vX.Y.Z)` labels, and the latest CHANGELOG release in both languages carry the same version. A failure names the file that was missed; fix it before continuing.

### 5. Commit and Tag

```bash
git add .claude-plugin/marketplace.json \
        plugins/project-init/.claude-plugin/plugin.json \
        README.md \
        CHANGELOG.md
git commit -m "Release vX.Y.Z"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
git push origin main
git push origin "vX.Y.Z"
```

### 6. Marketplace Verification

Verify the release installs cleanly from a fresh location. Run the block from the repository checkout: `REPO` records that path before the `cd`.

```bash
REPO=$(git rev-parse --show-toplevel)
D=$(mktemp -d) && cd "$D"
claude plugin marketplace add "$REPO"
claude plugin install project-init@project-init
claude plugin list | grep project-init
```

The version reported by `claude plugin list` must equal `X.Y.Z`.

## Verification

- [ ] `bash tests/run-all.sh` reports zero failures.
- [ ] Both manifest files report version `X.Y.Z` (`metadata.version` and `plugins[0].version` in `marketplace.json`).
- [ ] The README version badge and every structure-tree `(vX.Y.Z)` label show `X.Y.Z`.
- [ ] `CHANGELOG.md` contains the `[X.Y.Z]` entry in both English and Korean sections.
- [ ] The annotated tag `vX.Y.Z` exists on `main` and is pushed to the remote.
- [ ] `claude plugin install project-init@project-init` from a clean directory installs version `X.Y.Z`.
- [ ] `/health-check` runs without errors against the installed plugin.

## Rollback

If a regression is found before the tag is pushed, run these in your own terminal; this repository's `.claude/settings.json` denies `git reset --hard` to Claude:

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
- Last verified: 2026-05-05 (procedure changed since; not yet run)
- The structure test `tests/structure/test-plugin-structure.sh` validates version synchronization across the manifests, the README badge and tree labels, and the CHANGELOG. Step 4 deliberately runs only that subset because a mismatch must halt the release before the commit.
- The `commit-msg` hook strips `Co-Authored-By` lines automatically; do not add them manually.

---

<a id="korean"></a>

# 한국어

## 개요
project-init 플러그인의 새 버전을 마켓플레이스에 릴리스합니다. 절차는 버전이 나타나는 모든 곳(`plugin.json`, `marketplace.json`의 `metadata.version`과 `plugins[0].version`, 양 언어 README의 버전 배지와 구조 트리 `(vX.Y.Z)` 라벨, `CHANGELOG.md` 영어·한국어 섹션의 새 릴리스)을 갱신하고, 어노테이션 git 태그를 생성하며, 깨끗한 설치를 통해 릴리스를 검증합니다. 이 중 하나라도 `plugin.json`과 다르면 `tests/structure/test-plugin-structure.sh`가 실패하고, 이 저장소의 SessionStart 훅이 드리프트를 보고합니다.

## 사용 시점
- 사용자 대면 변경(새 명령, 명령 시그니처 변경, 훅 동작 변경)이 `main`에 반영된 후.
- 패치 릴리스가 필요한 버그 수정이 누적된 후.
- 사용자에게 도달해야 하는 보안 수정 후.

## 사전 요구 사항
- 작업 트리가 `main`에서 깨끗합니다(`git status`가 비어 있음).
- 로컬 `main`이 원격과 동기화되어 있습니다(`git pull --ff-only` 성공).
- 테스트 전체 통과(`bash tests/run-all.sh`).
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

두 매니페스트 파일과 README의 버전 문자열을 갱신합니다. 5단계에서 CHANGELOG와 함께 한 번에 커밋합니다. `X.Y.Z`를 선택한 버전으로 치환합니다.

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

python3 -c "
import re
p = 'README.md'
s = open(p, encoding='utf-8').read()
s = re.sub(r'badge/version-\d+\.\d+\.\d+-', 'badge/version-$NEW_VERSION-', s)
s = re.sub(r'\(v\d+\.\d+\.\d+\)', '(v$NEW_VERSION)', s)
open(p, 'w', encoding='utf-8').write(s)
"

git diff .claude-plugin/marketplace.json plugins/project-init/.claude-plugin/plugin.json README.md
```

diff에는 버전 문자열만 나타나야 합니다. 구조 테스트는 최신 CHANGELOG 릴리스도 `plugin.json`과 비교해 4단계를 마치기 전까지 실패하므로, 4단계 끝에서 실행합니다.

이 저장소의 Claude Code 세션에서는 Stop 훅(`.claude/hooks/test-gate.sh`)이 마지막 실행 이후 바뀐 트리에서 턴이 끝나면 전체 스위트를 실행합니다. 따라서 3단계와 4단계 사이에 턴이 끝나면 버전 동기화 실패와 함께 한 번 되돌아옵니다. 3단계와 4단계는 한 턴에 진행합니다.

### 4. CHANGELOG 갱신

Claude Code 안에서 `/generate-changelog` 슬래시 명령을 실행하거나, `CHANGELOG.md`를 수동으로 갱신합니다. 어느 쪽이든 결과는 다음을 만족해야 합니다:

- 영어와 한국어 섹션 모두에 새 헤딩 `## [X.Y.Z] - YYYY-MM-DD`이 존재합니다.
- 새 항목이 이전 버전 이후의 모든 사용자 대면 변경을 나열합니다.
- 새 항목 위의 `[Unreleased]` 섹션은 비어 있고, 그 헤딩은 두 언어 섹션 모두에 남아 있습니다.

`git log v<이전>..HEAD --oneline`으로 포함될 변경을 열거합니다. 그런 다음 구조 테스트를 실행합니다:

```bash
bash tests/run-all.sh structure
```

`plugin.json`, `marketplace.json`의 두 필드, README 배지와 `(vX.Y.Z)` 라벨, 양 언어 CHANGELOG의 최신 릴리스가 같은 버전인지 검사합니다. 실패하면 빠뜨린 파일이 표시되므로, 계속하기 전에 수정합니다.

### 5. 커밋과 태그

```bash
git add .claude-plugin/marketplace.json \
        plugins/project-init/.claude-plugin/plugin.json \
        README.md \
        CHANGELOG.md
git commit -m "Release vX.Y.Z"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
git push origin main
git push origin "vX.Y.Z"
```

### 6. 마켓플레이스 검증

새 위치에서 릴리스가 깨끗하게 설치되는지 검증합니다. 이 블록은 저장소 체크아웃에서 실행합니다. `REPO`가 `cd` 전에 그 경로를 기록합니다.

```bash
REPO=$(git rev-parse --show-toplevel)
D=$(mktemp -d) && cd "$D"
claude plugin marketplace add "$REPO"
claude plugin install project-init@project-init
claude plugin list | grep project-init
```

`claude plugin list`가 보고하는 버전은 `X.Y.Z`와 일치해야 합니다.

## 검증

- [ ] `bash tests/run-all.sh`가 실패 0건을 보고합니다.
- [ ] 두 매니페스트 파일이 모두 `X.Y.Z` 버전을 보고합니다(`marketplace.json`의 `metadata.version`과 `plugins[0].version` 포함).
- [ ] README 버전 배지와 모든 구조 트리 `(vX.Y.Z)` 라벨이 `X.Y.Z`를 표시합니다.
- [ ] `CHANGELOG.md`의 영어와 한국어 섹션 모두에 `[X.Y.Z]` 항목이 존재합니다.
- [ ] 어노테이션 태그 `vX.Y.Z`가 `main`에 존재하고 원격에 푸시되었습니다.
- [ ] 깨끗한 디렉터리에서 `claude plugin install project-init@project-init`이 `X.Y.Z` 버전을 설치합니다.
- [ ] 설치된 플러그인에 대해 `/health-check`가 오류 없이 실행됩니다.

## 롤백

태그 푸시 전에 회귀가 발견되면 직접 터미널에서 실행합니다. 이 저장소의 `.claude/settings.json`은 Claude에게 `git reset --hard`를 허용하지 않습니다:

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
- 최종 검증일: 2026-05-05 (이후 절차가 바뀌었으며 아직 실행하지 않음)
- 구조 테스트 `tests/structure/test-plugin-structure.sh`가 매니페스트, README 배지와 트리 라벨, CHANGELOG 사이의 버전 동기화를 검증합니다. 4단계는 의도적으로 이 부분 집합만 실행하는데, 불일치가 발견되면 커밋 전에 릴리스를 중단해야 하기 때문입니다.
- `commit-msg` 훅이 `Co-Authored-By` 라인을 자동 제거하므로 수동으로 추가하지 않습니다.
