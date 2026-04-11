# Docs Module

## Role
Project documentation including architecture design, Architecture Decision Records (ADRs), operational runbooks, and developer onboarding guide. All user-facing documents use bilingual (Korean/English) format.

## Key Files
- `architecture.md` - System architecture with ASCII diagrams (bilingual)
- `onboarding.md` - Developer onboarding guide with setup steps
- `decisions/.template.md` - ADR template (bilingual: Status/Context/Options/Decision/Consequences)
- `runbooks/.template.md` - Runbook template (bilingual: Overview/Procedure/Verification/Rollback)

## Dependencies
- All documents follow `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`

## Rules
- Architecture doc uses Unicode box-drawing characters (`┌─┐│└─┘▶▼`)
- ADR files follow `ADR-NNN-concise-title.md` naming convention
- Runbook commands must be copy-paste ready
- All docs use bilingual structure with `# English` / `# 한국어` sections
- Both Korean and English sections must have identical structure and information
- No emojis; code blocks must specify language; English imperative, Korean 경어체
