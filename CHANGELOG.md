# Changelog

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a> <a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.0] - 2026-11-03

### Added

- Add `plugins/project-init/scripts/harness-check.sh` (`bash harness-check.sh [--contract-only] [--] [PROJECT_DIR]`), which runs the deterministic harness checks and prints one `<STATUS> <id> <earned>/<max> <detail>` line per check, a `CATEGORY` line per category, and a final `TOTAL <earned>/<max> <percent>%`; `--contract-only` runs only the hook-contract checks (pre-v2.3 hooks, an unparsable `settings.json`, a registered gate whose script is missing or whose exit code its registration overrides, and the commit-scope and module-coverage markers) and exits 1 on any FAIL or WARN
- Add checks to `harness-check.sh` for what keeps a hook from working: `disableAllHooks` in project settings, a `python3` on PATH that does not run, a `VERIFY_CMD` that cannot run here or a verify-on-stop gate outside a git work tree, a commit-msg hook that uses a GNU-only `sed -i` or is missing under a `core.hooksPath` hook manager, literal credentials in `.mcp.json` headers, and a `.gitignore` whose `.env` line a later negation undoes
- Add `plugins/project-init/scripts/check-bilingual.py` (`python3 check-bilingual.py FILE...`), which checks the ADR-001/002 badges and anchors, heading, fence, and table parity between the halves, identical Mermaid blocks, fence language tags, emoji, and CHANGELOG release headings, and prints `FILE:LINE: message` (exit 0 clean, 1 issues, 2 usage or read error)
- Add the Optional `verify-on-stop.sh` Stop gate to `hook-scripts.md` and its registration, with a 120-second `timeout`, to `settings-json-template.md`: when a turn ends on a working tree that changed since the gate's last run, it runs the project's fast check (`VERIFY_CMD`, filled by `/init-project`) and hands failures back to Claude with exit 2; it records every run's tree fingerprint, green or red, so an unchanged tree is skipped and a continued turn (`stop_hook_active`) runs the check again only after Claude changed something, and it checks the linked worktree Claude works in when that belongs to the same repository
- Add `## Optional: Team Effort Cap` to `settings-json-template.md`, documenting `maxEffortLevel` as an optional team-wide effort cap (Claude Code 2.1.267 or later)
- Add `## Optional: Subagent Model` to `settings-json-template.md`, documenting `CLAUDE_CODE_SUBAGENT_MODEL` (for example `haiku` for Haiku 5.5) as an optional team-wide subagent model, with its precedence and the Haiku 4.5 resolution on Amazon Bedrock, Google Cloud, and Microsoft Foundry
- Add `Read(./.env)` and `Read(./.env.*)` deny rules to the generated `settings.json`, with a `Read(!.env.example)` carve-out so Claude can still maintain the template, and add `rm -fr` and `git push -f` deny rules to both the generated and this repository's `settings.json`
- Add the `project-init:commit-scope` marker to the header of `secret-scan.sh` (repository and template), so `/health-check` and `/migrate-hooks` can tell a copy that predates the commit-scope fix
- Add the `project-init:module-coverage` marker to the header of `check-doc-sync.sh` (repository and template): `harness-check.sh --contract-only` reports a copy without it as `WARN doc-sync-scope`, and `/migrate-hooks` regenerates it, carrying `SOURCE_ROOTS` over
- Add single-source sections `## CLAUDE.md Quality Criteria`, `## CLAUDE.md Anti-Patterns` (with the secrets greps), and `## Module CLAUDE.md Coverage` (with the one fallback list of source roots) to the project-scaffolder `SKILL.md`, which `/health-check`, `/sync-docs`, `/add-module`, and the doc-sync-checker agent cite instead of keeping their own copies
- Add `## INDEX.md` and `## Root CLAUDE.md Block` sections to `reference-doc-template.md` as the single source for the `docs/reference/INDEX.md` and root CLAUDE.md block formats, and a `declined` status for a detected layer the user deselected, so `/sync-docs` and the doc-sync-checker agent note it instead of recommending it on every run
- Add length rules to the shared `writing-style-guide.md`: write what the reader needs, omit an optional section whose condition is not met, and do not restate the introduction or summarize at the end
- Add a Stop hook to this repository (`.claude/hooks/test-gate.sh`, registered with a 180-second `timeout`) that runs `bash tests/run-all.sh` when a turn ends on a working tree that changed since the gate's last run and returns the failure summary to Claude with exit 2 (`TEST_GATE_CMD` overrides the command); like verify-on-stop, it skips a tree identical to its last run, green or red, and tests the linked worktree Claude works in
- Add structure tests that fail when `marketplace.json` `plugins[0].version`, the README version badge, the README structure-tree version labels, or the latest CHANGELOG release in either language differs from `plugin.json`, and when a template copy of a repository hook, test, or fixture drifts from the file
- Add `tests/structure/test-prompt-contracts.sh`, which fails when plugin prompts contradict each other: the module coverage rule and its fallback source roots, the module CLAUDE.md headings, the runbook name the generated `/deploy` offers, the SKILL.md secrets greps, AskUserQuestion in the commands that ask first, the pre-existing-content exception, the INDEX.md `declined` status, and a runbook's `Last verified` line
- Add ADR-009 recording the Opus 5.5 harness alignment (tiers, model and effort policy, report-all reviewers, deterministic scripts, Stop gates, commit-scoped secret gate)

### Changed

- **BREAKING:** Generate by tier in `/init-project`: Core always, Default (`/test-all`, `/review` with the code-reviewer agent) unless the user unchecks it, and Optional (`/deploy`, security-auditor, the code-review, refactor, and release skills, and the session-context, notify, and verify-on-stop hooks) only when the user checks it, chosen in the same up-front question round as the reference layers (ADR-009). Checking the code-review skill replaces `/review` and the code-reviewer agent, so the project keeps one review path; session-context is generated only when there is a local-environment fact to report, and verify-on-stop only in a git repository (otherwise each goes under Skipped)
- Rewrite `/init-project` as a goal, rules, detection, one question round, an artifacts table, and ordered finish steps: it checks an existing `.claude/` with `harness-check.sh --contract-only` and recommends `/project-init:migrate-hooks` first when the hooks predate the current contract, matches layer signals at any depth, never overwrites an existing file (logged as `(existing, kept)`), merges missing deny rules and hook registrations into an existing `settings.json` (a new one also gets the detected test command and fast check as `permissions.allow` rules), runs the generated tests, the hook-contract check, and the bilingual check on every bilingual file it wrote before its summary, reports issues in content that existed before the run instead of rewriting it, commits only the generated paths in a new repository, never commits in an existing one, and can be started only by the user
- Ask the up-front questions of `/init-project`, `/sync-docs`, `/generate-readme`, `/generate-changelog`, `/add-adr`, `/add-runbook`, `/add-module`, and `/add-reference-doc` with the AskUserQuestion tool when it is available, because its answers arrive in the same turn and keep the command's `allowed-tools` pre-approval, while a chat reply starts a new turn without it; long checklists are split over several calls (up to four questions of four options each, with `multiSelect` and a free-text answer), and without the tool the command asks in one chat message
- **BREAKING:** Report the `/health-check` score as the `harness-check.sh` percentage of applicable points (A >= 80%, B >= 60%, C >= 40%, D >= 20%, F < 20%) instead of a hand-summed 0-200 score whose items added up to 195, across Core files, Hooks, Hook contract, Harness components, Compatibility, Documentation, Security, and Tests, with a CRITICAL, NEEDS ATTENTION, or HEALTHY status, a separate CLAUDE.md quality score out of 100, and one test run
- Make module CLAUDE.md coverage a report instead of a quota: a source root's own CLAUDE.md (for example `src/CLAUDE.md`) covers every module below it, `harness-check.sh` prints `docs-modules` as INFO worth no points, and `/health-check` has the model judge each uncovered module and recommend `/add-module` only when the module has rules, invariants, or gotchas its code does not show
- Make `/health-check` say which grade it means (the harness grade or the CLAUDE.md grade), report NEEDS ATTENTION when a gate may not run (a `secret-scan-scope`, `doc-sync-scope`, gate registration, `hook-python3`, or `hook-disable-all` warning) or the CLAUDE.md grade is D or F, and give an action for every FAIL, WARN, and CLAUDE.md deduction, marking the minor ones instead of leaving them out
- Replace the `/health-check` "Skills: X/4 installed" category with Harness components (skills, commands, and agents load and do not duplicate each other, a plugin command, or a bundled command) and add Compatibility notes for skill frontmatter, unsupported keys, old model IDs, alias pins, a project-level `effortLevel`, and undocumented hook events
- Detect migrations in `/migrate-hooks` with `harness-check.sh --contract-only` and a check for relative registrations, regenerate a `secret-scan.sh` without the commit-scope marker (carrying custom `PATTERNS` and `SKIP_PATTERNS` over, but not the old defaults the template replaces) and a `check-doc-sync.sh` without the module-coverage marker (carrying `SOURCE_ROOTS` over), fix an unparsable `settings.json` before rewriting any registration, write a registered gate whose script is missing, rewrite every project-init hook registration to the `$CLAUDE_PROJECT_DIR` form, drop `model` from converted agents, keep the backup out of git with its own `.gitignore`, probe the regenerated gate with a staged token in a scratch repository, restore the backup when the post-migration checks fail, and allow only the user to start it
- Split `settings-json-template.md` into a Core template (secret-scan and check-doc-sync) and per-hook Optional registration blocks, write permission rules in the space form (`Bash(rm -rf *)`), and set neither `model` nor `effortLevel` in generated settings
- Make `secret-scan.sh` (repository and template) block with a message that tells Claude to move the secret to `.env` or to report the file and pattern as a false positive; skip files by path (`*secret-scan.sh`, `tests/hooks/test-secret-patterns.sh`, `tests/fixtures/secret-samples.txt`, `tests/fixtures/false-positives.txt`, `*.md`, `.env.example`, lock files), also relative to the project when it is a subdirectory of its repository, while still scanning every CLAUDE.md and every other file under `tests/fixtures/`; let a commit it cannot scan (python3 missing or not running, a failed scan, a repository it cannot find) through with a warning to the user (`systemMessage`) and to Claude (`additionalContext`) instead of a stderr line neither sees; and read the staged content with one `git cat-file --batch` instead of one `git show` per file
- Make the `check-doc-sync.sh` template name the first-level module directory, remind once per session, stop checking for ADR and runbook files, build its JSON with `json.dumps`, default `SOURCE_ROOTS` to `src app lib`, and check an edit in a linked worktree of the same repository against that worktree
- Make the `session-context.sh` template Optional and limit it to pinned-runtime mismatches (`.nvmrc`, `.python-version`, read from the first version line) and services the tests need that are not running, printing nothing otherwise, and make the `notify.sh` template Optional with a `json.dumps` payload of `notification_type` and `message` sent in the background with a 10-second timeout
- Print the plugin version and any version drift across the manifests, README badge, and CHANGELOG from this repository's SessionStart hook instead of git details that Claude Code already injects, and require only a CLAUDE.md at each plugin root in this repository's `check-doc-sync.sh`, which also checks an edit in a linked worktree against that worktree
- Omit `model` from the generated code-reviewer (Default) and security-auditor (Optional) agents so they inherit the session model and follow `CLAUDE_CODE_SUBAGENT_MODEL`, list plain tool names, and report every finding with severity and confidence instead of only findings scored 75 or above
- Remove the `model: opus` pin from the doc-sync-checker agent, set `effort: medium`, list plain tool names (`Bash` instead of the undocumented `Bash(find:*)` specifiers; the prompt keeps it read-only), tag every finding with severity and confidence (a section whose absence only lowers the score is reported as `score only` instead of dropped), report only uncovered first-level modules, score CLAUDE.md files with the SKILL.md rubric and secrets greps, and add an `### Implementation References` report section in the line formats `/sync-docs` consumes
- Restructure `/sync-docs` as audit once, apply, check, report: it audits inline for roughly ten or fewer CLAUDE.md and documentation files and otherwise runs the doc-sync-checker agent once with a single brief, applies the findings per document type without re-auditing (leaving `score only` findings unapplied), suggests ADRs and runbooks instead of writing them, runs `check-bilingual.py` on what it wrote, and adds Implementation References, Runbooks, and Bilingual Check sections to its report
- Rewrite `/add-adr`, `/add-runbook`, `/add-module`, `/add-reference-doc`, `/generate-readme`, and `/generate-changelog` as goal, inputs, rules, output contract, check, and report: they read the project's `docs/decisions/.template.md` or `docs/runbooks/.template.md` first, ask once only for what the repository cannot answer, leave TODO markers instead of inventing options or commands (`TODO(verify)` in runbooks), and run `check-bilingual.py` instead of a prose checklist
- Make `/generate-changelog` refuse to release a version that already exists, end its report with the `git tag -a` command to run, ask whether to add a Korean half to a CHANGELOG that has none, and report checker issues in released sections instead of rewriting them, and make `/add-reference-doc` ask once, before writing, whether to overwrite, skip, or abort for existing layer files
- Add YAML frontmatter (`name`, `description`) to every generated SKILL.md, give the generated `/test-all` `effort: low` with a report-only contract, and make the generated `/review` include untracked files, delegate multi-file changes to the code-reviewer agent, and report every finding
- Make the generated `/deploy` Optional and user-invoked only: it follows `docs/runbooks/deploy-*.md`, runs only the commands the runbook lists, and refuses to deploy when no runbook exists, offering `/add-runbook deploy-<environment>` (`deploy-production` when no environment was given)
- Reduce the Optional code-review, refactor, and release skills to project-specific facts, with `disable-model-invocation: true` on release
- Revise the CLAUDE.md anti-pattern deductions in `SKILL.md` (restated code or config, volatile specifics such as hardcoded counts, emphasis inflation or rules without reasons, thinking or verification scaffolding, sections that fail the prune test) and drop the "Over 500 lines", "No test guidance", and "No error patterns" deductions; line count is informational only
- Write the generated root CLAUDE.md Auto-Sync Rules as guidance ("Claude applies these while working; nothing runs automatically"), limit ADRs to decisions that are expensive to reverse, add a "Verify a change" Key Commands line, and reduce the module CLAUDE.md template to Role, Invariants and gotchas, and Entry point, written only for modules with rules the code does not show
- Generate `.mcp.json` as `{"mcpServers": {}}` and suggest `claude mcp add --scope project` for detected integrations, with `${VAR}` and `${VAR:-default}` shown for server entries
- Add `.claude/worktrees/` to the generated `.gitignore`, and append it to an existing one, so `git add` and the commit-scope secret scan skip Claude Code's linked worktrees
- Make the README template's Contributing section depend on the repository (a CONTRIBUTING.md or private repository gets the real flow, a public GitHub repository gets the fork flow), link the version badge to `CHANGELOG.md`, and translate the Korean headings of the architecture template
- Make the generated hook tests check the stdin contract, exit 2, gate registration without `|| true`, `$CLAUDE_PROJECT_DIR` registration, chained commits, `commit -am`, a staged rename, a quoted `git -c` value, CLAUDE.md and `tests/fixtures/` scanning, the warning when python3 is missing, linked worktrees, and the commit-msg hook, and run Optional-hook tests only when the hook exists; the generated secret-pattern tests read the hook's `PATTERNS` and match with python3 `re`
- Make this repository's `/deploy` user-invoked only, make `/review` review everything since `HEAD` (staged and unstaged) plus untracked files, run the test suite first, and report every issue with severity and confirmed or suspected, and make `/test-all` fix failures at their cause and report what it changed
- Document the command-writing rules in `plugins/project-init/CLAUDE.md` and `CONTRIBUTING.md`: a brief with explicit output contracts for smaller consumer models, the model and effort policy, `${CLAUDE_PLUGIN_ROOT}` references, AskUserQuestion for up-front questions, and `disable-model-invocation: true` for anything that releases, deploys, pushes, or rewrites many files or a user's harness, such as `/init-project` and `/migrate-hooks`
- Replace this repository's `docs/decisions/.template.md` and `docs/runbooks/.template.md` with the bilingual templates from `docs-templates.md`
- Mark ADR-008 as extended by ADR-009, which supersedes its decision 5 for the generated defaults
- Align the plugin rules, ADR-009, the README, and CONTRIBUTING with the Claude 5.5 family: Opus 5.5, Sonnet 5.5, and Haiku 5.5 all default to `medium` effort, the `sonnet` and `haiku` aliases still resolve to 4.5 models on Amazon Bedrock, Google Cloud, and Microsoft Foundry, and the README lists the minimum Claude Code version for each model
- Ask the generated CLAUDE.md's verify command to run before a change is reported done (a syntax-only check or a command that failed to start does not count), and have the generated `/test-all` report a suite that could not start as not run, because Sonnet 5.5 and Haiku 5.5 at low or medium effort sometimes report a change done without a check
- Flag pins to the superseded `claude-opus-5`, `claude-sonnet-5`, and `claude-fable-5` IDs in the `harness-check.sh` `compat-model-ids` check

