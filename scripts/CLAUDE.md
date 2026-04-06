# Scripts Module

## Role
Operational scripts for project setup, Git hook installation, and developer tooling.

## Key Files
- `setup.sh` - One-command project setup for new developers (env, hooks, dependencies)
- `install-hooks.sh` - Installs Git commit-msg hook (Co-Authored-By removal)

## Rules
- All scripts must use `set -e` for fail-fast behavior
- Scripts must validate prerequisites before executing (git, python3, etc.)
- Scripts must be executable (`chmod +x`)
- Use `#!/bin/bash` shebang for portability
