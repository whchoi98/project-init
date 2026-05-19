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

# --- init-project Step 4.5: Implementation Reference Detection ---

INIT_CMD="plugins/project-init/commands/init-project.md"
if [ -f "$INIT_CMD" ]; then
    INIT_CONTENT=$(cat "$INIT_CMD")
    assert_contains "init-project: has Step 4.5 (reference detection)" "$INIT_CONTENT" "Implementation Reference Detection"
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

# --- doc-sync-checker agent extension ---

CHECKER_AGENT="plugins/project-init/agents/doc-sync-checker.md"
if [ -f "$CHECKER_AGENT" ]; then
    CHECKER_CONTENT=$(cat "$CHECKER_AGENT")
    assert_contains "doc-sync-checker: examines docs/reference/" "$CHECKER_CONTENT" "docs/reference/"
    assert_contains "doc-sync-checker: validates Code Pointers" "$CHECKER_CONTENT" "Code Pointer"
    assert_contains "doc-sync-checker: checks INDEX consistency" "$CHECKER_CONTENT" "AUTO-MANAGED:index"
fi
