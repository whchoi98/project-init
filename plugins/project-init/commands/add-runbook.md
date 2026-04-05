---
description: Create a new operational runbook from template in docs/runbooks/
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(ls:*), Bash(find:*), Glob, Grep
argument-hint: Runbook name (e.g. deploy-production, database-migration, incident-response)
---

# Add Runbook

Create a new operational runbook with structured steps and update project-level docs.

## Step 1: Determine Runbook Name

Target: $ARGUMENTS

- If no name provided, ask the user for the runbook name
- Convert to kebab-case for the filename (e.g. "Deploy Production" -> `deploy-production.md`)
- Check if `docs/runbooks/` directory exists; create it if missing
- Check if the runbook already exists; if so, offer to update it instead

```bash
ls docs/runbooks/ 2>/dev/null
```

## Step 2: Gather Runbook Details

Ask the user:

1. **Purpose**: What operational task does this runbook cover? (one sentence)
2. **When to use**: Under what circumstances should someone follow this runbook?
3. **Prerequisites**: What tools, permissions, or access are needed?
4. **Procedure**: What are the high-level steps? (Claude will expand these)
5. **Rollback**: Is there a recovery procedure if something goes wrong?

If the user provides minimal input, infer from the runbook name and project context:
- Read `CLAUDE.md` for tech stack and deployment info
- Read `docs/architecture.md` for system components
- Infer appropriate steps based on the runbook topic

## Step 3: Read Template

Read the runbook template for structure reference:

```
Read file: skills/project-scaffolder/references/docs-templates.md
```

Use the Runbook Template section as the base structure.

## Step 4: Create Runbook

Create `docs/runbooks/<runbook-name>.md` with the following structure:

```markdown
# Runbook: <Title>

## Overview
<purpose from user input or inferred from context>

## When to Use
<circumstances that trigger this runbook>

## Prerequisites
- <required permissions>
- <required tools>
- <required access>

## Procedure

### 1. <First Phase>
<detailed steps with copy-paste ready commands>

### 2. <Second Phase>
<detailed steps with copy-paste ready commands>

### 3. <Third Phase>
<detailed steps with copy-paste ready commands>

## Verification
<!-- How to verify the procedure was successful -->
- [ ] <check 1>
- [ ] <check 2>

## Rollback
<!-- Recovery procedure if something goes wrong -->
1. <rollback step 1>
2. <rollback step 2>

## Notes
- Last verified: <today's date>
- Author: <user or inferred>
```

Key principles:
- Every command must be **copy-paste ready** (no placeholder paths without explanation)
- Include **verification steps** after each major phase
- Rollback section must be actionable, not vague
- Use code blocks with language tags for all commands

## Step 5: Update Root CLAUDE.md

Read the root `CLAUDE.md`. If a Runbooks section exists, add the new runbook. If not, suggest adding one.

## Step 6: Update docs/architecture.md

If the runbook relates to a specific component (e.g. deployment, database), check if `docs/architecture.md` references operational procedures. If an Infrastructure or Operations section exists, add a cross-reference.

## Step 7: Summary

Display:
- Created runbook file path and name
- Overview of sections included
- Suggested follow-up actions:
  - Create related runbooks (e.g. if deploy-production was created, suggest rollback-production)
  - Link the runbook from relevant module CLAUDE.md files
  - Schedule periodic review of the runbook
