---
description: Synchronize all project documentation with current code state
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git log:*), Bash(ls:*), Bash(tree:*), Agent
---

# Sync Docs

Synchronize project documentation with the current code state.

## Context

- Project structure: !`find . -not -path './.git/*' -not -path './node_modules/*' -not -path './__pycache__/*' -not -path './.venv/*' -type f | head -100`
- Recent commits: !`git log --oneline -20 2>/dev/null || echo "Not a git repository"`
- Existing CLAUDE.md files: !`find . -name "CLAUDE.md" -not -path './.git/*' 2>/dev/null`

## Phase 0: Gap Analysis (Subagent)

Launch the `doc-sync-checker` agent to analyze documentation gaps in parallel. This provides a structured report of:
- Missing module CLAUDE.md files
- Stale documents
- Suggested ADRs
- Quality scores for each CLAUDE.md

Use this report to prioritize updates in the following steps.

## Phase 1: CLAUDE.md Quality Assessment

For each CLAUDE.md file found, evaluate quality against these criteria:

| Criterion | Weight | Check |
|-----------|--------|-------|
| Commands/workflows documented | 20 | Are build/test/deploy commands present and correct? |
| Architecture clarity | 20 | Can Claude understand the codebase structure? |
| Non-obvious patterns | 15 | Are gotchas and quirks documented? |
| Conciseness | 15 | No verbose explanations or obvious info? |
| Currency | 15 | Does it reflect current codebase state? |
| Actionability | 15 | Are instructions executable, not vague? |

**Quality Grades:**
- **A (90-100)**: Comprehensive, current, actionable
- **B (70-89)**: Good coverage, minor gaps
- **C (50-69)**: Basic info, missing key sections
- **D (30-49)**: Sparse or outdated
- **F (0-29)**: Missing or severely outdated

Output a quality report before making changes:

```
## CLAUDE.md Quality Report

### Summary
- Files found: X
- Average score: XX/100
- Files needing update: X

### File-by-File Assessment

#### ./CLAUDE.md (Project Root)
**Score: XX/100 (Grade: X)**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Commands/workflows | X/20 | ... |
| Architecture clarity | X/20 | ... |
| Non-obvious patterns | X/15 | ... |
| Conciseness | X/15 | ... |
| Currency | X/15 | ... |
| Actionability | X/15 | ... |
```

## Phase 2: Root CLAUDE.md Sync

Read the root `CLAUDE.md` and update:
- **Overview** - Match current project purpose
- **Tech Stack** - Match actual dependencies (package.json, pyproject.toml, go.mod, etc.)
- **Project Structure** - Match actual directory tree
- **Conventions** - Match observed code patterns
- **Key Commands** - Match actual build/test/deploy commands

Verify commands are copy-paste ready by checking they reference actual scripts/files.

## Phase 3: Architecture Doc Sync

Read `docs/architecture.md` and update:
- **System Overview** - Reflect current system design
- **Components** - Add new components, remove deleted ones
- **Data Flow** - Update if data flow changed
- **Infrastructure** - Update if infra changed

## Phase 4: Module CLAUDE.md Audit

Detect the main source directory (src/, app/, lib/, cmd/, etc.):

```bash
ls -d src/ app/ lib/ cmd/ pkg/ internal/ components/ pages/ 2>/dev/null
```

Scan all directories under the source root:

```bash
find <source_dir> -type d -not -path './.git/*' 2>/dev/null
```

For each directory:
- If `CLAUDE.md` is missing, create one with module name, role, and key files
- If `CLAUDE.md` exists, verify it matches current files and update if needed
- Score each module CLAUDE.md using the quality criteria

## Phase 5: ADR Audit

Review recent commits for architecture-relevant changes:

```bash
git log --oneline -20 2>/dev/null
```

Check if significant decisions are documented:
- New dependencies added (check git diff for package.json/pyproject.toml changes)
- API design changes
- Database schema changes
- Infrastructure changes

If undocumented decisions found, suggest creating new ADRs. Determine the next ADR number:

```bash
find docs/decisions -name 'ADR-*.md' 2>/dev/null | sort -t'-' -k2 -n | tail -1
```

## Phase 6: README.md Sync

Update `README.md` project structure section to match actual directory layout.

## Phase 7: Report

Present a comprehensive summary:

```
## Sync Report

### Quality Scores (Before -> After)
- ./CLAUDE.md: D (35) -> B (78)
- ./src/api/CLAUDE.md: F (0) -> C (55) [NEW]
- ./src/auth/CLAUDE.md: C (52) -> B (72)

### Changes Made
- Files created: X
- Files updated: X

### Suggested ADRs
- ADR-003: Adopted Redis for session caching (from commit abc1234)

### Remaining Gaps
- src/utils/ has no CLAUDE.md (directory contains only helper functions)
```