### Removed

- Remove the sync-docs skill template, which duplicated `/project-init:sync-docs`, and the `tools/prompts/` directory from generated projects
- Remove placeholder module CLAUDE.md files (including `tests/unit/` and `tests/integration/`) and the API and persistence module CLAUDE.md templates
- Remove the Error Recovery playbooks from the generated `/deploy`, `/review`, and `/test-all`, and the confidence rubric from the code-review skill
- Remove the MCP server package examples that could not be verified from `mcp-json-template.md`, and the Minimal template and default Notification registration from `settings-json-template.md`
- Remove the unused `deploy.sh` and `seed-db.sh` templates from `scripts-templates.md`, which `/init-project` never generated

### Fixed

- Fix `secret-scan.sh` letting `git add . && git commit`, `git commit -am`, `git commit -m <msg> <path>`, `git -C <dir> commit`, and `git -c k=v commit` through unscanned: it now scans what the commit will contain (staged files from the index, modified tracked files for `-a`, `--all`, or a pathspec, and untracked files when the command line also runs `git add` or `git stage`, including an ignored file named by `git add -f`)
- Fix `secret-scan.sh` letting renamed files and type changes (a symlink replaced by a file) through unscanned, because its file list used `--diff-filter=ACM`; only deletions are left out now
- Fix `secret-scan.sh` missing commits whose git options carry quoted or spaced values (`git -c user.name="Claude Code" commit`, `git -C "my repo" commit`, `git --git-dir .git commit`) or follow a `cd` or `pushd` on the same line, and a `;`, `&`, or `|` inside a quoted commit message cutting off later arguments such as `-a`
- Fix `secret-scan.sh` missing current key formats: Anthropic keys that contain `_`, OpenAI project, service-account, and admin keys (`sk-proj-`, `sk-svcacct-`, `sk-admin-`), PEM and OpenSSH private keys, and quoted `password`, `secret`, and `api_key` values in another case or as JSON keys; references such as `${VAR}`, `{{ ... }}`, `%(name)s`, and `<placeholder>` stay unflagged, a quoted local default such as `POSTGRES_PASSWORD: "postgres"` now blocks, and `harness-check.sh` detects at least the same patterns
- Fix `secret-scan.sh` skipping files whose names contain spaces, quotes, tabs, or newlines; file lists are NUL-separated now
- Fix `secret-scan.sh` matching, which used `grep -P` (missing on macOS) and an AWS secret access key pattern whose variable-width lookbehind failed silently and never matched; patterns now match with python3 `re`, and the AWS pattern covers ini, `.env`, and JSON forms
- Fix `secret-scan.sh` blocking commits of its own pattern definitions and of the secret-pattern tests
- Fix `secret-scan.sh` letting a commit with a glob pathspec (`git commit -m x '*.py'` or an unquoted `*.py`) through unscanned, and skipping every pathspec of a commit when one of them named a path outside the repository: glob pathspecs are scanned, and each pathspec is resolved on its own
- Fix `secret-scan.sh` missing an ignored file forced in with `git -C <dir> add -f` or after a `cd` that the line undoes before the commit: the forced path is resolved from the directory the `git add` runs in
- Fix `secret-scan.sh` taking a `cd` option as the target directory (`cd -P dir`, `cd -L dir`, `cd -- dir`), which scanned the wrong repository or none and let the commit through without a warning
- Fix `secret-scan.sh` missing PGP private key blocks (`-----BEGIN PGP PRIVATE KEY BLOCK-----`)
- Fix gate hooks opening silently after Claude changes into a subdirectory, where a relative `bash .claude/hooks/<name>.sh` registration exits 127 (non-blocking): every registration in the generated `settings.json` and in this repository now uses `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh`
- Fix the commit-msg hook that `scripts/install-hooks.sh` writes (repository and template) aborting every commit on macOS, where BSD sed rejects `sed -i` without a backup suffix: it now runs `sed -i.bak ... && rm -f "$1.bak"` and exits 0
- Fix `scripts/install-hooks.sh` (repository and template) failing in a linked worktree, where `.git` is a file, writing a hook git never runs when `core.hooksPath` points at a hook manager such as husky, and overwriting a different commit-msg hook: it installs where `git rev-parse --git-path hooks` points, and in the last two cases changes nothing, prints the line to add, and exits 1, which `scripts/setup.sh` reports and continues past
- Fix the commit-msg hook that `scripts/install-hooks.sh` writes (repository and template) aborting every commit where `/bin/bash` does not exist, such as NixOS: it starts with `#!/bin/sh`; and make `install-hooks.sh` replace only a hook it installed itself, so a different hook that mentions Co-authored-by (for example one that adds the trailer) is left unchanged and the script prints the line to add
- Fix `tests/run-all.sh` (repository and template) breaking when the project path contains a space, losing the rest of the file list to a test that reads stdin, reporting a run that a sourced file ended early as green, and failing `assert_contains` at random under `pipefail`
- Fix the hook tests (`tests/hooks/test-hooks.sh`, repository and template) stopping the whole `tests/run-all.sh` run at random with exit 141: a registration lookup closed its pipe early, and under `set -euo pipefail` the SIGPIPE ended the run
- Fix this repository's Stop gate (`test-gate.sh`) and the Optional `verify-on-stop.sh` template skipping a tree silently after Claude Code killed a run at the hook `timeout`: the tree counted as checked, so later turns ended without a result; a killed run is now reported once
- Fix the generated `tests/run-all.sh` sourcing a project's existing `test-*.sh` files (for example under `tests/e2e/`); it sources only the directories in `TEST_DIRS`
- Fix the generated structure tests comparing CHANGELOG with a version file in every project: the block is enabled only when the project has a version file, and a mismatch in content that predates `/init-project` is reported instead of fixed by adding a release or bumping a version
- Fix plugin commands and agents referencing templates by relative paths (`skills/project-scaffolder/...`, `plugins/project-init/...`, `../skills/...`) that do not resolve in a consumer project: they now use `${CLAUDE_PLUGIN_ROOT}` and stop when a template cannot be read
- Fix `/health-check` and `/migrate-hooks` flagging freshly generated v2.3+ hooks as `STALE CONTRACT`, because their `$EVENT`/`$MESSAGE` grep matched `$MESSAGES` in `check-doc-sync.sh` and local variables in `notify.sh`
- Fix generated reference docs and `docs/reference/INDEX.md` using Markdown badges and `## English` headings that ADR-002 rejects: they now use the HTML badge pair, `# English` and `# 한국어`, and `---` separators, and INDEX.md gets a Korean half
- Fix `/init-project` writing a README language toggle that linked `#한국어` instead of `#korean` and omitting the Architecture section, by generating README, CHANGELOG, and architecture from the same templates as the dedicated commands
- Fix `/sync-docs` creating a CLAUDE.md for every directory under a source root; it now follows the SKILL.md coverage rule
- Fix the broken fence in `agents-templates.md` that pulled the security-auditor section into a code block, and the nested fences in the API reference template that cut it short when extracted
- Fix generated SKILL.md files having no YAML frontmatter, and remove the unsupported `tools` field from the project-scaffolder skill's frontmatter
- Fix `changelog-template.md` using a symmetric-difference `...` range for `git log` and a release date format that was not YYYY-MM-DD
- Fix the architecture template linking runbooks that may not exist; it now links only runbooks present in `docs/runbooks/`
- Fix the `notify.sh` template telling users to set the webhook in `.env`, which the hook never reads (it reads `CLAUDE_NOTIFY_WEBHOOK` from the environment); the `.env.example` template and this repository's `.env.example` no longer list it
- Fix `/add-runbook` writing today's date as `Last verified` in a runbook that nobody has run yet: it writes `not yet run (written <date>)`, and a date only when the user says they ran the procedure
- Fix the security-auditor template running `pip audit` instead of `pip-audit`, and add `govulncheck ./...` for Go projects
- Fix the doc-sync-checker agent keeping its own secret grep, which matched words such as `task-`: it now runs the SKILL.md secrets greps, whose token patterns skip kebab-case words; and fix this repository's `check-doc-sync.sh` asking for a CLAUDE.md inside plugin subdirectories and building JSON that broke on a quote in the path

