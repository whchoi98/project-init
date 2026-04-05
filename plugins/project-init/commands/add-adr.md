---
description: Create a new Architecture Decision Record with auto-numbering
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(ls:*), Bash(find:*), Glob, Grep
argument-hint: ADR title (e.g. "use-postgresql", "adopt-rest-api", "switch-to-typescript")
---

# Add ADR

Create a new Architecture Decision Record with automatic numbering and update project-level docs.

## Step 1: Determine ADR Title

Target: $ARGUMENTS

- If no title provided, ask the user for the ADR title
- Convert to kebab-case for the filename
- Check if `docs/decisions/` directory exists; create it if missing

## Step 2: Auto-Number

Find the next available ADR number:

```bash
find docs/decisions -name 'ADR-*.md' -not -name '.template.md' 2>/dev/null | sort | tail -1
```

- If no existing ADRs, start at `001`
- Otherwise, take the highest number and add 1
- Format: `ADR-NNN-<title>.md` (e.g. `ADR-001-use-postgresql.md`)

## Step 3: Gather Decision Details

Ask the user:

1. **Context**: What is the background? Why is a decision needed?
2. **Options considered**: What alternatives were evaluated? (at least 2)
3. **Decision**: Which option was chosen and why?
4. **Consequences**: What are the positive and negative impacts?
5. **Status**: Proposed, Accepted, Deprecated, or Superseded? (default: Accepted)

If the user provides minimal input:
- Read `CLAUDE.md` and `docs/architecture.md` for project context
- Read recent git log for related changes
- Infer context from the ADR title

```bash
git log --oneline -10 2>/dev/null
```

## Step 4: Read Template

Read the ADR template for structure reference:

```
Read file: skills/project-scaffolder/references/docs-templates.md
```

Use the ADR Template section as the base structure.

## Step 5: Create ADR

Create `docs/decisions/ADR-NNN-<title>.md`:

```markdown
# ADR-NNN: <Title in Natural Language>

## Status
<Proposed | Accepted | Deprecated | Superseded>

## Context
<background explaining why a decision is needed>

## Options Considered

### Option 1: <Name>
- **Pros**: <advantages>
- **Cons**: <disadvantages>

### Option 2: <Name>
- **Pros**: <advantages>
- **Cons**: <disadvantages>

## Decision
<the decision that was made and the reasoning>

## Consequences

### Positive
- <positive impact>

### Negative
- <negative impact or trade-off>

## References
- <links to relevant docs, issues, or discussions>
```

Key principles:
- Context must explain the **problem**, not the solution
- At least 2 options must be listed (including the chosen one)
- Consequences must include **both positive and negative** impacts
- References should link to relevant issues, PRs, or external docs

## Step 6: Update docs/architecture.md

Read `docs/architecture.md`. If the decision impacts the architecture:
- Add or update the relevant component description
- Reference the ADR in the appropriate section

## Step 7: Update Root CLAUDE.md

If the root `CLAUDE.md` has an Architecture Decisions or Conventions section, add a reference to the new ADR.

## Step 8: Summary

Display:
- Created ADR file path (e.g. `docs/decisions/ADR-003-use-postgresql.md`)
- Status of the decision
- Components affected
- Suggested follow-up actions:
  - Update related module CLAUDE.md files
  - Create a runbook if the decision requires operational changes
  - Review and update if the decision is still in Proposed status
