#!/bin/bash
# Tests for plugins/project-init/scripts/check-bilingual.py:
# each rule against the fixtures in tests/fixtures/bilingual/, then this repo's bilingual docs.
# Fixtures named good*.md or changelog-good*.md must pass; every other fixture breaks one rule.

BL_CHECKER="plugins/project-init/scripts/check-bilingual.py"
BL_FIXTURES="tests/fixtures/bilingual"

# Sets BL_OUT and BL_RC. The checker exits 1 on findings, so guard it: test files are sourced under set -e.
bl_run() {
    BL_RC=0
    BL_OUT=$(python3 "$BL_CHECKER" "$@" 2>&1) || BL_RC=$?
}

assert_file_exists "check-bilingual.py exists" "$BL_CHECKER"

if ! command -v python3 > /dev/null 2>&1; then
    skip "check-bilingual.py tests" "python3 not found"
elif [ -f "$BL_CHECKER" ]; then

    # --- CLI contract: exit 2 on usage or read errors ---

    bl_run
    assert_eq "check-bilingual: no arguments exits 2" "2" "$BL_RC"
    bl_run "$BL_FIXTURES/does-not-exist.md"
    assert_eq "check-bilingual: unreadable file exits 2" "2" "$BL_RC"

    # --- Fixtures: good ones exit 0, bad ones exit 1 ---

    for BL_FIXTURE in "$BL_FIXTURES"/*.md; do
        [ -f "$BL_FIXTURE" ] || continue
        BL_NAME=$(basename "$BL_FIXTURE")
        bl_run "$BL_FIXTURE"
        case "$BL_NAME" in
            good*|changelog-good*)
                assert_eq "check-bilingual: $BL_NAME passes" "0" "$BL_RC" ;;
            *)
                assert_eq "check-bilingual: $BL_NAME is rejected" "1" "$BL_RC" ;;
        esac
    done

    # --- Each rule reports the expected problem (fixture|expected output) ---

    while IFS='|' read -r BL_NAME BL_EXPECTED; do
        [ -n "$BL_NAME" ] || continue
        bl_run "$BL_FIXTURES/$BL_NAME"
        assert_contains "check-bilingual: $BL_NAME reports '$BL_EXPECTED'" "$BL_OUT" "$BL_EXPECTED"
    done <<'EOF'
bad-markdown-badges.md|bad-markdown-badges.md:3: Markdown badge linking to #english
bad-markdown-badges.md|bad-markdown-badges.md:4: Markdown badge linking to #한국어
bad-markdown-badges.md|no English language badge
bad-anchor-missing.md|bad-anchor-missing.md:48: no <a id="korean"></a> line
bad-korean-first.md|English comes first
bad-no-separator.md|no "---" line above <a id="korean"></a>
bad-setext-separator.md|bad-setext-separator.md:49: no "---" line above <a id="korean"></a>
bad-heading-levels.md|bad-heading-levels.md:63: heading "## 구조" is h2
bad-code-block-missing.md|the Korean half lacks 1 code block(s)
bad-mermaid-translated.md|bad-mermaid-translated.md:76: mermaid block 1 differs
bad-table-rows.md|table 1 has 3 rows here but 4
bad-fence-lang.md|bad-fence-lang.md:25: code fence has no language tag
bad-fence-lang.md|bad-fence-lang.md:65: code fence has no language tag
bad-unclosed-fence.md|code fence is never closed
bad-emoji.md|bad-emoji.md:14: emoji ✅ (U+2705)
bad-emoji.md|bad-emoji.md:44: emoji ⚠ (U+26A0)
bad-emoji.md|bad-emoji.md:52: emoji 🚀 (U+1F680)
changelog-bad-heading.md|does not match "## [x.y.z] - YYYY-MM-DD"
changelog-bad-heading.md|release date 2026-02-30 is not a valid
changelog-bad-halves.md|the Korean half is missing release "## [1.0.0] - 2026-08-01"
EOF

    # --- This repo's bilingual docs pass the checker ---

    for BL_DOC in README.md CHANGELOG.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md \
        docs/architecture.md docs/decisions/ADR-*.md docs/decisions/.template.md \
        docs/runbooks/*.md docs/runbooks/.template.md docs/reference/*.md; do
        [ -f "$BL_DOC" ] || continue
        bl_run "$BL_DOC"
        if [ "$BL_RC" = "0" ]; then
            pass "check-bilingual: $BL_DOC"
        else
            BL_COUNT=$(printf '%s\n' "$BL_OUT" | grep -c . || true)
            fail "check-bilingual: $BL_DOC" "$BL_COUNT issue(s), first: $(sed -n 1p <<< "$BL_OUT")"
        fi
    done
fi
