---
description: Build and publish the plugin to the marketplace
allowed-tools: Read, Bash(git tag:*), Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git describe:*), Bash(git remote:*), Bash(git pull:*), Bash(git revert:*), Bash(python3 -c:*), Glob, Grep
---

# Deploy

Build and publish the project-init plugin.

## Step 1: Pre-Deploy Checks

1. Verify working tree is clean: `git status`
2. Verify current branch (warn if not main): `git branch --show-current`
3. Run `/test-all` to validate plugin structure
4. Check if a deployment runbook exists: `ls docs/runbooks/deploy-*.md`

## Step 2: Version Validation

Both version files MUST match. Read and compare:

```bash
python3 -c "
import json
m = json.load(open('.claude-plugin/marketplace.json'))
p = json.load(open('plugins/project-init/.claude-plugin/plugin.json'))
mv = m['metadata']['version']
pv = p['version']
print(f'marketplace.json: {mv}')
print(f'plugin.json: {pv}')
if mv != pv:
    print(f'ERROR: Version mismatch! Fix before deploying.')
    exit(1)
print('Versions match.')
"
```

If versions don't match, update both files to the same version before proceeding.

## Step 3: Changelog Verification

1. Read `CHANGELOG.md`
2. Verify the current version has an entry with today's date
3. If missing, ask the user to update CHANGELOG.md before deploying

## Step 4: Tag and Push

```bash
# Get current version
VERSION=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])")

# Check if tag already exists
git tag -l "v$VERSION"

# If tag doesn't exist, create it
git tag -a "v$VERSION" -m "Release v$VERSION"

# Push code and tags
git push origin main
git push origin "v$VERSION"
```

## Step 5: User Update Instructions

After pushing, display:

```
## Release v<VERSION> Published

### For existing users:
claude plugin marketplace update project-init
claude plugin install project-init@project-init
# Restart Claude Code session

### For new users:
git clone https://github.com/whchoi98/project-init.git
claude plugin marketplace add ./project-init
claude plugin install project-init
```

## Error Recovery

### If version validation fails (Step 2)
Update both files to the same version:
```bash
# Edit both files to matching version, then:
git add .claude-plugin/marketplace.json plugins/project-init/.claude-plugin/plugin.json
git commit -m "fix: sync marketplace and plugin versions to X.Y.Z"
```
Restart from Step 2.

### If push fails (Step 4)
```bash
# Check remote status
git remote -v
git fetch origin

# If rejected due to diverged history
git pull --rebase origin main
git push origin main
```

### If tag was created but push failed (Step 4)
```bash
# Delete the local tag and retry
VERSION=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])")
git tag -d "v$VERSION"
# Fix the issue, then recreate and push
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin main && git push origin "v$VERSION"
```

### If a bad release was published — full rollback
```bash
# Get the version to rollback
VERSION=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])")

# Delete remote and local tag
git push origin ":refs/tags/v$VERSION"
git tag -d "v$VERSION"

# Revert the release commit if needed
git revert HEAD
git push origin main
```

### If GitHub Push Protection blocks the push
Secrets detected in staged files. Review the flagged files, remove or rotate the secrets, then amend the commit:
```bash
git add <fixed-files>
git commit --amend --no-edit
git push origin main
```

## Step 6: Summary

Display:
- Version deployed
- Git tag created
- Files changed since last tag: `git log $(git describe --tags --abbrev=0 HEAD^)..HEAD --oneline`
- Reminder: Update GitHub Releases page if needed
