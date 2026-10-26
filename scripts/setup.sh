#!/bin/bash
# Project setup script for new developers.
# Usage: bash scripts/setup.sh

set -e

echo "=== Project Setup ==="

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required"; exit 1; }

# This is a Claude Code plugin project - no language dependencies to install
echo "Project: project-init (Claude Code Plugin)"

# Setup environment
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "IMPORTANT: Edit .env with your actual values"
fi

# Setup Claude hooks
if [ -f ".claude/hooks/check-doc-sync.sh" ]; then
    chmod +x .claude/hooks/*.sh
    echo "Claude hooks configured"
fi

# Install the commit-msg hook. `git rev-parse` also finds a linked worktree, where .git is a file.
# A hook manager (core.hooksPath) makes install-hooks.sh print the line to add instead; setup goes on.
if git rev-parse --git-dir >/dev/null 2>&1 && [ -f "scripts/install-hooks.sh" ]; then
    bash scripts/install-hooks.sh || echo "WARNING: commit-msg hook not installed; see the message above"
fi

echo "=== Setup Complete ==="
echo "Next steps:"
echo "  1. Edit .env with your configuration (optional)"
echo "  2. Read CLAUDE.md for project conventions"
echo "  3. Read docs/onboarding.md for development workflow"
echo "  4. Register plugin: claude plugin marketplace add ./project-init"
echo "  5. Install plugin: claude plugin install project-init"
