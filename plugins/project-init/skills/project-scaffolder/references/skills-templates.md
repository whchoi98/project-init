# Skills Templates

Templates for `.claude/skills/` SKILL.md files.

---

## Code Review Skill

Path: `.claude/skills/code-review/SKILL.md`

```markdown
# Code Review Skill

Review changed code with confidence-based scoring to filter false positives.

## Review Scope

By default, review unstaged changes from `git diff`. The user may specify different files or scope.

## Review Criteria

### Project Guidelines Compliance
- Import patterns and module boundaries
- Framework conventions and language style
- Function declarations and error handling
- Naming conventions from CLAUDE.md

### Bug Detection
- Logic errors and null/undefined handling
- Race conditions and memory leaks
- Security vulnerabilities (OWASP Top 10)
- Performance problems

### Code Quality
- Code duplication and unnecessary complexity
- Missing critical error handling
- Test coverage gaps
- Accessibility issues (for frontend code)

## Confidence Scoring

Rate each issue 0-100:
- **0-24**: Likely false positive or pre-existing issue. Do not report.
- **25-49**: Might be real but possibly a nitpick. Do not report.
- **50-74**: Real issue but minor. Report only if critical.
- **75-89**: Verified real issue, important. Report with fix suggestion.
- **90-100**: Confirmed critical issue. Must report.

**Only report issues with confidence >= 75.**

## Output Format

For each issue:
```
### [CRITICAL|IMPORTANT] <issue title> (confidence: XX)
**File:** `path/to/file.ext:line`
**Issue:** Clear description of the problem
**Guideline:** Reference to CLAUDE.md rule or security standard
**Fix:** Concrete code suggestion
```

If no high-confidence issues found, confirm code meets standards with brief summary.

## Usage
Run with `/code-review` command
```

---

## Refactor Skill

Path: `.claude/skills/refactor/SKILL.md`

```markdown
# Refactor Skill

Refactor existing code to improve quality without changing behavior.

## Principles
- Improve structure without changing behavior
- Single Responsibility Principle (SRP)
- Remove duplicate code (DRY)
- Small, incremental steps with verification

## Process

### 1. Analysis
- Identify the target code and its tests
- Map all callers and dependencies
- Confirm test coverage exists (suggest adding tests first if not)

### 2. Plan
Present the refactoring plan to the user:
- What will change
- What will NOT change (behavior preservation)
- Risk assessment (low/medium/high)

### 3. Execute
- Make changes in small, verifiable steps
- Run tests after each step if possible
- Keep commits atomic

### 4. Verify
- Confirm all existing tests pass
- Verify no behavior changes
- Check that the refactoring achieved its goal

## Usage
Run with `/refactor` command
```

---

## Release Skill

Path: `.claude/skills/release/SKILL.md`

```markdown
# Release Skill

Automate the release process with validation checks.

## Procedure

### 1. Pre-release Checks
- Verify working tree is clean: `git status`
- Verify all tests pass
- Check for uncommitted changes

### 2. Determine Version
- Review changes since last tag: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`
- Apply semver rules:
  - MAJOR: Breaking API changes
  - MINOR: New features, backward compatible
  - PATCH: Bug fixes only

### 3. Update Changelog
- Group changes by type (Added, Changed, Fixed, Removed)
- Include commit references
- Add date and version header

### 4. Create Release
- Update version in relevant files (package.json, pyproject.toml, etc.)
- Create git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- Generate release notes

### 5. Summary
- Display version bump
- List key changes
- Show next steps (push tag, deploy, etc.)

## Usage
Run with `/release` command
```

---

## Sync Docs Skill

Path: `.claude/skills/sync-docs/SKILL.md`

```markdown
# Sync Docs Skill

Synchronize project documentation with current code state.

## Actions

### 1. Quality Assessment
Score each CLAUDE.md file (0-100) across:
- Commands/workflows (20 pts)
- Architecture clarity (20 pts)
- Non-obvious patterns (15 pts)
- Conciseness (15 pts)
- Currency (15 pts)
- Actionability (15 pts)

Output quality report with grades (A-F) before making changes.

### 2. Root CLAUDE.md Sync
- Update Overview, Tech Stack, Conventions, Key Commands
- Verify commands are copy-paste ready against actual scripts

### 3. Architecture Doc Sync
- Update docs/architecture.md to reflect current system structure
- Add new components, update data flows, reflect infrastructure changes

### 4. Module CLAUDE.md Audit
- Scan all directories under source root
- Create CLAUDE.md for modules missing one
- Update existing module CLAUDE.md files if out of date
- Score each module CLAUDE.md

### 5. ADR Audit
- Check recent commits (git log --oneline -20)
- Suggest new ADRs for undocumented architectural decisions

### 6. README.md Sync
- Update project structure section to match actual directory layout

### 7. Report
Output before/after quality scores and list of all changes.

## Usage
Run with `/sync-docs` command
```
