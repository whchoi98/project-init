---
description: Initialize a Claude Code project structure with CLAUDE.md, docs, hooks, and skills. Adapts to existing projects by detecting language/framework.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(git init:*), Bash(git add:*), Bash(git commit:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Glob, Grep
argument-hint: Optional project directory path (defaults to current directory)
---

# Initialize Claude Code Project Structure

Set up a complete Claude Code project structure in the target directory. Adapts to existing projects by detecting language, framework, and directory layout.

## Step 1: Determine Target Directory

Target: $ARGUMENTS

- If a path is provided, use it as the project root
- If empty, use the current working directory
- If the directory doesn't exist, create it

```bash
ls -la <target_dir> 2>/dev/null
```

## Step 2: Detect Existing Project

Scan for existing project files to determine if this is a new or existing project:

```bash
# Detect language/framework
ls package.json pyproject.toml go.mod Cargo.toml pom.xml build.gradle Gemfile composer.json 2>/dev/null

# Detect existing source directories
ls -d src/ app/ lib/ cmd/ pkg/ internal/ components/ pages/ routes/ 2>/dev/null

# Check dependency files for framework detection
cat package.json 2>/dev/null | head -30
cat pyproject.toml 2>/dev/null | head -30
```

**If existing project detected:**
- Do NOT create `src/api/` or `src/persistence/` if they don't match the project
- Instead, identify the actual source directories and create module `CLAUDE.md` files for each
- Adapt Tech Stack, Commands, and Conventions based on detected framework
- Warn the user before overwriting any existing files

**Project type detection rules:**

| File Found | Project Type | Source Dirs | Key Commands |
|-----------|-------------|-------------|--------------|
| `package.json` | Node.js | src/, app/, lib/, components/ | npm/yarn/pnpm |
| `pyproject.toml` / `requirements.txt` | Python | src/, app/, lib/ | pip, pytest, ruff |
| `go.mod` | Go | cmd/, pkg/, internal/ | go build, go test |
| `Cargo.toml` | Rust | src/ | cargo build, cargo test |
| `pom.xml` / `build.gradle` | Java/Kotlin | src/main/, src/test/ | mvn, gradle |
| None detected | New project | src/api/, src/persistence/ | (ask user) |

**If new project (no existing files):**
- Ask the user for project name, description, tech stack
- Create the default `src/api/` and `src/persistence/` structure

## Step 3: Create Directory Structure

Create directories based on detection results:

**Always create:**
```bash
mkdir -p docs/decisions
mkdir -p docs/runbooks
mkdir -p .claude/hooks
mkdir -p .claude/skills/code-review
mkdir -p .claude/skills/refactor
mkdir -p .claude/skills/release
mkdir -p .claude/skills/sync-docs
mkdir -p tools/scripts
mkdir -p tools/prompts
```

**For new projects only** (no existing source detected):
```bash
mkdir -p src/api
mkdir -p src/persistence
```

## Step 4: Generate CLAUDE.md

Read the template from [references/claude-md-template.md](../skills/project-scaffolder/references/claude-md-template.md).

**For existing projects:**
- Auto-fill Tech Stack from detected dependency files
- Auto-fill Project Structure from actual directory layout
- Auto-fill Key Commands from detected build system (package.json scripts, Makefile targets, etc.)
- Auto-fill Conventions from observed code patterns (linter configs, .editorconfig, etc.)

**For new projects:**
- Ask the user for project name, description, tech stack
- Fill in the template with user responses

Always include Auto-Sync Rules section.

## Step 5: Generate .claude/settings.json and Hook

Read [references/settings-json-template.md](../skills/project-scaffolder/references/settings-json-template.md) and create `.claude/settings.json`.

Read [references/hook-scripts.md](../skills/project-scaffolder/references/hook-scripts.md) and create `.claude/hooks/check-doc-sync.sh`. Make it executable:

```bash
chmod +x .claude/hooks/check-doc-sync.sh
```

**For existing projects**: Adapt `check-doc-sync.sh` to use the actual source directory path instead of hardcoded `src/`.

## Step 6: Generate Skills

Read [references/skills-templates.md](../skills/project-scaffolder/references/skills-templates.md) and create:
- `.claude/skills/code-review/SKILL.md`
- `.claude/skills/refactor/SKILL.md`
- `.claude/skills/release/SKILL.md`
- `.claude/skills/sync-docs/SKILL.md`

## Step 7: Generate Docs

Read [references/docs-templates.md](../skills/project-scaffolder/references/docs-templates.md) and create:
- `docs/architecture.md` - For existing projects, pre-fill Components section based on detected directories
- `docs/decisions/.template.md`
- `docs/runbooks/.template.md`

## Step 8: Generate Module CLAUDE.md Files

**For new projects:**
- `src/api/CLAUDE.md`
- `src/persistence/CLAUDE.md`

**For existing projects:**
- Scan all top-level source directories
- Create `CLAUDE.md` for each directory that doesn't have one
- Auto-fill module role based on directory name and contained files

## Step 9: Generate Supporting Files

Create (only if they don't already exist):
- `README.md` with project overview and structure
- `.gitignore` with patterns appropriate for the detected language
- `tools/scripts/.gitkeep`
- `tools/prompts/.gitkeep`

## Step 10: Initialize Git (Optional)

If `.git/` doesn't already exist, ask the user if they want to initialize:

```bash
git init
```

Create `.git/hooks/commit-msg` to auto-remove Co-Authored-By lines:

```bash
#!/bin/bash
sed -i '/^Co-Authored-By:.*/d' "$1"
```

```bash
chmod +x .git/hooks/commit-msg
```

Then stage and create initial commit:

```bash
git add -A
git commit -m "Initial project structure for Claude Code"
```

## Step 11: Summary

Display the created structure and explain the auto-sync mechanisms:

1. **CLAUDE.md Auto-Sync Rules** - Plan mode exit triggers doc updates
2. **Hook (check-doc-sync.sh)** - Write/Edit triggers missing doc detection
3. **Skill (/sync-docs)** - Manual full documentation sync
4. **Git Hook (commit-msg)** - Auto-remove Co-Authored-By lines

If existing project was detected, highlight what was adapted vs created fresh.
