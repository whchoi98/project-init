# Sources

Every statement in the three architecture figures comes from this repository. No external source is used.

| Claim in a figure | Value | Source |
|---|---|---|
| Critical path | User, /init-project, Generate Structure, Install Hooks, 4-Layer Auto-Sync, Docs Updated | `README.md`, `## Architecture` |
| /init-project steps | detect, ask once, generate by tier, run checks | `plugins/project-init/commands/init-project.md` (Detection, Questions, Artifacts, Finish) |
| /init-project is user-invoked | `disable-model-invocation: true` | `plugins/project-init/commands/init-project.md` frontmatter |
| Existing files are kept | "Existing files win" | `plugins/project-init/commands/init-project.md`, `## Rules` |
| Tiers and their contents | Core always, Default unless unchecked, Optional only when checked | `docs/architecture.md`, `### Generated Project Layer`; ADR-009 decision 1 |
| Plugin parts | commands/, agents/ (doc-sync-checker), skills/project-scaffolder/, scripts/ | `docs/architecture.md`, `### Plugin Layer` |
| Command names | the file names under `plugins/project-init/commands/` | directory listing |
| A command file's shape | goal, inputs, rules, output contract, check, report | `docs/architecture.md`, `### Plugin Layer`; ADR-009 decision 4 |
| Scripts | `harness-check.sh` (score, hook contract), `check-bilingual.py` (bilingual structure) | `docs/architecture.md`, `### Plugin Layer` |
| Scripts decide, the model judges | score, hook-contract detection, bilingual structure in scripts; CLAUDE.md quality, real secret or sample, module CLAUDE.md need, recommended actions, translation fidelity with the model | ADR-009 decision 6 |
| 4-layer auto-sync | Auto-Sync Rules (guidance), PostToolUse hook (auto), /sync-docs (manual), commit-msg hook (auto) | `README.md`, `### Auto-Sync Mechanisms`; `docs/architecture.md`, Key Design Decisions |
| PostToolUse hook behavior | notes a module without a covering CLAUDE.md, once per session | `plugins/project-init/skills/project-scaffolder/references/hook-scripts.md`, check-doc-sync.sh |
| commit-msg hook behavior | removes Co-Authored-By lines | `plugins/project-init/skills/project-scaffolder/SKILL.md`, How the Pieces Fit |
| /sync-docs behavior | audits once, applies findings, runs the bilingual check; suggests ADRs and runbooks instead of writing them | `plugins/project-init/commands/sync-docs.md` |
| Gates block with exit 2 | secret-scan.sh | `docs/architecture.md`, `### Repository Harness Layer`; ADR-004, ADR-008 |

## Rebuild

The text of all three figures is in `figtext.py`, English and Korean; the layouts are `fig1.py`, `fig2.py`, and `fig3.py`. After a change, build with the `aws-infographic` skill's scripts, which the skill copies into this folder (they are git-ignored):

```bash
cd docs/images/architecture
uv run --no-project --with playwright==1.64.1 --with pillow python buildkit.py build \
  fig1_en:01-critical-path-en fig1_ko:01-critical-path-ko \
  fig2_en:02-full-architecture-en fig2_ko:02-full-architecture-ko \
  fig3_en:03-data-flow-en fig3_ko:03-data-flow-ko
```

The build must report 0 issues for every output. `README.md` and `docs/architecture.md` embed the `build/*_16x9_{light,dark}.png` files.
