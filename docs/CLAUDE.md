# Docs Module

## Role
Project documentation including architecture design, Architecture Decision Records (ADRs), operational runbooks, and developer onboarding guide. Architecture, ADRs, and runbooks are bilingual (Korean/English); `onboarding.md` and the design notes under `superpowers/` are English-only.

## Key Files
- `architecture.md` - System architecture with Mermaid flowchart diagrams (bilingual)
- `onboarding.md` - Developer onboarding guide with setup steps
- `decisions/.template.md` - ADR template (bilingual: Status/Context/Options/Decision/Consequences)
- `runbooks/.template.md` - Runbook template (bilingual: Overview/Procedure/Verification/Rollback)

## Dependencies
- All documents follow `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`

## Rules
- Architecture figures follow the writing-style-guide `## Diagram Rules` (ADR-010): infographics built with the `aws-infographic` skill, one English and one Korean version, or Mermaid flowcharts where the skill is unavailable; the Mermaid diagrams now in `architecture.md` stay until they are rebuilt; no ASCII box diagrams
- Runbook commands must be copy-paste ready
- Bilingual docs use `# English` / `# 한국어` sections with identical structure and information
- No emojis; code blocks must specify language; English imperative, Korean 경어체
