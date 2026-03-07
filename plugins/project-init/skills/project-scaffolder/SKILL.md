---
name: project-scaffolder
description: Understand and apply Claude Code project structure patterns. Use when user asks about project organization, wants to add new modules, or needs guidance on where to place files in a Claude Code project.
tools: Read, Glob
user-invocable: false
---

# Project Scaffolder

Knowledge skill for Claude Code project structure patterns and conventions.

## Project Structure Pattern

A well-organized Claude Code project follows this structure:

```
project-root/
├── CLAUDE.md                      # Project memory and instructions for Claude
├── README.md                      # Project documentation
├── .gitignore
├── docs/
│   ├── architecture.md            # System architecture document
│   ├── decisions/                 # Architecture Decision Records (ADRs)
│   │   └── .template.md
│   └── runbooks/                  # Operational runbooks
│       └── .template.md
├── .claude/
│   ├── settings.json              # Permissions and hooks configuration
│   ├── hooks/
│   │   └── check-doc-sync.sh     # Documentation sync detection hook
│   └── skills/
│       ├── code-review/SKILL.md   # /code-review skill
│       ├── refactor/SKILL.md      # /refactor skill
│       ├── release/SKILL.md       # /release skill
│       └── sync-docs/SKILL.md     # /sync-docs skill
├── tools/
│   ├── scripts/                   # Utility scripts
│   └── prompts/                   # Reusable prompts
└── src/
    ├── api/
    │   └── CLAUDE.md              # API module context
    └── persistence/
        └── CLAUDE.md              # Persistence module context
```

## Key Principles

### CLAUDE.md Hierarchy
- **Root CLAUDE.md**: Project-wide context (overview, tech stack, conventions, commands)
- **Module CLAUDE.md**: Module-specific context (role, key files, rules)
- Keep each CLAUDE.md concise - it's part of the prompt context

### Auto-Sync Mechanisms
1. **CLAUDE.md Auto-Sync Rules**: Embedded in root CLAUDE.md, triggered after Plan mode
2. **PostToolUse Hook**: Detects missing module docs after Write/Edit operations
3. **Sync-docs Skill**: Manual full documentation synchronization
4. **Git commit-msg Hook**: Auto-removes Co-Authored-By lines

### When to Create New Module CLAUDE.md
- Any new directory under the source root (src/, app/, lib/, etc.) should have a `CLAUDE.md`
- Use `/add-module <path>` to create directory + CLAUDE.md + update architecture docs in one step
- Document: module role, key files, dependencies, and module-specific rules

### When to Create ADRs
- New technology/dependency added
- API design decisions
- Database schema changes
- Infrastructure changes
- Any decision with trade-offs worth recording

### ADR Numbering
- Find the highest number in `docs/decisions/ADR-*.md`
- Increment by 1
- Format: `ADR-NNN-concise-title.md`

### CLAUDE.md Quality Criteria

When evaluating or creating CLAUDE.md files, target these scores (total 100):

| Criterion | Max | What to check |
|-----------|-----|---------------|
| Commands/workflows | 20 | Build/test/deploy commands present and copy-paste ready? |
| Architecture clarity | 20 | Codebase structure understandable from this file alone? |
| Non-obvious patterns | 15 | Gotchas, quirks, and conventions documented? |
| Conciseness | 15 | No verbose explanations or obvious info? |
| Currency | 15 | Reflects current codebase state? |
| Actionability | 15 | Instructions are executable, not vague? |

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29)

### Existing Project Adaptation

When applying this structure to existing projects:
- Detect language/framework from dependency files (package.json, pyproject.toml, go.mod, etc.)
- Use existing source directories instead of creating src/api/ and src/persistence/
- Auto-fill Tech Stack, Commands, and Conventions from detected build system
- Create module CLAUDE.md for each existing source directory

## Reference Files

For detailed templates, see:
- [references/claude-md-template.md](references/claude-md-template.md) - CLAUDE.md template
- [references/settings-json-template.md](references/settings-json-template.md) - settings.json with hooks
- [references/skills-templates.md](references/skills-templates.md) - Skill definitions
- [references/docs-templates.md](references/docs-templates.md) - Architecture, ADR, Runbook templates
- [references/hook-scripts.md](references/hook-scripts.md) - Hook script implementations
