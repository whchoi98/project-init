# Documentation Templates

Templates for `docs/` files.

---

## Architecture Document

Path: `docs/architecture.md`

```markdown
# Architecture

## System Overview
<!-- Describe the overall system architecture -->

## Components
<!-- List major components and their roles -->

## Data Flow
<!-- Describe how data flows through the system -->

## Infrastructure
<!-- Describe infrastructure setup -->
```

---

## ADR Template

Path: `docs/decisions/.template.md`

```markdown
# ADR-000: Title

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
<!-- Background explaining why a decision is needed -->

## Decision
<!-- The decision that was made -->

## Consequences
<!-- Impact of the decision -->
```

### ADR Numbering Convention

1. List existing ADRs: `find docs/decisions -name 'ADR-*.md' | sort`
2. Take the highest number and add 1
3. Format: `ADR-NNN-concise-title.md`

### Example ADRs

- `ADR-001-use-postgresql.md`
- `ADR-002-rest-api-design.md`
- `ADR-003-adopt-typescript.md`

---

## Runbook Template

Path: `docs/runbooks/.template.md`

```markdown
# Runbook: Title

## Overview
<!-- Purpose of this runbook -->

## Prerequisites
<!-- Required permissions, tools, etc. -->

## Procedure
1. Step 1
2. Step 2
3. Step 3

## Rollback
<!-- Recovery procedure if something goes wrong -->
```

### Example Runbooks

- `deploy-production.md` - Production deployment procedure
- `database-migration.md` - Database migration steps
- `incident-response.md` - Incident handling procedure
