# Docs Module

## Role
Project documentation including architecture design, Architecture Decision Records (ADRs), operational runbooks, and developer onboarding guide. Architecture, ADRs, and runbooks are bilingual (Korean/English); `onboarding.md` and the design notes under `superpowers/` are English-only.

## Key Files
- `architecture.md` - System architecture with infographic figures, one English and one Korean version (bilingual)
- `images/architecture/` - Page modules, text, and built figures of the architecture infographics; `sources.md` lists where each statement comes from
- `onboarding.md` - Developer onboarding guide with setup steps
- `decisions/.template.md` - ADR template (bilingual: Status/Context/Options/Decision/Consequences)
- `runbooks/.template.md` - Runbook template (bilingual: Overview/Procedure/Verification/Rollback)

## Dependencies
- All documents follow `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md`

## Rules
- Architecture figures follow the writing-style-guide `## Diagram Rules` (ADR-010): infographics built with the `aws-infographic` skill, one English and one Korean version, or Mermaid flowcharts where the skill is unavailable; the figures in `architecture.md` and the README are infographics, rebuilt from `images/architecture/` when components change (edit `figtext.py`, both languages); no ASCII box diagrams
- Runbook commands must be copy-paste ready
- Bilingual docs use `# English` / `# 한국어` sections with identical structure and information
- No emojis; code blocks must specify language; English imperative, Korean 경어체
