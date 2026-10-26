#!/bin/bash
# SessionStart: print the plugin version and flag version drift across the files a release bumps.
# Claude Code already injects the branch, status, and recent commits, so this hook adds only
# what git does not show. Stdout reaches Claude's context. The event JSON on stdin is not needed
# and is never read. Registered with `2>/dev/null || true` (observational, ADR-004).
# tests/structure/test-plugin-structure.sh asserts the same versions, so drift also fails the suite.

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0

python3 - <<'PY'
import json
import re


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return ""


def json_version(path, *keys):
    try:
        value = json.loads(read(path))
        for key in keys:
            value = value[key]
        return str(value)
    except (ValueError, KeyError, IndexError, TypeError):
        return "missing"


def latest_release(section):
    match = re.search(r"^## \[(\d+\.\d+\.\d+)\]", section, re.M)
    return match.group(1) if match else "missing"


plugin = json_version("plugins/project-init/.claude-plugin/plugin.json", "version")
print("[project-init] plugin.json version: " + plugin)

badge = re.search(r"badge/version-(\d+\.\d+\.\d+)-", read("README.md"))
english, marker, korean = read("CHANGELOG.md").partition('<a id="korean"></a>')
others = [
    ("marketplace.json metadata.version", json_version(".claude-plugin/marketplace.json", "metadata", "version")),
    ("marketplace.json plugins[0].version", json_version(".claude-plugin/marketplace.json", "plugins", 0, "version")),
    ("README version badge", badge.group(1) if badge else "missing"),
    ("CHANGELOG English latest release", latest_release(english)),
    ("CHANGELOG Korean latest release", latest_release(korean) if marker else "missing"),
]
drift = ["%s=%s" % (name, value) for name, value in others if value != plugin]
if drift:
    print("[project-init] version drift (plugin.json=%s): %s. docs/runbooks/release.md lists the files a version bump updates."
          % (plugin, ", ".join(drift)))
PY
