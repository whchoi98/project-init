# Docs Module

## Role
Project documentation including architecture design, Architecture Decision Records (ADRs), operational runbooks, and developer onboarding guide. Bilingual (Korean/English) where applicable.

## Key Files
- `architecture.md` - System architecture with ASCII diagrams (bilingual)
- `onboarding.md` - Developer onboarding guide with setup steps
- `decisions/.template.md` - ADR template (Status, Context, Options, Decision, Consequences)
- `runbooks/.template.md` - Runbook template (Overview, Procedure, Verification, Rollback)

## Rules
- Architecture doc uses Unicode box-drawing characters (`┌─┐│└─┘▶▼`)
- ADR files follow `ADR-NNN-concise-title.md` naming convention
- Runbook commands must be copy-paste ready
- Both Korean and English sections must have identical structure in bilingual docs