## [2.4.0] - 2026-09-13

### Added

- New command `/migrate-hooks [--dry-run]`: backs up `.claude/hooks/`, `settings.json`, and `.claude/agents/`, regenerates pre-v2.3 hook scripts from the current templates (preserving custom `PATTERNS` and `SOURCE_ROOTS`), rewrites hook command strings, converts `.yml` agents to Markdown subagents, and verifies with sample stdin events
- `/health-check` Step 2.5 detects the pre-v2.3 hook contract (`$TOOL_INPUT_PATH` in `settings.json`, `secret-scan.sh` wrapped in `|| true`, hooks not reading `tool_input`, `.yml` agents), marks affected hooks `STALE CONTRACT`, and recommends `/migrate-hooks`

## [2.3.0] - 2026-09-13

### Changed

- Hook templates (`hook-scripts.md`, `settings-json-template.md`) now follow the Claude Code hook contract: event JSON is read from stdin (`tool_input.file_path`, `tool_input.command`, `message`), `secret-scan.sh` gates only `git commit` and blocks with exit 2, `check-doc-sync.sh` returns reminders as `hookSpecificOutput.additionalContext`, and the gate hook is registered without `|| true`
- Agent templates (`agents-templates.md`) generate `.claude/agents/*.md` with YAML frontmatter and a Markdown system prompt; `/init-project` Step 8 and the README trees updated accordingly
- Repository harness right-sized for frontier models (ADR-008): generic skills (code-review, refactor, release, sync-docs), unloaded `.yml` agents, and the unused Notification hook removed; `/review`, `/test-all`, `/deploy` reduced to repo-specific checks; hardcoded test and file counts removed from CLAUDE.md, runbooks, and tests

### Fixed

- Generated PostToolUse and Notification hooks silently did nothing because they relied on non-existent `$TOOL_INPUT_PATH` / `$EVENT` / `$MESSAGE` environment variables
- Generated `secret-scan.sh` could never block a commit: it was wrapped in `|| true` and used exit 1, which Claude Code treats as non-blocking
- Generated `.claude/agents/*.yml` files were never loaded by Claude Code (subagents must be `.md`)

## [2.2.0] - 2026-07-12

### Added

- Architecture section in the README template (recommended, placed after Features) with a concise Mermaid flowchart and a link to `docs/architecture.md`
- Diagram Rules section in the shared `writing-style-guide.md`: all architecture flows use Mermaid flowchart (`flowchart TB` with per-layer subgraphs for full diagrams, `flowchart LR` for data flow), diagrams duplicated identically in both language sections
- ADR-007 recording the Mermaid flowchart decision

### Changed

- Replace ASCII box diagrams (`┌─┐│└─┘▶▼`) with Mermaid flowcharts across `docs-templates.md`, `/init-project`, `/sync-docs` (Phase 4), and the `doc-sync-checker` agent; `/sync-docs` converts legacy ASCII diagrams on its next run
- `/generate-readme` detects `docs/architecture.md` and derives the README Architecture section's flowchart from its Data Flow Summary
- Repository `README.md` and `docs/architecture.md` migrated to Mermaid flowcharts

## [2.1.0] - 2026-05-19

### Added

- Implementation reference docs feature — `/init-project` Step 4.5 detects up to 8 layers (infrastructure, data, api, iac, frontend, ui, security, agent-llm) and generates skeletons under `docs/reference/`
- New command `/add-reference-doc <layer>` for incremental layer additions
- Auto-managed `docs/reference/INDEX.md` and `## Implementation References` block in root CLAUDE.md (between `<!-- AUTO-MANAGED:* -->` markers)
- New plugin template: `skills/project-scaffolder/references/reference-doc-template.md`
- `writing-style-guide.md` shared reference template for consistent style and bilingual rules across all document types
- Bilingual (EN/KR) structure for ADR templates with language toggle and translated section headings
- Bilingual (EN/KR) structure for Runbook templates with language toggle and translated section headings
- Bilingual output validation step in `/add-adr` (Step 8) and `/add-runbook` (Step 7)
- `/generate-readme` command for standalone bilingual (EN/KR) README.md generation with auto-detection and shields.io badges
- `/generate-changelog` command for standalone bilingual (EN/KR) CHANGELOG.md generation following Keep a Changelog convention
- `readme-template.md` and `changelog-template.md` reference templates for README/CHANGELOG generation rules
- Bilingual README.md generation integrated into `/init-project` (Step 12) with auto-detection from manifest files
- Bilingual CHANGELOG.md generation integrated into `/init-project` (Step 13) with git tag history analysis
- Full README.md sync in `/sync-docs` (Phase 7) with badge, section, and language sync validation
- CHANGELOG.md sync in `/sync-docs` (Phase 8) with git log analysis and unreleased entry categorization
- Automated test framework (`tests/run-all.sh`) with 114 tests across 3 categories: hooks (27), secret patterns (22), structure (65)
- Test fixture files for secret pattern validation (true positives and false positives)
- Error recovery sections in all generated commands: `/deploy` (5 scenarios including full rollback), `/review` (3 scenarios), `/test-all` (failure pattern table + multi-failure diagnosis)
- Structured output schemas for agents: `code-reviewer` (Verdict: PASS/WARN/FAIL, Summary table, Guideline field) and `security-auditor` (category breakdown, Recommendations section, Passed Checks checklist)
- Deny list in `settings.json` blocking dangerous commands: `rm -rf`, `git push --force`, `git reset --hard`, `eval`, `curl|bash`, `python3 -c import os`
- `tests-templates.md` reference template for test framework generation by `/init-project`
- Module `CLAUDE.md` files for `tests/`, `docs/`, `scripts/` directories
- Harness Engineering section in README explaining the plugin as a harness automation tool
- Recommended Workflow section in README: brainstorm → plan → implement → /init-project → /sync-docs

### Changed

- `/sync-docs` Phase 1 extended with a reference block: detects missing layer docs, validates Code Pointers, auto-corrects INDEX drift
- `doc-sync-checker` agent extended with reference-doc validation
- **BREAKING:** `/init-project` now generates 17 steps (was 15), adding bilingual README.md (Step 12) and CHANGELOG.md (Step 13) generation
- `/sync-docs` expanded to 11 phases (was 9), adding shared style guide read (Phase 0), README.md sync (Phase 8), and CHANGELOG.md sync (Phase 9)
- All document generation commands (`/generate-readme`, `/generate-changelog`, `/add-adr`, `/add-runbook`, `/sync-docs`) now reference shared `writing-style-guide.md`
- `/add-adr` generates bilingual ADR with English and Korean sections
- `/add-runbook` generates bilingual Runbook with English and Korean sections
- Reference templates expanded to 12 (was 9) with writing-style-guide.md, readme-template.md, and changelog-template.md
- Secret scan patterns hardened: replaced broad base64 pattern with context-aware AWS Secret Key detection; added Stripe, Google, Azure, GitHub token patterns
- Tool scoping hardened: `Bash(python3:*)` → `Bash(python3 -c:*)`, `Bash(cat:*)` removed in favor of Read tool
- `check-doc-sync.sh` hook walks parent directories to find `CLAUDE.md` instead of only checking the immediate directory
- Reference templates (9 total, was 8) fully synced with project-level improvements
- Plugin version synchronized: `marketplace.json` and `plugin.json` both bumped to 2.1.0

### Fixed

