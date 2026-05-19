# Implementation Reference Docs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 8 layer-specific implementation reference doc skeletons to the `project-init` plugin, generated via hybrid detection + user confirmation from `/init-project`, with `/add-reference-doc` for incremental additions and `/sync-docs` for drift detection.

**Architecture:** Three commands cooperate over `docs/reference/` and an AUTO-MANAGED INDEX. The plugin's primitive is a single template file (`reference-doc-template.md`) with 8 fenced layer skeletons that all commands extract from. Tests are structural bash assertions over the markdown command files.

**Tech Stack:** Markdown (plugin commands/templates), bash (test runner using existing `assert_*` helpers), JSON manifests (plugin.json, marketplace.json).

**Spec:** `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`

---

## File Structure

**New files (9):**
- `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md` — 8-layer skeleton library
- `plugins/project-init/commands/add-reference-doc.md` — new command
- `docs/decisions/ADR-005-implementation-reference-docs.md`
- `docs/decisions/ADR-006-hybrid-detection-confirmation.md`
- `tests/structure/test-reference-docs.sh` — covers all reference-doc structural tests

**Modified files (10):**
- `plugins/project-init/commands/init-project.md` — Step 4.5 insertion
- `plugins/project-init/commands/sync-docs.md` — Phase 1 reference block
- `plugins/project-init/agents/doc-sync-checker.md` — reference validation
- `plugins/project-init/CLAUDE.md` — Key Files list
- `CLAUDE.md` (root) — Auto-Sync Rules + ADR index
- `plugins/project-init/.claude-plugin/plugin.json` — version bump
- `.claude-plugin/marketplace.json` — version bump
- `CHANGELOG.md` — 2.1.0 entry
- `README.md` — document new command + reference docs
- `tests/run-all.sh` — no change (auto-discovery)

---

## Conventions

- Test runner auto-discovers `test-*.sh` (hyphenated) under `tests/`. Existing `assert_*` helpers (`assert_file_exists`, `assert_contains`, `assert_grep_match`, etc.) are in scope when sourced by `run-all.sh`.
- Plugin commands are markdown files with YAML frontmatter; their "logic" is instructions Claude follows. Tests verify the markdown contains required keywords/sections/markers.
- TDD ordering: each task that adds behavior is preceded by a test extension that fails first.
- Commit after each green task. Commit messages match the existing style (imperative, ≤72 char subject).

---

## Task 1: Bootstrap failing test file for reference-doc-template

**Files:**
- Create: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Create the test file with first failing assertions**

Write `tests/structure/test-reference-docs.sh`:

```bash
#!/bin/bash
# Tests for the 8-layer implementation reference docs feature.
# Validates plugin template, new command file, init-project Step 4.5,
# sync-docs reference block, and doc-sync-checker reference validation.

# --- Reference doc template exists and has all 8 layers ---

TEMPLATE="plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md"

assert_file_exists "reference-doc-template.md exists" "$TEMPLATE"

if [ -f "$TEMPLATE" ]; then
    TEMPLATE_CONTENT=$(cat "$TEMPLATE")
    for layer in infrastructure data api iac frontend ui security agent-llm; do
        assert_contains "Template defines layer: $layer" "$TEMPLATE_CONTENT" "## Layer: $layer"
    done
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run-all.sh reference-docs`
Expected: FAIL with "reference-doc-template.md exists" assertion (template not yet created).

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: add failing structural tests for reference-doc-template"
```

---

## Task 2: Create reference-doc-template.md with 8 layer skeletons

**Files:**
- Create: `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md`

- [ ] **Step 1: Write the template file**

Create `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md` with this exact structure (one section per layer; bodies follow the same 5-section bilingual skeleton):

````markdown
# Reference Doc Template Library

Each fenced block below is extracted by `/init-project`, `/add-reference-doc`,
and used to generate `docs/reference/{layer}.md`. The placeholders
`{{LAYER_TITLE_EN}}`, `{{LAYER_TITLE_KO}}`, `{{COMPONENTS_TABLE}}`,
`{{CODE_POINTERS_AUTO}}`, and `{{LAST_UPDATED}}` are substituted by the
caller.

## Layer: infrastructure

```markdown
# Infrastructure / 인프라 구현 상세

