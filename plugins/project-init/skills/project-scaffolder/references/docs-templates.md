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

## Operations
<!-- Link to relevant runbooks in docs/runbooks/ -->
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

## Options Considered

### Option 1: <Name>
- **Pros**: <advantages>
- **Cons**: <disadvantages>

### Option 2: <Name>
- **Pros**: <advantages>
- **Cons**: <disadvantages>

## Decision
<!-- The decision that was made and the reasoning -->

## Consequences

### Positive
- <positive impact>

### Negative
- <negative impact or trade-off>
```

### ADR Numbering Convention

1. List existing ADRs: `find docs/decisions -name 'ADR-*.md' -not -name '.template.md' | sort`
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

## When to Use
<!-- Circumstances that trigger this runbook -->

## Prerequisites
<!-- Required permissions, tools, etc. -->

## Procedure

### 1. <First Phase>
<!-- Detailed steps with copy-paste ready commands -->

### 2. <Second Phase>
<!-- Detailed steps with copy-paste ready commands -->

## Verification
- [ ] <check 1>
- [ ] <check 2>

## Rollback
<!-- Recovery procedure if something goes wrong -->

## Notes
- Last verified: YYYY-MM-DD
```

### Recommended Runbooks

| Runbook | When to Create |
|---------|---------------|
| `deploy-production.md` | Project has Dockerfile, CDK, SAM, Terraform, or CI/CD |
| `database-migration.md` | Project has migration files or database config |
| `incident-response.md` | Project has monitoring or alerting config |
| `environment-setup.md` | Project has multiple environments |
| `rollback-production.md` | Production deployment runbook exists |

---

## Onboarding Document

Path: `docs/onboarding.md`

```markdown
# Developer Onboarding

## Quick Start

### 1. Prerequisites
<!-- List required tools, accounts, and access -->
- [ ] <tool/runtime> installed (version X+)
- [ ] Repository access granted
- [ ] Environment variables configured (see .env.example)

### 2. Setup
<!-- Step-by-step setup with copy-paste commands -->

### 3. Verify
<!-- How to confirm everything works -->

## Project Overview
<!-- Brief architecture explanation for newcomers -->
- Read `CLAUDE.md` for project context and conventions
- Read `docs/architecture.md` for system design
- Review `docs/decisions/` for architectural decisions

## Development Workflow
<!-- Day-to-day development process -->
- Branch naming: `feat/`, `fix/`, `docs/`, `refactor/`
- Commit convention: Conventional Commits
- PR process: <describe>

## Key Concepts
<!-- Domain-specific concepts new developers need to know -->

## Troubleshooting
<!-- Common issues new developers encounter -->

## Resources
<!-- Links to relevant documentation, wikis, design docs -->
```

---

## API Reference Document

Path: `docs/api-reference.md`

```markdown
# API Reference

## Base URL
<!-- e.g., https://api.example.com/v1 -->

## Authentication
<!-- How to authenticate (Bearer token, API key, etc.) -->

## Endpoints

### <Resource Name>

#### List <Resources>
```
GET /resources
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `limit` | integer | No | Items per page (default: 20) |

**Response** `200 OK`

#### Get <Resource>
```
GET /resources/:id
```

**Response** `200 OK`

#### Create <Resource>
```
POST /resources
```

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Resource name |

**Response** `201 Created`

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Missing or invalid auth |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource does not exist |
| 500 | Internal Server Error |

## Rate Limits
<!-- Rate limiting policy -->
```

---

## Environment Template

Path: `.env.example`

```bash
# Application
APP_NAME=my-app
APP_ENV=development
APP_PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_dev
DB_USER=
DB_PASSWORD=

# Authentication
JWT_SECRET=
JWT_EXPIRY=3600

# External Services
# API_KEY=
# WEBHOOK_URL=

# Claude Code Notifications (optional)
# CLAUDE_NOTIFY_WEBHOOK=
```

### Rules

- `.env.example` is committed to git (contains only placeholder values)
- `.env` is NEVER committed (listed in `.gitignore`)
- Secrets use empty values or comments in `.env.example`
- Each variable includes a comment explaining its purpose
