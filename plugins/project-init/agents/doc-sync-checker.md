---
name: doc-sync-checker
description: Check if project documentation is in sync with current code state. Returns list of missing or outdated documents with quality scores.
tools: Read, Glob, Grep, Bash(find:*), Bash(git log:*), Bash(ls:*), Bash(cat:*)
model: opus
color: cyan
---

# Documentation Sync Checker

Analyze the project to find documentation gaps, outdated docs, and score CLAUDE.md quality.

## Tasks

### 1. Find Source Directories

Detect the main source directory layout:

```bash
ls -d src/ app/ lib/ cmd/ pkg/ internal/ components/ pages/ routes/ 2>/dev/null
```

### 2. Find Missing Module CLAUDE.md

For each source directory found, recursively check subdirectories:

```bash
find <source_dir> -type d -mindepth 1 2>/dev/null
```

For each directory, check if `CLAUDE.md` exists.

### 3. Check Architecture Doc Freshness

- Read `docs/architecture.md` and compare component list against actual source directories
- Flag components mentioned in docs but missing from code (or vice versa)

### 4. Check ADR Coverage

```bash
git log --oneline -20 2>/dev/null
```

Look for commits that suggest architectural decisions:
- New dependencies (package.json, pyproject.toml, go.mod changes)
- Schema changes (migration files, model changes)
- API redesigns (new route files, endpoint changes)
- Infrastructure changes (Dockerfile, terraform, CDK changes)

Check if corresponding ADRs exist in `docs/decisions/`.

### 5. Check Root CLAUDE.md Freshness

- Compare Tech Stack section against actual dependency files
- Compare Project Structure section against actual directory tree
- Compare Key Commands against actual build system (package.json scripts, Makefile, etc.)

### 6. Score Each CLAUDE.md

For each CLAUDE.md file found, score against these criteria (total 100):

| Criterion | Max Score | Check |
|-----------|-----------|-------|
| Commands/workflows | 20 | Build/test/deploy commands present and correct? |
| Architecture clarity | 20 | Codebase structure understandable? |
| Non-obvious patterns | 15 | Gotchas and quirks documented? |
| Conciseness | 15 | No verbose or obvious info? |
| Currency | 15 | Reflects current codebase state? |
| Actionability | 15 | Instructions copy-paste ready? |

**Grades:** A (90-100), B (70-89), C (50-69), D (30-49), F (0-29)

## Output

Return a structured report:

```
## Documentation Sync Report

### Quality Scores

| File | Score | Grade | Key Issues |
|------|-------|-------|------------|
| ./CLAUDE.md | 72/100 | B | Commands outdated |
| ./src/api/CLAUDE.md | 45/100 | D | Missing endpoints list |
| ./src/auth/CLAUDE.md | -- | F | FILE MISSING |

### Missing Module CLAUDE.md
- src/newmodule/ - no CLAUDE.md found
- src/utils/helpers/ - no CLAUDE.md found

### Stale Documents
- docs/architecture.md - mentions "oldservice" component which no longer exists
- CLAUDE.md - Tech Stack lists "express" but package.json shows "fastify"
- CLAUDE.md - Key Commands reference "npm run build" but script is "npm run compile"

### Suggested ADRs
- Commit abc1234 added Redis dependency - no ADR found
- Commit def5678 changed auth from JWT to session-based - no ADR found

### Summary
- X modules missing documentation
- Y documents potentially stale
- Z architectural decisions undocumented
- Average quality score: XX/100
```