- **`PreCommit` → `PreToolUse`**: `PreCommit` is not a valid Claude Code hook event; replaced with `PreToolUse` (matcher: `Bash`) across all templates, commands, and documentation (15 files)
- **Invalid deny pattern**: `Bash(python3 -c:*import os*)` — `:*` mid-pattern breaks Claude Code's parser; fixed to `Bash(python3 -c*import os*)`
- **Invalid deny pattern**: `Bash(curl:* | bash)` and `Bash(wget:* | bash)` — `:*` mid-pattern causes settings.json parse failure; fixed to glob wildcards `Bash(curl*| bash*)` and `Bash(wget*| bash*)` in both `settings.json` and `settings-json-template.md`
- Template count references updated from 8 to 9 in architecture.md, SKILL.md, onboarding.md, and structure tests
- Phantom `scripts/deploy.sh` reference removed from architecture.md (file doesn't exist in this repo)
- Empty `tools/prompts/` removed from CLAUDE.md project structure
- Version mismatch between `marketplace.json` (1.0.0) and `plugin.json` (2.0.0)
- `check-doc-sync.sh` false warnings for nested directories where parent has `CLAUDE.md`
- Secret scan false positives from overly broad AWS Secret Key pattern
- GitHub Push Protection blocking test fixtures (now runtime-constructed)

### Documentation

- ADR-005: Implementation reference docs structure
- ADR-006: Hybrid detection + user confirmation for /init-project

## [2.0.0] - 2026-04-05

### Added

- `/add-runbook` command for creating operational runbooks from template with structured steps, verification, and rollback sections
- `/add-adr` command for creating Architecture Decision Records with auto-numbering and options-considered format
- `/health-check` command for validating entire project setup with health score (0-200, A-F grades)
- PreCommit hook (`secret-scan.sh`) for scanning staged files for API keys, passwords, and tokens
- SessionStart hook (`session-context.sh`) for loading project context at session start
- Notification hook (`notify.sh`) for webhook alerts on significant events
- Git commit-msg hook enhancement for case-insensitive Co-Authored-By removal (AI contributor exclusion)
- Agent templates for generated projects: `code-reviewer` and `security-auditor`
- Slash command templates for generated projects: `/review`, `/test-all`, `/deploy`
- MCP configuration template (`.mcp.json`) with GitHub, Slack, PostgreSQL, Playwright examples
- `onboarding.md` document template for new developer onboarding
- `api-reference.md` document template for API documentation
- `.env.example` template with security rules (no real secrets)
- `scripts/setup.sh` and `scripts/install-hooks.sh` templates for generated projects
- `tests/` directory structure generation (unit, integration) with CLAUDE.md
- Production-grade architecture.md template with bilingual language switcher, layer-based components, ASCII box diagrams, data flow summaries, infrastructure tables, and key design decisions
- Architecture diagram style guide using Unicode box-drawing characters (`┌─┐│└─┘▶▼`)
- Multi-level architecture doc freshness check (component sync, diagram accuracy, layer coverage, IaC tables, bilingual consistency)
- CLAUDE.md anti-pattern detection in `doc-sync-checker` (500+ lines, vague instructions, secrets, stale deps)
- Runbook coverage check in `doc-sync-checker` agent (recommends runbooks based on project characteristics)
- ADR freshness check in `doc-sync-checker` agent (flags stale or proposed ADRs)
- Runbook audit phase in `/sync-docs` command (Phase 6)
- Troubleshooting section in README.md (both English and Korean)
- Example command output in README.md Usage section
- `.gitignore`, `.editorconfig`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`
- GitHub issue templates (bug report, feature request) and PR template

### Changed

- **BREAKING:** `/init-project` now generates 14 steps (was 11), producing a more complete project structure
- Rewrite README.md as bilingual (English/Korean) format with shields.io badges
- Expand `doc-sync-checker` agent from 6 tasks to 9 tasks (runbook, ADR freshness, anti-patterns)
- Expand settings.json template to include all 4 hook types (SessionStart, PreCommit, PostToolUse, Notification)
- Expand skills-templates.md to include common slash command templates
- Expand docs-templates.md to include onboarding, API reference, and .env templates
- Expand SKILL.md knowledge base with extension types, anti-patterns, and security best practices
- Fix installation instructions to use `git clone` workflow instead of missing setup script
- Replace `tree` command with `find` in `/sync-docs` for cross-platform portability
- Update author from "Claude Code Plugin" to "whchoi98" in plugin.json
- Update email to whchoi98@gmail.com across all manifests

## [1.0.0] - 2026-03-07

### Added

- `/init-project` command with adaptive language and framework detection for existing projects ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- `/sync-docs` command with CLAUDE.md quality scoring on a 0-100 scale (A-F grades)
- `/add-module` command with automatic architecture docs and root CLAUDE.md update
- `project-scaffolder` knowledge skill for project structure patterns and conventions
- `doc-sync-checker` subagent for parallel documentation gap analysis (model: opus)
- 4-layer auto-sync workflow: Plan mode rules, PostToolUse hook, `/sync-docs` command, and Git commit-msg hook
- Plan mode integration for context-aware project generation with pre-filled architecture docs and ADRs ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code marketplace registration support ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Existing project detection for Node.js, Python, Go, Rust, and Java/Kotlin
- Confidence-based code review skill with 75+ threshold filtering in generated projects
- 5 reference template files (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- Restructure repository as marketplace with plugin in `plugins/project-init/` subdirectory ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/whchoi98/project-init/compare/v2.4.0...v3.0.0
[2.4.0]: https://github.com/whchoi98/project-init/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/whchoi98/project-init/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/whchoi98/project-init/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/whchoi98/project-init/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/whchoi98/project-init/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/whchoi98/project-init/releases/tag/v1.0.0

---

<a id="korean"></a>

# 한국어

이 프로젝트의 모든 주요 변경 사항은 이 파일에 기록됩니다.
이 문서는 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 기반으로 하며,
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 따릅니다.

## [Unreleased]

## [3.0.0] - 2026-11-03

### Added

- `plugins/project-init/scripts/harness-check.sh`(`bash harness-check.sh [--contract-only] [--] [PROJECT_DIR]`) 추가: 결정론적 하네스 검사를 실행해 검사마다 `<STATUS> <id> <earned>/<max> <detail>` 한 줄, 카테고리마다 `CATEGORY` 한 줄, 마지막에 `TOTAL <earned>/<max> <percent>%`를 출력하며, `--contract-only`는 훅 계약 검사(v2.3 이전 훅, 파싱되지 않는 `settings.json`, 스크립트가 없거나 등록이 종료 코드를 덮어쓰는 게이트, commit-scope·module-coverage 마커)만 실행하고 FAIL이나 WARN이 하나라도 있으면 exit 1
- 훅이 동작하지 못하게 만드는 원인을 찾는 검사를 `harness-check.sh`에 추가: 프로젝트 settings의 `disableAllHooks`, PATH에 있지만 실행되지 않는 `python3`, 여기서 실행할 수 없는 `VERIFY_CMD`나 git 작업 트리 밖의 verify-on-stop 게이트, GNU 전용 `sed -i`를 쓰거나 `core.hooksPath` 훅 관리자 아래에 없는 commit-msg 훅, `.mcp.json` 헤더의 리터럴 자격 증명, 뒤쪽 부정 패턴이 `.env` 줄을 무효로 만드는 `.gitignore`
- `plugins/project-init/scripts/check-bilingual.py`(`python3 check-bilingual.py FILE...`) 추가: ADR-001/002 배지와 앵커, 두 언어 절반의 헤딩·fence·표 대응, 동일한 Mermaid 블록, fence 언어 태그, 이모지, CHANGELOG 릴리스 헤딩을 검사하고 `FILE:LINE: message`로 출력 (exit 0 문제 없음, 1 문제 발견, 2 사용법 또는 읽기 오류)
- `hook-scripts.md`에 Optional `verify-on-stop.sh` Stop 게이트, `settings-json-template.md`에 120초 `timeout`을 둔 그 등록 블록 추가: 게이트의 마지막 실행 이후 바뀐 작업 트리에서 턴이 끝나면 프로젝트의 빠른 검사(`/init-project`가 채우는 `VERIFY_CMD`)를 실행하고 실패를 exit 2로 Claude에 돌려줌. 통과든 실패든 실행마다 트리 fingerprint를 기록하므로 바뀌지 않은 트리는 건너뛰고, 이어지는 턴(`stop_hook_active`)에서는 Claude가 무언가를 바꾼 뒤에만 다시 검사하며, Claude가 작업하는 linked worktree가 같은 저장소에 속하면 그 worktree를 검사
- `settings-json-template.md`에 `## Optional: Team Effort Cap` 추가: `maxEffortLevel`을 팀 전체 effort 상한 옵션으로 문서화 (Claude Code 2.1.267 이상)
- `settings-json-template.md`에 `## Optional: Subagent Model` 추가: `CLAUDE_CODE_SUBAGENT_MODEL`(예: Haiku 5.5용 `haiku`)을 팀 전체 서브에이전트 모델 옵션으로 문서화하고, 우선순위와 Amazon Bedrock, Google Cloud, Microsoft Foundry에서 Haiku 4.5로 해석되는 점을 안내
- 생성 `settings.json`에 `Read(./.env)`, `Read(./.env.*)` deny 규칙과 템플릿 관리를 위한 `Read(!.env.example)` 예외를 추가하고, `rm -fr`·`git push -f` deny 규칙은 생성 `settings.json`과 이 저장소의 `settings.json` 모두에 추가
- `secret-scan.sh`(저장소와 템플릿) 헤더에 `project-init:commit-scope` 마커 추가: `/health-check`와 `/migrate-hooks`가 커밋 범위 수정 이전 사본을 구분
- `check-doc-sync.sh`(저장소와 템플릿) 헤더에 `project-init:module-coverage` 마커 추가: 마커가 없는 사본을 `harness-check.sh --contract-only`가 `WARN doc-sync-scope`로 보고하고, `/migrate-hooks`가 `SOURCE_ROOTS`를 유지하며 다시 생성
- project-scaffolder `SKILL.md`에 단일 출처 섹션 `## CLAUDE.md Quality Criteria`, `## CLAUDE.md Anti-Patterns`(시크릿 grep 포함), `## Module CLAUDE.md Coverage`(하나뿐인 source root 대체 목록 포함) 추가: `/health-check`, `/sync-docs`, `/add-module`, doc-sync-checker 에이전트가 자체 사본 대신 이 섹션을 인용
- `reference-doc-template.md`에 `docs/reference/INDEX.md`와 루트 CLAUDE.md 블록 형식의 단일 출처인 `## INDEX.md`, `## Root CLAUDE.md Block` 섹션과, 감지됐지만 사용자가 해제한 계층에 붙는 `declined` 상태 추가: `/sync-docs`와 doc-sync-checker 에이전트가 해당 계층을 실행마다 권하지 않고 표시만 함
- 공통 `writing-style-guide.md`에 길이 규칙 추가: 독자에게 필요한 만큼만 쓰기, 조건을 충족하지 않는 선택 섹션 생략, 서론 반복과 끝부분 요약 금지
- 이 저장소에 Stop 훅(`.claude/hooks/test-gate.sh`, 180초 `timeout`으로 등록) 추가: 게이트의 마지막 실행 이후 바뀐 작업 트리에서 턴이 끝나면 `bash tests/run-all.sh`를 실행하고 실패 요약을 exit 2로 Claude에 돌려줌 (`TEST_GATE_CMD`로 명령 변경 가능). verify-on-stop과 마찬가지로 통과든 실패든 마지막 실행과 같은 트리는 건너뛰고, Claude가 작업하는 linked worktree를 검사
- 구조 테스트 추가: `marketplace.json`의 `plugins[0].version`, README 버전 배지, README 구조 트리의 버전 라벨, 양 언어 CHANGELOG의 최신 릴리스가 `plugin.json`과 다르거나, 저장소 훅·테스트·픽스처의 템플릿 사본이 원본과 어긋나면 실패
- 플러그인 프롬프트끼리 모순되면 실패하는 `tests/structure/test-prompt-contracts.sh` 추가: 모듈 커버리지 규칙과 source root 대체 목록, 모듈 CLAUDE.md 헤딩, 생성 `/deploy`가 제안하는 런북 이름, SKILL.md 시크릿 grep, 먼저 묻는 커맨드의 AskUserQuestion 사용, 기존 내용 예외, INDEX.md `declined` 상태, 런북의 `Last verified` 줄을 검사
- Opus 5.5 하네스 정렬(티어, 모델·effort 정책, 모든 finding 보고 리뷰어, 결정론적 스크립트, Stop 게이트, 커밋 범위 시크릿 게이트)을 기록한 ADR-009 추가

### Changed

- **BREAKING:** `/init-project`가 티어별로 생성: Core는 항상, Default(`/test-all`, code-reviewer 에이전트와 함께하는 `/review`)는 사용자가 해제하지 않는 한, Optional(`/deploy`, security-auditor, code-review·refactor·release 스킬, session-context·notify·verify-on-stop 훅)은 사용자가 선택할 때만 생성하며, 참조 계층과 같은 사전 질문에서 선택 (ADR-009). code-review 스킬을 선택하면 `/review`와 code-reviewer 에이전트를 대신해 리뷰 경로가 하나로 유지되고, session-context는 보고할 로컬 환경 정보가 있을 때만, verify-on-stop은 git 저장소에서만 생성(그렇지 않으면 Skipped에 기록)
- `/init-project`를 목표, 규칙, 감지, 한 번의 질문, 산출물 표, 순서가 있는 마무리 단계로 재작성: 기존 `.claude/`를 `harness-check.sh --contract-only`로 검사해 훅이 현재 계약 이전 것이면 `/project-init:migrate-hooks`를 먼저 권하고, 계층 신호를 모든 깊이에서 찾으며, 기존 파일은 덮어쓰지 않고 `(existing, kept)`로 기록, 기존 `settings.json`에는 없는 deny 규칙과 훅 등록만 병합(새 `settings.json`에는 감지한 테스트 명령과 빠른 검사를 `permissions.allow` 규칙으로도 추가), 요약 전에 생성 테스트·훅 계약 검사와 작성한 모든 이중 언어 파일의 이중 언어 검사 실행, 실행 전부터 있던 내용의 문제는 고쳐 쓰지 않고 보고, 새 저장소에서는 생성한 경로만 커밋, 기존 저장소에서는 커밋하지 않음, 사용자만 시작 가능
- `/init-project`, `/sync-docs`, `/generate-readme`, `/generate-changelog`, `/add-adr`, `/add-runbook`, `/add-module`, `/add-reference-doc`의 사전 질문을 AskUserQuestion 도구가 있으면 그 도구로 묻도록 변경: 답이 같은 턴에 도착해 커맨드의 `allowed-tools` 사전 승인이 유지되지만, 채팅 답장은 사전 승인이 없는 새 턴을 시작하기 때문. 긴 체크리스트는 여러 호출로 나누고(호출당 최대 4개 질문, 질문당 4개 옵션, `multiSelect`와 자유 입력 답 사용), 도구가 없으면 채팅 메시지 한 번으로 물음
- **BREAKING:** `/health-check` 점수를 항목 합계가 195점인데 손으로 합산하던 0-200 점수 대신, `harness-check.sh`가 계산한 적용 가능 점수 대비 백분율(A >= 80%, B >= 60%, C >= 40%, D >= 20%, F < 20%)로 보고하도록 변경: Core files, Hooks, Hook contract, Harness components, Compatibility, Documentation, Security, Tests 카테고리, CRITICAL·NEEDS ATTENTION·HEALTHY 상태, 별도의 100점 만점 CLAUDE.md 품질 점수, 테스트 1회 실행 포함
- 모듈 CLAUDE.md 커버리지를 할당량이 아닌 보고로 변경: source root 자신의 CLAUDE.md(예: `src/CLAUDE.md`)가 그 아래 모든 모듈을 커버하고, `harness-check.sh`는 `docs-modules`를 점수가 없는 INFO로 출력하며, `/health-check`에서는 모델이 커버되지 않은 모듈을 하나씩 판단해 코드가 보여 주지 않는 규칙, 불변 조건, 주의점이 있을 때만 `/add-module`을 권함
- `/health-check`가 어느 등급(하네스 등급 또는 CLAUDE.md 등급)을 말하는지 밝히고, 게이트가 실행되지 않을 수 있을 때(`secret-scan-scope`, `doc-sync-scope`, 게이트 등록, `hook-python3`, `hook-disable-all` 경고)나 CLAUDE.md 등급이 D 또는 F일 때 NEEDS ATTENTION을 보고하며, 모든 FAIL, WARN, CLAUDE.md 감점에 조치를 하나씩 제시하고 사소한 것은 빼지 않고 표시하도록 변경
- `/health-check`의 "Skills: X/4 installed" 카테고리를 Harness components(스킬·커맨드·에이전트가 로드되고, 서로 또는 플러그인 커맨드나 내장 커맨드와 중복되지 않는지)로 교체하고, 스킬 frontmatter, 지원되지 않는 키, 옛 모델 ID, 별칭 고정, 프로젝트 수준 `effortLevel`, 문서에 없는 훅 이벤트에 대한 Compatibility 안내 추가
- `/migrate-hooks`가 `harness-check.sh --contract-only`와 상대 경로 등록 검사로 마이그레이션 대상을 감지하고, 커밋 범위 마커가 없는 `secret-scan.sh`(사용자 정의 `PATTERNS`, `SKIP_PATTERNS`는 유지하되 템플릿이 대체하는 옛 기본값은 제외)와 module-coverage 마커가 없는 `check-doc-sync.sh`(`SOURCE_ROOTS` 유지)를 다시 생성하며, 파싱되지 않는 `settings.json`은 등록을 다시 쓰기 전에 먼저 고치고, 스크립트가 없는 등록된 게이트를 작성하고, project-init 훅 등록을 모두 `$CLAUDE_PROJECT_DIR` 형식으로 다시 쓰고, 변환한 에이전트에서 `model`을 제거하고, 백업은 자체 `.gitignore`로 git에서 제외하며, 임시 저장소에 stage한 토큰으로 다시 생성한 게이트를 시험하고, 마이그레이션 후 검사가 실패하면 백업에서 복원하며, 사용자만 시작할 수 있도록 변경
- `settings-json-template.md`를 Core 템플릿(secret-scan, check-doc-sync)과 훅별 Optional 등록 블록으로 분리하고, 권한 규칙을 공백 형식(`Bash(rm -rf *)`)으로 작성하며, 생성 settings에 `model`과 `effortLevel`을 넣지 않도록 변경
- `secret-scan.sh`(저장소와 템플릿) 변경: 시크릿을 `.env`로 옮기거나 파일과 패턴을 오탐으로 보고하라고 Claude에 알리는 메시지로 차단. 경로 기준으로 건너뛰며(`*secret-scan.sh`, `tests/hooks/test-secret-patterns.sh`, `tests/fixtures/secret-samples.txt`, `tests/fixtures/false-positives.txt`, `*.md`, `.env.example`, lock 파일), 프로젝트가 저장소의 하위 디렉터리이면 프로젝트 기준 경로로도 비교하되, 모든 CLAUDE.md와 `tests/fixtures/`의 다른 파일은 검사. 검사할 수 없는 커밋(python3가 없거나 실행되지 않음, 검사 실패, 저장소를 찾지 못함)은 아무도 보지 못하는 stderr 한 줄 대신 사용자(`systemMessage`)와 Claude(`additionalContext`)에게 경고하고 통과시킴. stage된 내용은 파일마다 `git show`를 실행하지 않고 `git cat-file --batch` 한 번으로 읽음
- `check-doc-sync.sh` 템플릿이 1단계 모듈 디렉터리를 지목하고, 세션당 한 번만 알리며, ADR·런북 파일 존재 검사를 하지 않고, JSON을 `json.dumps`로 생성하며, `SOURCE_ROOTS` 기본값을 `src app lib`로 두고, 같은 저장소의 linked worktree에서 편집한 파일은 그 worktree 기준으로 검사하도록 변경
- `session-context.sh` 템플릿을 Optional로 바꾸고 고정 런타임 불일치(`.nvmrc`, `.python-version`의 첫 버전 줄 기준)와 테스트에 필요한데 실행 중이 아닌 서비스만 보고하며 그 외에는 아무것도 출력하지 않도록, `notify.sh` 템플릿을 Optional로 바꾸고 `notification_type`과 `message`를 `json.dumps` 페이로드로 10초 제한과 함께 백그라운드 전송하도록 변경
- 이 저장소의 SessionStart 훅이 Claude Code가 이미 주입하는 git 정보 대신 플러그인 버전과 매니페스트·README 배지·CHANGELOG 사이의 버전 드리프트를 출력하도록, 이 저장소의 `check-doc-sync.sh`가 플러그인 루트의 CLAUDE.md만 요구하고 linked worktree에서 편집한 파일은 그 worktree 기준으로 검사하도록 변경
- 생성 code-reviewer(Default)와 security-auditor(Optional) 에이전트에서 `model`을 생략해 세션 모델을 상속하고 `CLAUDE_CODE_SUBAGENT_MODEL`을 따르게 하고, 도구는 일반 이름으로 나열하며, 75점 이상만이 아니라 모든 finding을 심각도와 확신도와 함께 보고하도록 변경
- doc-sync-checker 에이전트의 `model: opus` 고정을 제거하고 `effort: medium`을 설정하며, 도구는 일반 이름으로 나열하고(문서에 없는 `Bash(find:*)` 지정자 대신 `Bash`, 읽기 전용은 프롬프트가 유지), 모든 finding에 심각도와 확신도를 붙이고(없어도 점수만 낮아지는 섹션은 버리지 않고 `score only`로 보고), 커버되지 않은 1단계 모듈만 보고하며, SKILL.md 기준과 시크릿 grep으로 CLAUDE.md를 채점하고, `/sync-docs`가 읽는 줄 형식의 `### Implementation References` 보고 섹션 추가
- `/sync-docs`를 한 번 감사, 적용, 검사, 보고 구조로 재구성: CLAUDE.md와 문서 파일이 대략 10개 이하면 직접 감사하고 그보다 많으면 doc-sync-checker 에이전트를 브리프 한 번으로 한 번만 실행하며, 다시 감사하지 않고 문서 유형별로 finding을 적용하고(`score only` finding은 적용하지 않음), ADR과 런북은 직접 쓰지 않고 제안하며, 작성한 문서에 `check-bilingual.py`를 실행하고, 보고서에 Implementation References, Runbooks, Bilingual Check 섹션 추가
- `/add-adr`, `/add-runbook`, `/add-module`, `/add-reference-doc`, `/generate-readme`, `/generate-changelog`를 목표, 입력, 규칙, 출력 계약, 검사, 보고 구조로 재작성: 프로젝트의 `docs/decisions/.template.md`나 `docs/runbooks/.template.md`를 먼저 읽고, 저장소로 답할 수 없는 것만 한 번에 묻고, 옵션이나 명령을 지어내지 않고 TODO 표시를 남기며(런북은 `TODO(verify)`), 산문 체크리스트 대신 `check-bilingual.py`를 실행
- `/generate-changelog`가 이미 존재하는 버전의 릴리스를 거부하고, 보고 끝에 실행할 `git tag -a` 명령을 제시하며, 한국어 절반이 없는 CHANGELOG에는 한국어 절반을 추가할지 묻고, 릴리스된 섹션의 검사 문제는 고쳐 쓰지 않고 보고하도록, `/add-reference-doc`가 쓰기 전에 기존 계층 파일을 덮어쓸지, 건너뛸지, 중단할지 한 번에 묻도록 변경
- 생성되는 모든 SKILL.md에 YAML frontmatter(`name`, `description`)를 추가하고, 생성 `/test-all`에 `effort: low`와 보고 전용 계약을 적용하며, 생성 `/review`가 untracked 파일을 포함하고 여러 파일 변경은 code-reviewer 에이전트에 위임하며 모든 finding을 보고하도록 변경
- 생성 `/deploy`를 Optional이자 사용자 전용 호출로 변경: `docs/runbooks/deploy-*.md`를 따르고, 런북에 있는 명령만 실행하며, 런북이 없으면 배포하지 않고 `/add-runbook deploy-<environment>`(환경을 지정하지 않으면 `deploy-production`)를 제안
- Optional code-review·refactor·release 스킬을 프로젝트 고유 사실만 담도록 축소하고, release에 `disable-model-invocation: true` 적용
- `SKILL.md`의 CLAUDE.md 안티패턴 감점 개편(코드나 설정을 반복하는 내용, 하드코딩 개수 같은 변동 정보, 강조 남용이나 이유 없는 규칙, 사고·검증 발판 문구, prune test를 통과하지 못하는 섹션)과 "Over 500 lines", "No test guidance", "No error patterns" 감점 삭제; 줄 수는 참고 정보로만 사용
- 생성 루트 CLAUDE.md의 Auto-Sync Rules를 지침으로 작성("Claude applies these while working; nothing runs automatically")하고, ADR은 되돌리기 비싼 결정으로 한정하며, Key Commands에 "Verify a change" 줄을 추가하고, 모듈 CLAUDE.md 템플릿을 Role, Invariants and gotchas, Entry point로 줄이며 코드가 보여 주지 않는 규칙이 있는 모듈에만 생성
- `.mcp.json`을 `{"mcpServers": {}}`로 생성하고 감지된 통합에는 `claude mcp add --scope project`를 제안하며, 서버 항목에 `${VAR}`와 `${VAR:-default}` 예시 표시
- 생성 `.gitignore`에 `.claude/worktrees/`를 넣고 기존 `.gitignore`에도 추가해, `git add`와 커밋 범위 시크릿 스캔이 Claude Code의 linked worktree를 건너뛰도록 변경
- README 템플릿의 Contributing 섹션을 저장소 성격에 따라 달리하고(CONTRIBUTING.md가 있거나 비공개 저장소면 실제 흐름, 공개 GitHub 저장소면 fork 흐름), 버전 배지를 `CHANGELOG.md`에 연결하며, architecture 템플릿의 한국어 헤딩을 번역
- 생성 훅 테스트가 stdin 계약, exit 2, `|| true` 없는 게이트 등록, `$CLAUDE_PROJECT_DIR` 등록, 체인 커밋, `commit -am`, stage된 이름 변경, 따옴표로 감싼 `git -c` 값, CLAUDE.md와 `tests/fixtures/` 검사, python3가 없을 때의 경고, linked worktree, commit-msg 훅을 검사하고, Optional 훅 테스트는 해당 훅이 있을 때만 실행하도록 변경; 생성 시크릿 패턴 테스트는 훅의 `PATTERNS`를 읽어 python3 `re`로 매칭
- 이 저장소의 `/deploy`를 사용자 전용 호출로, `/review`가 `HEAD` 이후의 모든 변경(stage된 것과 안 된 것)과 untracked 파일을 리뷰하고 테스트 스위트를 먼저 실행하며 모든 이슈를 심각도와 confirmed·suspected로 보고하도록, `/test-all`이 실패를 원인에서 고치고 변경 내용을 보고하도록 변경
- `plugins/project-init/CLAUDE.md`와 `CONTRIBUTING.md`에 커맨드 작성 규칙 문서화: 작은 소비자 모델을 위한 명시적 출력 계약을 담은 브리프, 모델·effort 정책, `${CLAUDE_PLUGIN_ROOT}` 참조, 사전 질문용 AskUserQuestion, 릴리스·배포·푸시를 하거나 많은 파일 또는 사용자의 하네스를 다시 쓰는 작업(예: `/init-project`, `/migrate-hooks`)의 `disable-model-invocation: true`
- 이 저장소의 `docs/decisions/.template.md`와 `docs/runbooks/.template.md`를 `docs-templates.md`의 이중 언어 템플릿으로 교체
- ADR-008을 ADR-009로 확장된 것으로 표시: 생성 기본값에 대해서는 ADR-009가 ADR-008의 결정 5를 대체
- 플러그인 규칙, ADR-009, README, CONTRIBUTING을 Claude 5.5 세대에 맞춤: Opus 5.5, Sonnet 5.5, Haiku 5.5는 모두 기본 effort가 `medium`이고, Amazon Bedrock, Google Cloud, Microsoft Foundry에서는 `sonnet`과 `haiku` 별칭이 여전히 4.5 모델로 해석되며, README에 모델별 최소 Claude Code 버전을 명시
- 생성 CLAUDE.md의 검증 명령을 변경 완료 보고 전에 실행하도록 하고(문법 검사나 시작에 실패한 명령은 검증으로 치지 않음), 생성 `/test-all`이 시작하지 못한 스위트를 실행 안 됨으로 보고하도록 변경. Sonnet 5.5와 Haiku 5.5는 low나 medium effort에서 검사 없이 변경을 완료로 보고하는 경우가 있기 때문
- `harness-check.sh`의 `compat-model-ids` 검사가 대체된 `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5` ID 고정도 표시

### Removed

- 생성 프로젝트에서 `/project-init:sync-docs`와 중복되는 sync-docs 스킬 템플릿과 `tools/prompts/` 디렉터리 제거
- 자리표시자 모듈 CLAUDE.md(`tests/unit/`, `tests/integration/` 포함)와 API·persistence 모듈 CLAUDE.md 템플릿 제거
- 생성 `/deploy`, `/review`, `/test-all`의 Error Recovery 절차와 code-review 스킬의 확신도 기준표 제거
- `mcp-json-template.md`에서 검증할 수 없는 MCP 서버 패키지 예시, `settings-json-template.md`에서 Minimal 템플릿과 기본 Notification 등록 제거
- `/init-project`가 생성한 적 없는 `deploy.sh`, `seed-db.sh` 템플릿을 `scripts-templates.md`에서 제거

### Fixed

- `secret-scan.sh`가 `git add . && git commit`, `git commit -am`, `git commit -m <msg> <path>`, `git -C <dir> commit`, `git -c k=v commit`을 검사 없이 통과시키던 문제 수정: 이제 커밋에 들어갈 내용(index에서 읽은 stage된 파일, `-a`·`--all`·pathspec이면 수정된 tracked 파일, 같은 명령줄에 `git add`나 `git stage`가 있으면 `git add -f`로 지정한 ignore 파일을 포함한 untracked 파일)을 검사
- `secret-scan.sh`의 파일 목록이 `--diff-filter=ACM`을 써서 이름을 바꾼 파일과 유형 변경(파일로 바뀐 symlink)을 검사 없이 통과시키던 문제 수정: 이제 삭제만 제외
- `secret-scan.sh`가 따옴표나 공백이 든 git 옵션 값(`git -c user.name="Claude Code" commit`, `git -C "my repo" commit`, `git --git-dir .git commit`)을 쓰거나 같은 줄의 `cd`·`pushd` 뒤에 오는 커밋을 놓치던 문제와, 따옴표로 감싼 커밋 메시지 안의 `;`, `&`, `|`가 `-a` 같은 뒤쪽 인자를 잘라 내던 문제 수정
- `secret-scan.sh`가 현재 키 형식을 놓치던 문제 수정: `_`가 든 Anthropic 키, OpenAI 프로젝트·서비스 계정·관리자 키(`sk-proj-`, `sk-svcacct-`, `sk-admin-`), PEM·OpenSSH 개인 키, 대소문자가 다르거나 JSON 키로 쓴 따옴표 값의 `password`, `secret`, `api_key`. `${VAR}`, `{{ ... }}`, `%(name)s`, `<placeholder>` 같은 참조는 계속 걸리지 않고, `POSTGRES_PASSWORD: "postgres"` 같은 따옴표로 감싼 로컬 기본값은 이제 차단되며, `harness-check.sh`도 최소한 같은 패턴을 감지
- `secret-scan.sh`가 이름에 공백, 따옴표, 탭, 줄바꿈이 든 파일을 건너뛰던 문제 수정: 이제 파일 목록을 NUL로 구분
- `secret-scan.sh`가 macOS에 없는 `grep -P`를 쓰고, 가변폭 lookbehind 때문에 조용히 실패해 한 번도 매칭되지 않던 AWS secret access key 패턴을 쓰던 문제 수정: 패턴은 이제 python3 `re`로 매칭하며, AWS 패턴은 ini, `.env`, JSON 형식을 모두 처리
- `secret-scan.sh`가 자신의 패턴 정의와 시크릿 패턴 테스트 파일의 커밋을 차단하던 문제 수정
- `secret-scan.sh`가 glob pathspec을 쓴 커밋(`git commit -m x '*.py'` 또는 따옴표 없는 `*.py`)을 검사 없이 통과시키고, pathspec 중 하나가 저장소 밖 경로를 가리키면 그 커밋의 pathspec을 모두 건너뛰던 문제 수정: glob pathspec도 검사하고, pathspec마다 따로 해석
- `secret-scan.sh`가 `git -C <dir> add -f`로, 또는 커밋 전에 같은 줄에서 되돌리는 `cd` 뒤에서 강제로 추가한 ignore 파일을 놓치던 문제 수정: 강제 추가한 경로를 `git add`가 실행되는 디렉터리 기준으로 해석
- `secret-scan.sh`가 `cd` 옵션(`cd -P dir`, `cd -L dir`, `cd -- dir`)을 이동할 디렉터리로 받아들여, 엉뚱한 저장소를 검사하거나 아무 저장소도 검사하지 않고 경고 없이 커밋을 통과시키던 문제 수정
- `secret-scan.sh`가 PGP 개인 키 블록(`-----BEGIN PGP PRIVATE KEY BLOCK-----`)을 놓치던 문제 수정
- Claude가 하위 디렉터리로 이동하면 상대 경로 `bash .claude/hooks/<name>.sh` 등록이 127(비차단)로 종료해 게이트 훅이 조용히 열리던 문제 수정: 생성 `settings.json`과 이 저장소의 모든 등록이 이제 `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh` 사용
- `scripts/install-hooks.sh`(저장소와 템플릿)가 작성하는 commit-msg 훅이 macOS에서 모든 커밋을 중단시키던 문제 수정: BSD sed는 백업 접미사 없는 `sed -i`를 거부하므로, 이제 `sed -i.bak ... && rm -f "$1.bak"`를 실행하고 exit 0으로 끝남
- `scripts/install-hooks.sh`(저장소와 템플릿)가 `.git`이 파일인 linked worktree에서 실패하고, `core.hooksPath`가 husky 같은 훅 관리자를 가리키면 git이 실행하지 않는 훅을 쓰며, 다른 commit-msg 훅을 덮어쓰던 문제 수정: `git rev-parse --git-path hooks`가 가리키는 곳에 설치하고, 뒤의 두 경우에는 아무것도 바꾸지 않고 추가할 줄을 출력한 뒤 exit 1로 끝나며, `scripts/setup.sh`는 이를 알리고 계속 진행
- `scripts/install-hooks.sh`(저장소와 템플릿)가 작성하는 commit-msg 훅이 NixOS처럼 `/bin/bash`가 없는 시스템에서 모든 커밋을 중단시키던 문제 수정: 이제 `#!/bin/sh`로 시작. 또한 `install-hooks.sh`가 자신이 설치한 훅만 교체하므로, Co-authored-by를 언급하는 다른 훅(예: 트레일러를 추가하는 훅)은 그대로 두고 추가할 줄을 출력
- `tests/run-all.sh`(저장소와 템플릿)가 프로젝트 경로에 공백이 있으면 깨지고, stdin을 읽는 테스트에 나머지 파일 목록을 빼앗기며, source한 파일이 도중에 끝낸 실행을 통과로 보고하고, `pipefail`에서 `assert_contains`가 무작위로 실패하던 문제 수정
- 훅 테스트(`tests/hooks/test-hooks.sh`, 저장소와 템플릿)가 `tests/run-all.sh` 실행 전체를 무작위로 exit 141로 중단시키던 문제 수정: 등록을 찾는 부분이 파이프를 일찍 닫아, `set -euo pipefail`에서 SIGPIPE가 실행을 끝냈음
- 이 저장소의 Stop 게이트(`test-gate.sh`)와 Optional `verify-on-stop.sh` 템플릿이 훅 `timeout`으로 Claude Code가 실행을 중단한 뒤 그 트리를 조용히 건너뛰던 문제 수정: 트리가 검사된 것으로 기록되어 이후 턴이 결과 없이 끝났음. 이제 중단된 실행을 한 번 보고
- 생성 `tests/run-all.sh`가 프로젝트에 이미 있는 `test-*.sh` 파일(예: `tests/e2e/` 아래)까지 source하던 문제 수정: 이제 `TEST_DIRS`에 있는 디렉터리만 source
- 생성 구조 테스트가 모든 프로젝트에서 CHANGELOG를 버전 파일과 비교하던 문제 수정: 이 블록은 프로젝트에 버전 파일이 있을 때만 켜고, `/init-project` 이전부터 있던 내용의 불일치는 릴리스를 추가하거나 버전을 올려 고치지 않고 보고
- 플러그인 커맨드와 에이전트가 소비자 프로젝트에서 해석되지 않는 상대 경로(`skills/project-scaffolder/...`, `plugins/project-init/...`, `../skills/...`)로 템플릿을 참조하던 문제 수정: 이제 `${CLAUDE_PLUGIN_ROOT}`를 쓰고, 템플릿을 읽지 못하면 멈춤
- `/health-check`와 `/migrate-hooks`의 `$EVENT`/`$MESSAGE` grep이 `check-doc-sync.sh`의 `$MESSAGES`와 `notify.sh`의 지역 변수에 매칭되어 새로 생성한 v2.3 이후 훅을 `STALE CONTRACT`로 표시하던 문제 수정
- 생성 참조 문서와 `docs/reference/INDEX.md`가 ADR-002가 기각한 Markdown 배지와 `## English` 헤딩을 쓰던 문제 수정: 이제 HTML 배지 쌍, `# English`와 `# 한국어`, `---` 구분선을 쓰며, INDEX.md에 한국어 절반 추가
- `/init-project`가 `#korean` 대신 `#한국어`로 연결되는 README 언어 전환을 쓰고 Architecture 섹션을 빠뜨리던 문제 수정: README, CHANGELOG, architecture를 전용 커맨드와 같은 템플릿으로 생성
- `/sync-docs`가 source root 아래 모든 디렉터리에 CLAUDE.md를 만들던 문제 수정: 이제 SKILL.md 커버리지 규칙을 따름
- `agents-templates.md`의 깨진 fence가 security-auditor 섹션을 코드 블록 안으로 끌어들이던 문제와, API reference 템플릿의 중첩 fence 때문에 추출 시 템플릿이 잘리던 문제 수정
- 생성 SKILL.md에 YAML frontmatter가 없던 문제 수정, project-scaffolder 스킬 frontmatter에서 지원되지 않는 `tools` 필드 제거
- `changelog-template.md`가 `git log`에 대칭 차집합 `...` 범위를 쓰고 YYYY-MM-DD가 아닌 릴리스 날짜 형식을 쓰던 문제 수정
- architecture 템플릿이 존재하지 않을 수 있는 런북에 링크하던 문제 수정: 이제 `docs/runbooks/`에 있는 런북만 링크
- `notify.sh` 템플릿이 훅이 읽지 않는 `.env`에 웹훅을 설정하라고 안내하던 문제 수정 (훅은 환경 변수 `CLAUDE_NOTIFY_WEBHOOK`을 읽음): `.env.example` 템플릿과 이 저장소의 `.env.example`에서도 제거
- `/add-runbook`이 아무도 실행하지 않은 런북의 `Last verified`에 오늘 날짜를 쓰던 문제 수정: 이제 `not yet run (written <date>)`을 쓰고, 날짜는 사용자가 절차를 실행했다고 말할 때만 씀
- security-auditor 템플릿이 `pip-audit` 대신 `pip audit`을 실행하던 문제 수정, Go 프로젝트용 `govulncheck ./...` 추가
- doc-sync-checker 에이전트가 `task-` 같은 단어에 매칭되는 자체 시크릿 grep을 쓰던 문제 수정: 이제 토큰 패턴이 kebab-case 단어를 건너뛰는 SKILL.md 시크릿 grep을 실행. 또한 이 저장소의 `check-doc-sync.sh`가 플러그인 하위 디렉터리에 CLAUDE.md를 요구하고 경로의 따옴표에서 깨지는 JSON을 만들던 문제 수정

## [2.4.0] - 2026-09-13

### Added

- 신규 커맨드 `/migrate-hooks [--dry-run]`: `.claude/hooks/`, `settings.json`, `.claude/agents/`를 백업하고, v2.3 이전 훅 스크립트를 현재 템플릿으로 재생성(사용자 정의 `PATTERNS`, `SOURCE_ROOTS` 유지), 훅 명령 문자열 수정, `.yml` 에이전트를 Markdown 서브에이전트로 변환, 샘플 stdin 이벤트로 검증
- `/health-check` Step 2.5에서 v2.3 이전 훅 계약(`settings.json`의 `$TOOL_INPUT_PATH`, `|| true`로 감싼 `secret-scan.sh`, `tool_input`을 읽지 않는 훅, `.yml` 에이전트)을 감지하고 해당 훅을 `STALE CONTRACT`로 표시하며 `/migrate-hooks`를 권장

## [2.3.0] - 2026-09-13

### Changed

- 훅 템플릿(`hook-scripts.md`, `settings-json-template.md`)이 Claude Code 훅 계약을 따르도록 수정: 이벤트 JSON을 stdin에서 읽고(`tool_input.file_path`, `tool_input.command`, `message`), `secret-scan.sh`는 `git commit`만 게이트하며 exit 2로 차단, `check-doc-sync.sh`는 `hookSpecificOutput.additionalContext`로 리마인드를 반환, 게이트 훅은 `|| true` 없이 등록
- 에이전트 템플릿(`agents-templates.md`)이 YAML frontmatter와 Markdown 시스템 프롬프트를 가진 `.claude/agents/*.md`를 생성; `/init-project` Step 8과 README 트리 갱신
- 저장소 하네스를 최신 모델 기준으로 적정화(ADR-008): 범용 스킬(code-review, refactor, release, sync-docs), 로드되지 않는 `.yml` 에이전트, 미사용 Notification 훅 제거; `/review`, `/test-all`, `/deploy`를 저장소 고유 점검만 남기도록 축소; CLAUDE.md, 런북, 테스트의 하드코딩된 테스트·파일 개수 제거

### Fixed

- 생성된 PostToolUse·Notification 훅이 존재하지 않는 `$TOOL_INPUT_PATH` / `$EVENT` / `$MESSAGE` 환경변수에 의존해 아무 동작도 하지 않던 문제
- 생성된 `secret-scan.sh`가 `|| true`로 감싸져 있고 exit 1(비차단)을 사용해 커밋을 차단할 수 없던 문제
- 생성된 `.claude/agents/*.yml` 파일이 Claude Code에 로드되지 않던 문제(서브에이전트는 `.md`만 지원)

## [2.2.0] - 2026-07-12

### Added

- README 템플릿에 Architecture 섹션 추가 (권장, Features 다음 배치) — 간결한 Mermaid flowchart와 `docs/architecture.md` 링크 포함
- 공유 `writing-style-guide.md`에 Diagram Rules 섹션 추가: 모든 아키텍처 흐름은 Mermaid flowchart 사용 (전체 다이어그램은 계층별 subgraph를 가진 `flowchart TB`, 데이터 흐름은 `flowchart LR`), 다이어그램은 양 언어 섹션에 동일하게 복제
- Mermaid flowchart 결정을 기록한 ADR-007 추가

### Changed

- `docs-templates.md`, `/init-project`, `/sync-docs`(Phase 4), `doc-sync-checker` 에이전트 전반에서 ASCII 박스 다이어그램(`┌─┐│└─┘▶▼`)을 Mermaid flowchart로 교체; `/sync-docs`가 다음 실행 시 레거시 ASCII 다이어그램 변환
- `/generate-readme`가 `docs/architecture.md`를 감지하여 README Architecture 섹션의 flowchart를 Data Flow Summary에서 도출
- 저장소 `README.md`와 `docs/architecture.md`를 Mermaid flowchart로 마이그레이션

## [2.1.0] - 2026-05-19

### Added

- 구현 참조 문서 기능 — `/init-project` Step 4.5가 최대 8개 레이어(infrastructure, data, api, iac, frontend, ui, security, agent-llm)를 감지하고 `docs/reference/` 아래 스켈레톤 생성
- 점진적 레이어 추가를 위한 새로운 커맨드 `/add-reference-doc <layer>`
- 루트 CLAUDE.md의 자동 관리형 `docs/reference/INDEX.md` 및 `## Implementation References` 블록 (`<!-- AUTO-MANAGED:* -->` 마커 사이)
- 새로운 플러그인 템플릿: `skills/project-scaffolder/references/reference-doc-template.md`
- 모든 문서 유형에 일관된 스타일 및 이중 언어 규칙을 적용하는 공통 `writing-style-guide.md` 참조 템플릿 추가
- ADR 템플릿에 이중 언어(EN/KR) 구조 추가 (언어 토글 및 번역된 섹션 제목)
- Runbook 템플릿에 이중 언어(EN/KR) 구조 추가 (언어 토글 및 번역된 섹션 제목)
- `/add-adr` (Step 8) 및 `/add-runbook` (Step 7)에 이중 언어 출력 검증 단계 추가
- 이중 언어(EN/KR) README.md를 자동 감지와 shields.io 뱃지로 생성하는 `/generate-readme` 커맨드 추가
- Keep a Changelog 규약에 따라 이중 언어(EN/KR) CHANGELOG.md를 생성하는 `/generate-changelog` 커맨드 추가
- README/CHANGELOG 생성 규칙을 정의하는 `readme-template.md`, `changelog-template.md` 참조 템플릿 추가
- `/init-project`에 매니페스트 파일 자동 감지 기반 이중 언어 README.md 생성 통합 (Step 12)
- `/init-project`에 git 태그 히스토리 분석 기반 이중 언어 CHANGELOG.md 생성 통합 (Step 13)
- `/sync-docs`에 뱃지, 섹션, 언어 동기화 검증을 포함한 전체 README.md 동기화 추가 (Phase 7)
- `/sync-docs`에 git log 분석과 미릴리스 항목 분류를 포함한 CHANGELOG.md 동기화 추가 (Phase 8)
- 자동화된 테스트 프레임워크(`tests/run-all.sh`) 추가: 3개 카테고리 114개 테스트 (훅 27, 시크릿 패턴 22, 구조 65)
- 시크릿 패턴 검증용 테스트 픽스처 파일 추가 (True Positive / False Positive)
- 모든 생성 커맨드에 에러 복구 섹션 추가: `/deploy` (전체 롤백 포함 5개 시나리오), `/review` (3개 시나리오), `/test-all` (실패 패턴 표 + 다중 실패 진단)
- 에이전트 구조화된 출력 스키마 추가: `code-reviewer` (Verdict, Summary 테이블, Guideline 필드), `security-auditor` (카테고리별 분류, Recommendations, Passed Checks 체크리스트)
- `settings.json` Deny 목록 추가: `rm -rf`, `git push --force`, `git reset --hard`, `eval`, `curl|bash`, `python3 -c import os` 차단
- `/init-project`의 테스트 프레임워크 생성을 위한 `tests-templates.md` 참조 템플릿 추가
- `tests/`, `docs/`, `scripts/` 디렉토리용 모듈 `CLAUDE.md` 추가
- README에 하네스 엔지니어링 섹션 추가: 플러그인을 하네스 자동화 도구로 설명
- README에 권장 워크플로우 섹션 추가: brainstorm → plan → implement → /init-project → /sync-docs

### Changed

- `/sync-docs` Phase 1을 참조 블록으로 확장: 누락된 레이어 문서 감지, Code Pointers 검증, INDEX 드리프트 자동 수정
- `doc-sync-checker` 에이전트를 참조 문서 검증 기능 추가
- **BREAKING:** `/init-project`가 17단계로 확장 (기존 15단계), 이중 언어 README.md (Step 12) 및 CHANGELOG.md (Step 13) 생성 추가
- `/sync-docs`가 11단계로 확장 (기존 9단계), 공통 스타일 가이드 읽기 (Phase 0), README.md 동기화 (Phase 8), CHANGELOG.md 동기화 (Phase 9) 추가
- 모든 문서 생성 커맨드(`/generate-readme`, `/generate-changelog`, `/add-adr`, `/add-runbook`, `/sync-docs`)가 공통 `writing-style-guide.md` 참조
- `/add-adr`가 영어/한국어 이중 언어 ADR 생성
- `/add-runbook`이 영어/한국어 이중 언어 Runbook 생성
- 참조 템플릿 12개로 확장 (기존 9개), writing-style-guide.md, readme-template.md, changelog-template.md 추가
- 시크릿 스캔 패턴 강화: 광범위 Base64 패턴을 컨텍스트 기반 AWS Secret Key 감지로 교체; Stripe, Google, Azure, GitHub 토큰 패턴 추가
- 도구 범위 강화: `Bash(python3:*)` → `Bash(python3 -c:*)`, `Bash(cat:*)` 제거 후 Read 도구 사용
- `check-doc-sync.sh` 훅이 부모 디렉토리를 탐색하여 `CLAUDE.md`를 찾도록 개선
- 참조 템플릿 9개(기존 8개) 전체를 프로젝트 수준 개선 사항과 동기화
- 플러그인 버전 동기화: `marketplace.json`과 `plugin.json` 모두 2.1.0으로 상향

### Fixed

- **`PreCommit` → `PreToolUse`**: `PreCommit`은 유효한 Claude Code 훅 이벤트가 아님; 모든 템플릿, 커맨드, 문서에서 `PreToolUse` (matcher: `Bash`)로 교체 (15개 파일)
- **잘못된 deny 패턴**: `Bash(python3 -c:*import os*)` — 패턴 중간의 `:*`가 Claude Code 파서를 깨뜨림; `Bash(python3 -c*import os*)`로 수정
- **잘못된 deny 패턴**: `Bash(curl:* | bash)` 및 `Bash(wget:* | bash)` — 패턴 중간의 `:*`로 settings.json 파싱 실패; glob 와일드카드 `Bash(curl*| bash*)` 및 `Bash(wget*| bash*)`로 수정 (`settings.json` 및 `settings-json-template.md` 양쪽 모두)
- 템플릿 수 참조를 8에서 9로 업데이트 (architecture.md, SKILL.md, onboarding.md, 구조 테스트)
- architecture.md에서 존재하지 않는 `scripts/deploy.sh` 참조 제거
- CLAUDE.md 프로젝트 구조에서 빈 `tools/prompts/` 제거
- `marketplace.json` (1.0.0)과 `plugin.json` (2.0.0) 간 버전 불일치 수정
- 부모 디렉토리에 `CLAUDE.md`가 있는데 하위 디렉토리에서 거짓 경고하는 `check-doc-sync.sh` 버그 수정
- 지나치게 광범위한 AWS Secret Key 패턴으로 인한 시크릿 스캔 거짓 양성 수정
- GitHub Push Protection이 테스트 픽스처를 차단하는 문제 수정 (런타임 조합으로 전환)

### Documentation

- ADR-005: 구현 참조 문서 구조
- ADR-006: `/init-project`을 위한 하이브리드 감지 + 사용자 확인

## [2.0.0] - 2026-04-05

### Added

- 운영 런북을 템플릿 기반으로 생성하는 `/add-runbook` 커맨드 추가 (검증, 롤백 섹션 포함)
- 아키텍처 결정 기록(ADR)을 자동 번호 부여로 생성하는 `/add-adr` 커맨드 추가
- 전체 프로젝트 설정을 검증하는 `/health-check` 커맨드 추가 (건강 점수 0-200, A-F 등급)
- PreCommit 훅(`secret-scan.sh`) 추가: 스테이징된 파일에서 API 키, 비밀번호, 토큰 스캔
- SessionStart 훅(`session-context.sh`) 추가: 세션 시작 시 프로젝트 컨텍스트 로딩
- Notification 훅(`notify.sh`) 추가: 중요 이벤트 시 웹훅 알림 전송
- Git commit-msg 훅 강화: 대소문자 무관 Co-Authored-By 제거 (AI 기여자 배제)
- 생성 프로젝트용 에이전트 템플릿 추가: `code-reviewer`, `security-auditor`
- 생성 프로젝트용 슬래시 커맨드 템플릿 추가: `/review`, `/test-all`, `/deploy`
- MCP 설정 템플릿(`.mcp.json`) 추가: GitHub, Slack, PostgreSQL, Playwright 예시 포함
- `onboarding.md` 문서 템플릿 추가: 신규 개발자 온보딩 가이드
- `api-reference.md` 문서 템플릿 추가: API 문서화
- `.env.example` 템플릿 추가: 보안 규칙 적용 (실제 시크릿 미포함)
- `scripts/setup.sh`, `scripts/install-hooks.sh` 템플릿 추가
- `tests/` 디렉토리 구조 생성 (unit, integration) 및 CLAUDE.md 포함
- 이중 언어 전환기, 레이어 기반 컴포넌트, ASCII 박스 다이어그램, 데이터 플로우 요약, 인프라 테이블, 핵심 설계 결정을 포함하는 프로덕션 수준 architecture.md 템플릿 추가
- Unicode 박스 그리기 문자(`┌─┐│└─┘▶▼`)를 사용하는 아키텍처 다이어그램 스타일 가이드 추가
- 다중 레벨 아키텍처 문서 최신성 검사 추가 (컴포넌트 동기화, 다이어그램 정확성, 레이어 커버리지, IaC 테이블, 이중 언어 일관성)
- `doc-sync-checker`에 CLAUDE.md 안티패턴 감지 추가 (500줄 초과, 모호한 지시, 시크릿, 오래된 의존성)
- `doc-sync-checker` 에이전트에 런북 커버리지 검사 추가 (프로젝트 특성에 따라 런북 추천)
- `doc-sync-checker` 에이전트에 ADR 최신성 검사 추가 (오래된 Proposed 상태 ADR 감지)
- `/sync-docs` 커맨드에 런북 감사 단계(Phase 6) 추가
- README.md에 문제 해결(Troubleshooting) 섹션 및 실행 결과 예시 추가
- `.gitignore`, `.editorconfig`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` 추가
- GitHub 이슈 템플릿(버그 리포트, 기능 요청) 및 PR 템플릿 추가

### Changed

- **BREAKING:** `/init-project`가 14단계로 확장 (기존 11단계), 더 완전한 프로젝트 구조 생성
- README.md를 이중 언어(영어/한국어) 형식으로 shields.io 뱃지와 함께 전면 재작성
- `doc-sync-checker` 에이전트를 6개에서 9개 태스크로 확장 (런북, ADR 최신성, 안티패턴)
- settings.json 템플릿을 4개 훅 유형 모두 포함하도록 확장 (SessionStart, PreCommit, PostToolUse, Notification)
- skills-templates.md를 일반 슬래시 커맨드 템플릿 포함하도록 확장
- docs-templates.md를 온보딩, API 참조, .env 템플릿 포함하도록 확장
- SKILL.md를 확장 유형, 안티패턴, 보안 모범 사례 포함하도록 확장
- 설치 안내를 누락된 설정 스크립트 대신 `git clone` 워크플로우로 수정
- `/sync-docs`의 `tree` 명령어를 크로스 플랫폼 호환을 위해 `find`로 교체
- plugin.json의 author를 "Claude Code Plugin"에서 "whchoi98"로 변경
- 모든 매니페스트의 이메일을 whchoi98@gmail.com으로 변경

## [1.0.0] - 2026-03-07

### Added

- 기존 프로젝트의 언어 및 프레임워크를 자동 감지하는 `/init-project` 커맨드 추가 ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- CLAUDE.md 품질을 0-100점(A-F 등급)으로 평가하는 `/sync-docs` 커맨드 추가
- 아키텍처 문서와 루트 CLAUDE.md를 자동 업데이트하는 `/add-module` 커맨드 추가
- 프로젝트 구조 패턴과 컨벤션 지식을 제공하는 `project-scaffolder` 스킬 추가
- 문서 갭 분석을 병렬 실행하는 `doc-sync-checker` 서브에이전트 추가 (model: opus)
- Plan 모드 규칙, PostToolUse 훅, `/sync-docs` 커맨드, Git commit-msg 훅으로 구성된 4단계 자동 동기화 워크플로우 추가
- Plan 모드 연동으로 아키텍처 문서와 ADR이 사전 작성되는 컨텍스트 기반 프로젝트 생성 지원 ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code 마켓플레이스 등록 지원 ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Node.js, Python, Go, Rust, Java/Kotlin 기존 프로젝트 감지 지원
- 생성 프로젝트에 75점 이상만 보고하는 confidence 기반 코드 리뷰 스킬 포함
- 5개 참조 템플릿 파일 제공 (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- 리포지토리를 마켓플레이스 구조로 변경, 플러그인을 `plugins/project-init/` 하위 디렉토리로 이동 ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/whchoi98/project-init/compare/v2.4.0...v3.0.0
[2.4.0]: https://github.com/whchoi98/project-init/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/whchoi98/project-init/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/whchoi98/project-init/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/whchoi98/project-init/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/whchoi98/project-init/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/whchoi98/project-init/releases/tag/v1.0.0