[![English](https://img.shields.io/badge/Language-English-blue)](#english)
[![한국어](https://img.shields.io/badge/Language-한국어-red)](#korean)

<a id="english"></a>
## English

### 1. Overview
<!-- 1-3 sentences on what the infrastructure layer does and why it exists. -->

### 2. Components
| Component | Path | Purpose |
|---|---|---|
{{COMPONENTS_TABLE}}

### 3. Key Decisions
<!-- TODO: list 3-5 decisions or link to docs/decisions/ADR-*.md -->

### 4. Code Pointers
<!-- TODO: 3-7 entries; paths must be valid (checked by /sync-docs) -->
{{CODE_POINTERS_AUTO}}

### 5. Cross-references
<!-- TODO -->
- Related modules:
- Related ADRs:
- Related runbooks:

<a id="korean"></a>
## 한국어

### 1. 개요
<!-- 인프라 계층이 무엇을 하는지, 왜 존재하는지 1-3 문장으로. -->

### 2. 구성요소
| 구성요소 | 경로 | 목적 |
|---|---|---|
{{COMPONENTS_TABLE}}

### 3. 주요 결정
<!-- TODO: 3-5개 결정 나열 또는 docs/decisions/ADR-*.md 링크 -->

### 4. 코드 포인터
<!-- TODO: 3-7개 항목; 경로는 실재해야 함 (/sync-docs가 점검) -->
{{CODE_POINTERS_AUTO}}

### 5. 상호 참조
<!-- TODO -->
- 관련 모듈:
- 관련 ADR:
- 관련 런북:
```

## Layer: data
(repeat the same skeleton with "Data / 데이터 구성 상세" titles)

## Layer: api
(repeat with "API / API 구성 상세")

## Layer: iac
(repeat with "Infrastructure as Code / IaC 구현 상세")

## Layer: frontend
(repeat with "Frontend / Frontend 구현 상세")

## Layer: ui
(repeat with "UI / UI 구현 상세")

## Layer: security
(repeat with "Security / 보안 구현 상세")

## Layer: agent-llm
(repeat with "Agent · LLM / Agent · LLM 구현 상세")
```

**Important:** The "(repeat ...)" lines above are shorthand for this plan only. In the actual file, each of the 8 layer sections must contain the full fenced skeleton — copy the infrastructure block and change only the H1 line and the Korean H1 to the matching layer title. Do not abbreviate.

- [ ] **Step 2: Run the test to verify it now passes**

Run: `bash tests/run-all.sh reference-docs`
Expected: All 9 assertions pass (template exists + 8 layer sections).

- [ ] **Step 3: Commit**

```bash
git add plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md
git commit -m "feat: add 8-layer reference doc template library"
```

---

## Task 3: Extend tests for skeleton structural requirements

**Files:**
- Modify: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Append skeleton-structure assertions**

Append to `tests/structure/test-reference-docs.sh`:

```bash
# --- Each layer skeleton contains 5 required sections + bilingual anchors ---

if [ -f "$TEMPLATE" ]; then
    REQUIRED_SECTIONS=("### 1. Overview" "### 2. Components" "### 3. Key Decisions" "### 4. Code Pointers" "### 5. Cross-references")
    KOREAN_SECTIONS=("### 1. 개요" "### 2. 구성요소" "### 3. 주요 결정" "### 4. 코드 포인터" "### 5. 상호 참조")
    for section in "${REQUIRED_SECTIONS[@]}"; do
        COUNT=$(grep -c "^$section\$" "$TEMPLATE" || echo 0)
        if [ "$COUNT" -ge 8 ]; then
            pass "Template: section '$section' appears in all 8 layers"
        else
            fail "Template: section '$section'" "found $COUNT occurrences, expected ≥8"
        fi
    done
    for section in "${KOREAN_SECTIONS[@]}"; do
        COUNT=$(grep -c "^$section\$" "$TEMPLATE" || echo 0)
        if [ "$COUNT" -ge 8 ]; then
            pass "Template: Korean section '$section' appears in all 8 layers"
        else
            fail "Template: Korean section '$section'" "found $COUNT occurrences, expected ≥8"
        fi
    done

    # Bilingual anchors per layer
    ANCHOR_EN=$(grep -c '<a id="english"></a>' "$TEMPLATE" || echo 0)
    ANCHOR_KO=$(grep -c '<a id="korean"></a>' "$TEMPLATE" || echo 0)
    if [ "$ANCHOR_EN" -ge 8 ]; then pass "Template: 8 English anchors"; else fail "Template: English anchors" "got $ANCHOR_EN, expected ≥8"; fi
    if [ "$ANCHOR_KO" -ge 8 ]; then pass "Template: 8 Korean anchors"; else fail "Template: Korean anchors" "got $ANCHOR_KO, expected ≥8"; fi

    # Variables present somewhere in the file
    for var in '{{COMPONENTS_TABLE}}' '{{CODE_POINTERS_AUTO}}'; do
        if grep -qF "$var" "$TEMPLATE"; then
            pass "Template: variable $var present"
        else
            fail "Template: variable $var" "not found"
        fi
    done
fi
```

- [ ] **Step 2: Run the test**

Run: `bash tests/run-all.sh reference-docs`
Expected: All assertions pass (since template was written correctly in Task 2). If any section count is below 8, return to Task 2 and complete the missing layer sections.

- [ ] **Step 3: Commit**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: assert 5-section bilingual skeleton across all 8 layers"
```

---

## Task 4: Add failing test for /add-reference-doc command

**Files:**
- Modify: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Append /add-reference-doc command assertions**

Append to `tests/structure/test-reference-docs.sh`:

```bash
# --- /add-reference-doc command file ---

ADD_CMD="plugins/project-init/commands/add-reference-doc.md"

assert_file_exists "add-reference-doc.md exists" "$ADD_CMD"

if [ -f "$ADD_CMD" ]; then
    ADD_CMD_CONTENT=$(cat "$ADD_CMD")
    assert_contains "add-reference-doc: has YAML frontmatter" "$ADD_CMD_CONTENT" "---"
    assert_contains "add-reference-doc: has description" "$ADD_CMD_CONTENT" "description:"
    assert_contains "add-reference-doc: has argument-hint" "$ADD_CMD_CONTENT" "argument-hint:"
    assert_contains "add-reference-doc: lists allowed-tools" "$ADD_CMD_CONTENT" "allowed-tools:"
    assert_contains "add-reference-doc: validates layer enum" "$ADD_CMD_CONTENT" "infrastructure"
    assert_contains "add-reference-doc: validates layer enum" "$ADD_CMD_CONTENT" "agent-llm"
    assert_contains "add-reference-doc: references template" "$ADD_CMD_CONTENT" "reference-doc-template.md"
    assert_contains "add-reference-doc: writes to docs/reference/" "$ADD_CMD_CONTENT" "docs/reference/"
    assert_contains "add-reference-doc: handles conflict" "$ADD_CMD_CONTENT" "overwrite"
    assert_contains "add-reference-doc: updates INDEX.md" "$ADD_CMD_CONTENT" "INDEX.md"
    assert_contains "add-reference-doc: updates root CLAUDE.md" "$ADD_CMD_CONTENT" "AUTO-MANAGED:references"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run-all.sh reference-docs`
Expected: FAIL with "add-reference-doc.md exists" + dependent assertions.

- [ ] **Step 3: Commit**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: add failing tests for /add-reference-doc command"
```

---

## Task 5: Create /add-reference-doc command

**Files:**
- Create: `plugins/project-init/commands/add-reference-doc.md`

- [ ] **Step 1: Write the command file**

Create `plugins/project-init/commands/add-reference-doc.md`:

````markdown
---
description: Add an implementation reference doc skeleton for one or more layers under docs/reference/
allowed-tools: Read, Write, Edit, Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(git config:*), Bash(date:*), Glob
argument-hint: One or more layer names — infrastructure, data, api, iac, frontend, ui, security, agent-llm
---

# Add Implementation Reference Doc

Append a skeleton implementation reference document for the given layer(s) under `docs/reference/`.

## Step 1: Validate Layer Names

Target layers: $ARGUMENTS

Valid layers (enum):
- `infrastructure`
- `data`
- `api`
- `iac`
- `frontend`
- `ui`
- `security`
- `agent-llm`

If any argument is not in the enum, abort with: `Unknown layer "<name>". Valid: infrastructure, data, api, iac, frontend, ui, security, agent-llm`.

## Step 2: Ensure Target Directory

```bash
mkdir -p docs/reference
```

## Step 3: For Each Layer — Generate Skeleton

For every requested layer:

1. **Check existence** at `docs/reference/{layer}.md`:
   - If exists: prompt the user `(o)verwrite / (s)kip / (a)bort`. On `s` skip this layer; on `a` abort the whole command.
2. **Extract skeleton** from `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md` — read the fenced block under `## Layer: {layer}`.
3. **Substitute variables**:
   - `{{COMPONENTS_TABLE}}` → empty table row `| <!-- TODO: component --> | <!-- path --> | <!-- purpose --> |`
   - `{{CODE_POINTERS_AUTO}}` → `<!-- TODO: add 3-7 code pointers -->`
4. **Write** to `docs/reference/{layer}.md`.

## Step 4: Regenerate `docs/reference/INDEX.md`

Read the current directory listing of `docs/reference/*.md` (excluding INDEX.md itself).
Rewrite the file with this structure:

```markdown
# Implementation Reference Index / 구현 참조 인덱스

[![English](https://img.shields.io/badge/Language-English-blue)](#english)
[![한국어](https://img.shields.io/badge/Language-한국어-red)](#korean)

<a id="english"></a>
## English

Layer-by-layer implementation guides. Each file follows the same 5-section
structure (Overview / Components / Key Decisions / Code Pointers / Cross-references).

<!-- AUTO-MANAGED:index -->
| Layer | File | Status |
|---|---|---|
| Infrastructure | [infrastructure.md](infrastructure.md) | present |
| Data | — | not applicable |
| API | — | not applicable |
| IaC | — | not applicable |
| Frontend | — | not applicable |
| UI | — | not applicable |
| Security | — | not applicable |
| Agent · LLM | — | not applicable |
<!-- /AUTO-MANAGED -->

Last updated: <today's date in YYYY-MM-DD> (managed by /init-project, /add-reference-doc, /sync-docs)

<a id="korean"></a>
## 한국어
(same structure, Korean section headings)
```

The table cells reflect actual file presence. Files outside the AUTO-MANAGED region must be preserved if the file already existed.

## Step 5: Update Root CLAUDE.md AUTO-MANAGED Region

Locate the block between `<!-- AUTO-MANAGED:references -->` and `<!-- /AUTO-MANAGED -->` in the root `CLAUDE.md`. If absent, append a new `## Implementation References` section near the end:

```markdown
## Implementation References
<!-- AUTO-MANAGED:references -->
Layer-by-layer implementation guides in `docs/reference/`. See [INDEX](docs/reference/INDEX.md).
- <link line per present layer>
<!-- /AUTO-MANAGED -->
```

Rewrite the content between the markers based on the current INDEX status.

## Step 6: Report

Output a summary:
```
Added reference docs:
  ✓ docs/reference/<layer>.md  (skeleton)
  ...
Updated:
  - docs/reference/INDEX.md
  - CLAUDE.md (## Implementation References)

Next: fill in the TODO sections in each new file.
```
````

- [ ] **Step 2: Run tests to verify they pass**

Run: `bash tests/run-all.sh reference-docs`
Expected: All add-reference-doc assertions pass.

- [ ] **Step 3: Commit**

```bash
git add plugins/project-init/commands/add-reference-doc.md
git commit -m "feat: add /add-reference-doc command for incremental layer docs"
```

---

## Task 6: Add failing test for init-project Step 4.5

**Files:**
- Modify: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Append init-project Step 4.5 assertions**

Append to `tests/structure/test-reference-docs.sh`:

```bash
# --- init-project Step 4.5: Implementation Reference Detection ---

INIT_CMD="plugins/project-init/commands/init-project.md"
if [ -f "$INIT_CMD" ]; then
    INIT_CONTENT=$(cat "$INIT_CMD")
    assert_contains "init-project: has Step 4.5 (reference detection)" "$INIT_CONTENT" "Implementation Reference Detection"
    # Detection signals from spec §5.1.1
    assert_contains "init-project: detects Dockerfile (infra)" "$INIT_CONTENT" "Dockerfile"
    assert_contains "init-project: detects migrations/ (data)" "$INIT_CONTENT" "migrations/"
    assert_contains "init-project: detects routes/ (api)" "$INIT_CONTENT" "routes/"
    assert_contains "init-project: detects *.tf (iac)" "$INIT_CONTENT" "*.tf"
    assert_contains "init-project: detects react/vue/svelte (frontend)" "$INIT_CONTENT" "react"
    assert_contains "init-project: detects components/ (ui)" "$INIT_CONTENT" "components/"
    assert_contains "init-project: detects .env.example (security)" "$INIT_CONTENT" ".env.example"
    assert_contains "init-project: detects prompts/ (agent-llm)" "$INIT_CONTENT" "prompts/"
    assert_contains "init-project: invokes /add-reference-doc logic" "$INIT_CONTENT" "reference-doc-template.md"
    assert_contains "init-project: writes INDEX.md" "$INIT_CONTENT" "docs/reference/INDEX.md"
    assert_contains "init-project: skip-on-exist policy" "$INIT_CONTENT" "existing, kept"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run-all.sh reference-docs`
Expected: FAIL on the new assertions (init-project not yet modified).

- [ ] **Step 3: Commit**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: add failing assertions for init-project Step 4.5"
```

---

## Task 7: Modify init-project.md — insert Step 4.5

**Files:**
- Modify: `plugins/project-init/commands/init-project.md`

- [ ] **Step 1: Read current init-project.md to locate insertion point**

Run: `grep -n "^## Step" plugins/project-init/commands/init-project.md`
Confirm Step 4 (directory structure) ends before Step 5 (file generation). Plan to insert "Step 4.5" between them.

- [ ] **Step 2: Insert Step 4.5 block**

Edit `plugins/project-init/commands/init-project.md`. Immediately after the Step 4 block ends and before the next `## Step 5` heading, insert:

````markdown
## Step 4.5: Implementation Reference Detection

Before generating files, detect which implementation layers apply to this
project and produce skeletons under `docs/reference/`. This runs the same
logic as `/add-reference-doc`, applied to a detected layer set the user
confirms.

### 4.5.a Detection signal matrix

| Layer | Detect when ANY present |
|---|---|
| infrastructure | `Dockerfile`, `docker-compose.yml`, `compose.yaml`, `k8s/`, `helm/` |
| data | `migrations/`, `prisma/`, `schema.sql`, `*.prisma`, `models/`, `entities/`, `db/` |
| api | `routes/`, `controllers/`, `api/`, `openapi.yaml`, `*.proto`, `swagger.json` |
| iac | `*.tf`, `cdk.json`, `template.yaml`, `serverless.yml`, `terragrunt.hcl` |
| frontend | `package.json` deps with react/vue/svelte/next/nuxt/angular, `index.html`, `vite.config.*` |
| ui | (frontend detected) AND any of `components/`, `styles/`, `tailwind.config.*`, `*.css`/`*.scss` |
| security | `.env.example`, `auth/`, `middleware/`, `permissions/`, `iam/`, `policies/` — **always pre-checked** |
| agent-llm | `prompts/`, package deps with anthropic/openai/langchain/bedrock |

### 4.5.b Confirmation prompt

Print detection results and ask the user to confirm or edit:

```
Detected implementation layers:
  ✓ Infrastructure (Dockerfile)
  ✓ API (routes/)
  ✓ Security (.env.example) — auto-recommended
  ─ Data — not detected
  ...

Proceed with detected set, or adjust? (a)ccept / (e)dit
```

On `(e)dit`, present a multi-select prompt with each layer pre-checked per
detection, allowing toggle. Empty projects (zero detections) show all layers
unchecked except Security, plus the note: *"More layers can be added later
with /add-reference-doc <layer>."*

### 4.5.c Generation

For each selected layer:
- Extract its skeleton from
  `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md`
  (fenced block under `## Layer: {layer}`)
- Substitute variables: `{{COMPONENTS_TABLE}}` rows from detected paths;
  `{{CODE_POINTERS_AUTO}}` from top 1-3 detected files
- Write to `docs/reference/{layer}.md`
- **If file exists**: skip silently and log `(existing, kept)`

After all layer files: regenerate `docs/reference/INDEX.md` (AUTO-MANAGED
region) and upsert `## Implementation References` block in root
`CLAUDE.md` between `<!-- AUTO-MANAGED:references -->` markers.
````

- [ ] **Step 3: Add required `Bash` allowances to frontmatter if missing**

Check the `allowed-tools` line. The detection logic uses `find` and `ls`, which are already permitted. No change expected — verify by searching the frontmatter.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/run-all.sh reference-docs`
Expected: All Task 6 assertions pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/project-init/commands/init-project.md
git commit -m "feat: add Step 4.5 (reference doc detection) to init-project"
```

---

## Task 8: Add failing test for sync-docs reference block

**Files:**
- Modify: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Append sync-docs assertions**

Append to `tests/structure/test-reference-docs.sh`:

```bash
# --- sync-docs Phase 1 reference block ---

SYNC_CMD="plugins/project-init/commands/sync-docs.md"
if [ -f "$SYNC_CMD" ]; then
    SYNC_CONTENT=$(cat "$SYNC_CMD")
    assert_contains "sync-docs: has Implementation References block" "$SYNC_CONTENT" "Implementation References"
    assert_contains "sync-docs: detects missing layer files" "$SYNC_CONTENT" "docs/reference/"
    assert_contains "sync-docs: validates Code Pointers" "$SYNC_CONTENT" "Code Pointer"
    assert_contains "sync-docs: notes INDEX auto-correction" "$SYNC_CONTENT" "AUTO-MANAGED:index"
    assert_contains "sync-docs: refers users to /add-reference-doc" "$SYNC_CONTENT" "/add-reference-doc"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run-all.sh reference-docs`
Expected: FAIL on Implementation References assertions.

- [ ] **Step 3: Commit**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: add failing assertions for sync-docs reference block"
```

---

## Task 9: Modify sync-docs.md — Phase 1 extension

**Files:**
- Modify: `plugins/project-init/commands/sync-docs.md`

- [ ] **Step 1: Locate Phase 1 (Gap Analysis) section**

Run: `grep -n "^## Phase" plugins/project-init/commands/sync-docs.md`
Identify where Phase 1 begins and where Phase 2 (CLAUDE.md Quality Assessment) begins.

- [ ] **Step 2: Insert Implementation References block in Phase 1**

Edit `plugins/project-init/commands/sync-docs.md`. Add a new subsection at the end of Phase 1, before the Phase 2 heading:

````markdown
### Phase 1.5: Implementation References

Re-run the layer detection from `/init-project` Step 4.5 (signal matrix).
For each detected layer, check `docs/reference/{layer}.md`:

- **Missing file** for a detected layer → output:
  `❌ {layer}.md missing — run /add-reference-doc {layer}`

- **Existing file with Code Pointers** → for each path-like string under the
  `### 4. Code Pointers` section that matches the regex
  `[A-Za-z0-9_./-]+\.[A-Za-z0-9]+` with at least one `/`, verify the path
  exists on disk. Report:
  `⚠ {layer}.md: Code Pointer "<path>" not found in repo`

- **TODO marker count** → report only (no grade):
  `ℹ {layer}.md: 5 TODO markers remaining`

- **INDEX.md drift** → regenerate the table inside
  `<!-- AUTO-MANAGED:index -->` markers from the current
  `docs/reference/*.md` listing. If contents differed, report:
  `✓ INDEX.md auto-corrected (was out of sync)`

This block reports and may rewrite **only** the AUTO-MANAGED region in
INDEX.md. Layer files themselves are never modified by `/sync-docs`.
````

- [ ] **Step 3: Run tests to verify they pass**

Run: `bash tests/run-all.sh reference-docs`
Expected: Task 8 assertions pass.

- [ ] **Step 4: Commit**

```bash
git add plugins/project-init/commands/sync-docs.md
git commit -m "feat: add Phase 1.5 reference gap + Code Pointer check to sync-docs"
```

---

## Task 10: Add failing test for doc-sync-checker agent

**Files:**
- Modify: `tests/structure/test-reference-docs.sh`

- [ ] **Step 1: Append doc-sync-checker assertions**

Append to `tests/structure/test-reference-docs.sh`:

```bash
# --- doc-sync-checker agent extension ---

CHECKER_AGENT="plugins/project-init/agents/doc-sync-checker.md"
if [ -f "$CHECKER_AGENT" ]; then
    CHECKER_CONTENT=$(cat "$CHECKER_AGENT")
    assert_contains "doc-sync-checker: examines docs/reference/" "$CHECKER_CONTENT" "docs/reference/"
    assert_contains "doc-sync-checker: validates Code Pointers" "$CHECKER_CONTENT" "Code Pointer"
    assert_contains "doc-sync-checker: checks INDEX consistency" "$CHECKER_CONTENT" "AUTO-MANAGED:index"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run-all.sh reference-docs`
Expected: FAIL on doc-sync-checker assertions.

- [ ] **Step 3: Commit**

```bash
git add tests/structure/test-reference-docs.sh
git commit -m "test: add failing assertions for doc-sync-checker reference logic"
```

---

## Task 11: Extend doc-sync-checker agent

**Files:**
- Modify: `plugins/project-init/agents/doc-sync-checker.md`

- [ ] **Step 1: Append reference-doc validation section**

Edit `plugins/project-init/agents/doc-sync-checker.md`. After the existing checklist, add:

````markdown
## Implementation Reference Validation

In addition to CLAUDE.md and existing documents, examine `docs/reference/`:

1. Enumerate `docs/reference/*.md` (excluding `INDEX.md`).
2. For each file, parse the `### 4. Code Pointers` section. Extract path-like
   tokens matching `[A-Za-z0-9_./-]+\.[A-Za-z0-9]+` containing at least one
   `/`. Verify each exists on disk; report missing ones.
3. Compare `docs/reference/INDEX.md` table inside the
   `<!-- AUTO-MANAGED:index -->` block against the actual directory
   listing. Report any mismatch.
4. Report `<!-- TODO -->` marker counts per file (informational).

Report findings in the same structured format used elsewhere in the agent.
````

- [ ] **Step 2: Run tests to verify they pass**

Run: `bash tests/run-all.sh reference-docs`
Expected: Task 10 assertions pass.

- [ ] **Step 3: Commit**

```bash
git add plugins/project-init/agents/doc-sync-checker.md
git commit -m "feat: extend doc-sync-checker to validate reference docs"
```

---

## Task 12: Author ADR-005 and ADR-006

**Files:**
- Create: `docs/decisions/ADR-005-implementation-reference-docs.md`
- Create: `docs/decisions/ADR-006-hybrid-detection-confirmation.md`

- [ ] **Step 1: Write ADR-005**

Create `docs/decisions/ADR-005-implementation-reference-docs.md` following the existing ADR format (review `ADR-001` for structure). Required sections:

```markdown
# ADR-005: Implementation Reference Docs Structure

- Status: Accepted
- Date: 2026-05-18
- Supersedes: —

## Context
The plugin needs a way to record per-layer implementation knowledge that is
consistent across projects so new readers (humans and LLMs) can navigate any
project initialized with `project-init` the same way.

## Decision
- 8 layer-specific reference docs under `docs/reference/`: infrastructure,
  data, api, iac, frontend, ui, security, agent-llm.
- All docs share a 5-section skeleton: Overview / Components / Key Decisions
  / Code Pointers / Cross-references.
- An auto-managed `docs/reference/INDEX.md` and a `## Implementation
  References` block in root `CLAUDE.md` keep navigation in sync, enforced
  via `<!-- AUTO-MANAGED:* -->` marker regions.
- Bilingual (Korean/English) per ADR-001, with shields.io anchor badges per
  ADR-002.

## Alternatives Considered
- Single monolithic `docs/implementation.md` — rejected: too large, no
  cross-project navigation parity.
- Extension of `docs/architecture.md` — rejected: architecture is
  intentionally high-level; mixing it with per-layer detail blurs
  abstraction levels.
- Per-module CLAUDE.md absorption — rejected: module ≠ layer; layers cut
  across modules.

## Consequences
- New readers can rely on identical structure across projects.
- `/sync-docs` can validate Code Pointers cheaply.
- Extension to a 9th layer (e.g., Observability) requires only adding a new
  fenced block in `reference-doc-template.md` plus a one-line enum update.

## References
- Spec: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
```

Mirror the same structure in Korean below per ADR-001.

- [ ] **Step 2: Write ADR-006**

Create `docs/decisions/ADR-006-hybrid-detection-confirmation.md`:

```markdown
# ADR-006: Hybrid Detection + User Confirmation for Reference Doc Generation

- Status: Accepted
- Date: 2026-05-18

## Context
`/init-project` must decide which of the 8 implementation reference layers
to generate. Three pure approaches exist: fully automatic (silent miss
risk), fully interactive (cognitive load), and preset (edge-case
mismatch).

## Decision
Run detection first (signal matrix in spec §5.1.1), then present results
to the user with pre-checked boxes for the detected set, allowing edit
before generation. Security is always pre-checked regardless of detection.

## Alternatives Considered
- Automatic only — rejected: empty projects produce nothing; detection
  errors propagate silently.
- Interactive only — rejected: user repeats work the plugin can infer.
- Preset profiles (`web-app`, `cli-tool`, etc.) — rejected: any project
  that does not match a preset falls back to interactive anyway.

## Consequences
- Empty projects work: zero detections + Security pre-checked + ability to
  add layers later with `/add-reference-doc`.
- False positives in detection are corrected by the user before they
  produce stale files.

## References
- Spec: `docs/superpowers/specs/2026-05-18-implementation-reference-docs-design.md`
- Related: ADR-005
```

Add Korean mirror.

- [ ] **Step 3: Update root CLAUDE.md ADR index**

Edit the `### Current ADRs` list in root `CLAUDE.md`. Add two lines:

```markdown
- [ADR-005](docs/decisions/ADR-005-implementation-reference-docs.md) -- Implementation reference docs structure (8 layers, shared 5-section skeleton, AUTO-MANAGED INDEX)
- [ADR-006](docs/decisions/ADR-006-hybrid-detection-confirmation.md) -- Hybrid detection + user confirmation flow for /init-project Step 4.5
```

- [ ] **Step 4: Commit**

```bash
git add docs/decisions/ADR-005-implementation-reference-docs.md docs/decisions/ADR-006-hybrid-detection-confirmation.md CLAUDE.md
git commit -m "docs: add ADR-005 (reference docs) and ADR-006 (hybrid detection)"
```

---

## Task 13: Update plugins/project-init/CLAUDE.md Key Files list

**Files:**
- Modify: `plugins/project-init/CLAUDE.md`

- [ ] **Step 1: Add entries to Key Files**

Insert under the existing `## Key Files` list:

```markdown
- `commands/add-reference-doc.md` - Add layer-specific implementation reference doc
- `skills/project-scaffolder/references/reference-doc-template.md` - 8-layer skeleton library used by /init-project and /add-reference-doc
```

- [ ] **Step 2: Commit**

```bash
git add plugins/project-init/CLAUDE.md
git commit -m "docs: list add-reference-doc and reference template in plugin CLAUDE.md"
```

---

## Task 14: Bump plugin version to 2.1.0

**Files:**
- Modify: `plugins/project-init/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Read current versions**

Run:
```bash
python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['metadata']['version'])"
```
Both should print `2.0.0`.

- [ ] **Step 2: Update plugin.json**

Edit the `"version": "2.0.0"` line to `"version": "2.1.0"`.

- [ ] **Step 3: Update marketplace.json**

Edit the `"version": "2.0.0"` line in the `metadata` block to `"version": "2.1.0"`.

- [ ] **Step 4: Run version-sync test**

Run: `bash tests/run-all.sh structure`
Expected: `Version sync: marketplace.json matches plugin.json` passes.

- [ ] **Step 5: Commit**

```bash
git add plugins/project-init/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version to 2.1.0 (reference docs feature)"
```

---

## Task 15: Update CHANGELOG.md with 2.1.0 entry

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add a 2.1.0 entry at the top of the changelog**

Following the existing bilingual format (review the 2.0.0 entry for structure), add:

```markdown
## [2.1.0] - 2026-05-18

### Added
- Implementation reference docs feature — `/init-project` Step 4.5 detects up to 8 layers (infrastructure, data, api, iac, frontend, ui, security, agent-llm) and generates skeletons under `docs/reference/`
- New command `/add-reference-doc <layer>` for incremental layer additions
- Auto-managed `docs/reference/INDEX.md` and `## Implementation References` block in root CLAUDE.md (between `<!-- AUTO-MANAGED:* -->` markers)
- New plugin template: `skills/project-scaffolder/references/reference-doc-template.md`

### Changed
- `/sync-docs` Phase 1 extended with a reference block: detects missing layer docs, validates Code Pointers, auto-corrects INDEX drift
- `doc-sync-checker` agent extended with reference-doc validation

### Documentation
- ADR-005: Implementation reference docs structure
- ADR-006: Hybrid detection + user confirmation for /init-project
```

Mirror in Korean below per existing CHANGELOG format.

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add 2.1.0 entry covering reference docs feature"
```

---

## Task 16: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document `/add-reference-doc` in the Plugin commands list**

Locate the command list in `README.md` (search for `/init-project`). Add:

```markdown
- `/add-reference-doc <layer>` - Add a layer-specific implementation reference doc skeleton (`infrastructure`, `data`, `api`, `iac`, `frontend`, `ui`, `security`, `agent-llm`)
```

- [ ] **Step 2: Add brief description of the reference docs system**

In the "What it does" / feature list section, add:

```markdown
- **Implementation reference docs**: Per-layer skeletons under `docs/reference/` with shared 5-section structure (Overview / Components / Key Decisions / Code Pointers / Cross-references). Auto-detected at init, drift-checked by `/sync-docs`.
```

Mirror in Korean per README's bilingual layout.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document /add-reference-doc and reference docs feature"
```

---

## Task 17: Final regression — run full test suite

- [ ] **Step 1: Run full suite**

Run: `bash tests/run-all.sh`
Expected: All 114 existing tests + all new `test-reference-docs.sh` assertions pass. Note the total count (should be ≥ 114 + new assertion count).

- [ ] **Step 2: If any test fails**

Investigate the specific assertion. Do not skip — fix the underlying cause. If a structural test fails because content drifted, re-read the relevant task and re-apply.

- [ ] **Step 3: Confirm no uncommitted changes remain**

Run: `git status --short`
Expected: empty output.

- [ ] **Step 4: Push branch / open PR** (manual; outside this plan)

The plan ends with a clean working tree on `main` (or feature branch) with all 16 commits in linear sequence, ready for PR review.

---

## Self-Review

**Spec coverage:**
- §4 Architecture overview → Tasks 2, 5, 7, 9, 11 implement the 3-command system and shared template primitive.
- §5.1 init-project Step 4.5 → Tasks 6-7.
- §5.2 /add-reference-doc → Tasks 4-5.
- §5.3 Common skeleton structure → Task 2 (template) + Task 3 (tests).
- §5.4 INDEX.md format → Tasks 5 (writes), 9 (sync-docs validates), 11 (agent validates).
- §5.5 Root CLAUDE.md integration → Tasks 5, 7, 12 (Step 3).
- §5.6 sync-docs extension → Tasks 8-9.
- §5.7 doc-sync-checker → Tasks 10-11.
- §5.8 Plugin reference template → Task 2.
- §6 Variables → Task 2 template + Task 5 substitution logic.
- §7 Conflict policy → encoded in Task 5 Step 3 (overwrite/skip/abort) and Task 7 Step 2 (init: existing-kept).
- §8 ADRs → Task 12.
- §9 Testing → Tasks 1, 3, 4, 6, 8, 10 (cumulative single file `test-reference-docs.sh`). Note: spec listed 5 separate test files; this plan consolidates into one file with grouped sections for maintainability. All 5 testing concerns from the spec are covered by named assertion groups in the single file.
- §10 Affected files → all listed files appear in some task.
- §11 Build sequence → tasks ordered to match spec's 1-9 sequence with TDD interleaving.

**Placeholder scan:** No "TBD"/"TODO"/"implement later" in any task. Korean mirror sections in ADRs and CHANGELOG are explicit instructions ("Add Korean mirror") rather than placeholders, because the content is mechanical translation of clearly-stated English source.

**Type consistency:** Layer enum (`infrastructure`, `data`, `api`, `iac`, `frontend`, `ui`, `security`, `agent-llm`) appears consistently across Tasks 1, 4, 5, 6, 7, 8, 11. AUTO-MANAGED marker tokens (`<!-- AUTO-MANAGED:index -->`, `<!-- AUTO-MANAGED:references -->`) are spelled identically wherever referenced. The variable `{{COMPONENTS_TABLE}}` and `{{CODE_POINTERS_AUTO}}` match between template (Task 2) and command logic (Tasks 5, 7).

**Known consolidation decision:** Spec listed 5 separate test files; plan uses 1 file (`tests/structure/test-reference-docs.sh`) with grouped assertion blocks added across tasks 1, 3, 4, 6, 8, 10. This change is intentional: it reduces filesystem churn and matches the existing test convention of grouping related assertions per file (see `tests/structure/test-plugin-structure.sh` for precedent). The spec's testing coverage is preserved.

