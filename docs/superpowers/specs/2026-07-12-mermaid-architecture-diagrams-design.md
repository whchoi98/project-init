# Design: Mermaid Flowchart for Architecture Diagrams

Date: 2026-07-12
Status: Approved by user

## Goal

Replace the ASCII box-diagram convention with Mermaid flowchart for all architecture
flows and diagrams across generated documents, add an Architecture section to the
README template, and apply the new convention to this repository's own documents.

## Decisions (user-confirmed)

1. **Full replacement**: All architecture diagrams and flow diagrams use Mermaid
   flowchart. ASCII box diagrams (`┌─┐│└─┘▶▼`) are retired. GitHub renders Mermaid
   natively; text-based diagrams stay diff-reviewable and easy to regenerate.
2. **README gains an Architecture section**: A concise Mermaid flowchart of the
   critical flow plus a link to `docs/architecture.md`.
3. **Dogfooding**: This repository's `README.md` and `docs/architecture.md` are
   updated now, not deferred to the next `/sync-docs`.
4. **Version bump**: 2.1.0 → 2.2.0 in both manifests, with a bilingual CHANGELOG
   entry, following the release runbook and reconciling known drift points
   (README badge, structure-tree version labels, counts).

## Conventions (to be codified in writing-style-guide.md)

- Diagrams use fenced ```mermaid blocks with `flowchart`.
- Layered architecture diagrams: `flowchart TB` with one `subgraph` per layer.
- Data flow / critical path: `flowchart LR`.
- Node labels stay in English in both language sections (diagrams are duplicated
  identically per the existing bilingual rules; only surrounding prose is translated).
- No emojis in diagrams (existing prohibition applies).

## Files to change

| Group | File | Change |
|-------|------|--------|
| Rules | `plugins/project-init/skills/project-scaffolder/references/writing-style-guide.md` | Add "Diagram Rules" section |
| Rules | `docs/decisions/ADR-007-mermaid-architecture-diagrams.md` | New ADR recording ASCII → Mermaid |
| Templates | `.../references/docs-templates.md` | Replace ASCII generation rule and style guide with Mermaid flowchart style guide |
| Templates | `.../references/readme-template.md` | Add Architecture section |
| Commands | `plugins/project-init/commands/generate-readme.md` | Document Architecture section rules |
| Commands | `plugins/project-init/commands/sync-docs.md` | Phase 4: regenerate Mermaid flowchart instead of ASCII |
| Commands | `plugins/project-init/commands/init-project.md` | Replace ASCII diagram references if present |
| Docs | `plugins/project-init/CLAUDE.md` | Note convention change |
| Docs | root `CLAUDE.md` | Add ADR-007 to Current ADRs |
| Repo docs | `README.md` | Architecture section (EN/KR) with Mermaid flowchart |
| Repo docs | `docs/architecture.md` | Replace ASCII diagrams with Mermaid |
| Release | `plugin.json`, `marketplace.json`, `CHANGELOG.md` | 2.2.0 bump + entry |

## Verification

- `bash tests/run-all.sh` passes (baseline 169 tests).
- No ASCII box-drawing characters remain in templates/commands/docs
  (`grep -r '┌\|▶' ...`), excluding historical ADR/CHANGELOG entries that describe
  the old convention.
- Bilingual sync checklist: diagrams identical in both language sections.
- Version consistency: manifests, README badge, structure-tree labels, CHANGELOG
  top entry all read 2.2.0.
