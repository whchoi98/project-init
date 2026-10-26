# Design: Claude 5.5 Family Alignment

Date: 2026-10-24
Status: Approved by user

## Goal

Align the plugin and its generated harness with the Claude 5.5 family (Opus 5.5, Sonnet 5.5,
Haiku 5.5) without changing the ADR-009 model and effort policy. ADR-009 was written on
2026-09-23, when `sonnet` resolved to Sonnet 5 and `haiku` to Haiku 4.5, so its facts and
the rule reasons built on them are stale. Sonnet 5.5 and Haiku 5.5 also bring a weakness the
prompts do not address yet: at `low` or `medium` effort they sometimes report a change as
done without running a check.

## Verified facts

Fetched on 2026-10-24 from `code.claude.com/docs/en/model-config.md` and `sub-agents.md`, plus
the bundled claude-api migration guide (Sonnet 5.5 and Haiku 5.5 behavioral shifts).

- Opus 5.5, Sonnet 5.5, and Haiku 5.5 all default to `medium` in Claude Code, accept `low`
  through `max`, and cannot turn thinking off.
- Minimum Claude Code versions: Opus 5.5 v2.1.280, Sonnet 5.5 v2.1.284, Haiku 5.5 v2.1.293.
- On the Anthropic API, `opus`, `sonnet`, and `haiku` resolve to the 5.5 models. On Amazon
  Bedrock and Google Cloud, `sonnet` and `haiku` resolve to Sonnet 4.5 and Haiku 4.5; on
  Claude Platform on AWS to Sonnet 4.6 and Haiku 4.5. On Microsoft Foundry, `opus` resolves to
  Opus 4.6, `sonnet` to Sonnet 4.5, and `haiku` to Haiku 4.5. Haiku 4.5 has no effort levels.
- Subagent model order: per-invocation `model`, then frontmatter `model` (`inherit` selects
  the main model), then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main model. The variable alone
  does not move the built-in Explore and Plan subagents; `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`
  (v2.1.257 or later) does, and also overrides frontmatter `model`.
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` sets what `haiku` resolves to, and the model for background
  functionality.
- Frontmatter `effort` overrides the session level in both directions, so it also lowers a
  session the user set to `xhigh` or `max`.

## Decisions (user-confirmed)

1. **Model routing**: agents keep omitting `model`. Haiku 5.5 is documented as an optional,
   team-wide `CLAUDE_CODE_SUBAGENT_MODEL` setting with its provider caveat. No frontmatter pins.
2. **Reviewer effort**: code-reviewer and security-auditor keep inheriting the session level.
   The template tells Sonnet and Haiku users to raise the session with `/effort high` for a
   review that must catch edge cases.
3. **No new ADR**: no contract changes and no earlier ADR is reversed. ADR-009 is unreleased
   and uncommitted, so its Context, decisions 2 and 4, and References are corrected in place
   in both languages. Filename and title stay, because other files reference them.
4. **No release**: entries go under `[Unreleased]`. No version bump, and no commit until the
   user reviews (this spec included).

## Changes

| Group | File | Change |
|-------|------|--------|
| Rules | `plugins/project-init/CLAUDE.md` `## Rules` | Consumer models become Opus 5.5 (default), Sonnet 5.5, Haiku 5.5, with the 4.5 alias resolution on other providers as the reason contracts stay explicit. The command rule's reason "Opus 5 models over-verify and write long otherwise" becomes: a named check bounds verification on Opus and makes Sonnet 5.5 and Haiku 5.5 at `low` or `medium` effort run one at all. The model and effort rule adds that the three 5.5 models default to `medium`, and documents `CLAUDE_CODE_SUBAGENT_MODEL` next to `maxEffortLevel` as an option |
| ADR | `docs/decisions/ADR-009-opus-5-5-harness-alignment.md` | Context: replace "Sonnet 5 or Haiku 4.5 (which has no effort parameter)" with the 5.5 facts and the verification weakness. Decision 2: lower-cost subagents through `CLAUDE_CODE_SUBAGENT_MODEL`, not a pin. Decision 4: the generated verify line and `/test-all` not-run rule. References: add the 2026-10-24 fetch and the Sonnet 5.5 and Haiku 5.5 guidance. Both languages |
| Templates | `.../references/settings-json-template.md` | New `## Optional: Subagent Model` after `## Optional: Team Effort Cap`: when it helps, precedence, Explore and Plan plus `_FORCE`, provider caveat with `ANTHROPIC_DEFAULT_HAIKU_MODEL`, versions, and a JSON block `{"env": {"CLAUDE_CODE_SUBAGENT_MODEL": "haiku"}}`. Documentation only; `/init-project` does not ask for it |
| Templates | `.../references/agents-templates.md` `## Model, effort, and tools` | Point lower-cost subagents to the new settings section. State the `medium` default and the `/effort high` advice, with the reason not to pin `effort` |
| Templates | `.../references/claude-md-template.md` | After `Verify a change:`, add: run it before reporting a change done; a syntax-only check or a command that failed to start does not count; if it cannot run here, say which check was skipped and why |
| Templates | `.../references/skills-templates.md` (generated `/test-all`) | A suite whose command cannot start (missing tool or dependencies) is reported as not run, with the error, never as passed |
| Commands | `plugins/project-init/commands/init-project.md` | The verify-on-stop option's "most useful with smaller models" names the reason: Sonnet or Haiku at `low` or `medium` effort sometimes reports a change done without running a check |
| Script | `plugins/project-init/scripts/harness-check.sh` `compat-model-ids` | Also flag pins to the superseded 5.0 IDs `claude-opus-5`, `claude-sonnet-5`, and `claude-fable-5` (bare, or followed by `[`, `@`, `:`, `-v<digit>`, or a date). `claude-opus-5-5`, `claude-sonnet-5-5`, and `claude-fable-5-1` stay unflagged |
| Docs | `README.md` (both languages) | Requirements list the 5.5 minimum versions next to `maxEffortLevel`. The doc-sync-checker note's `CLAUDE_CODE_SUBAGENT_MODEL` example names `haiku` for lower cost, with the provider caveat |
| Docs | `CHANGELOG.md` `[Unreleased]` (both languages) | Changed and Added entries for the above |
| Consumers | Any command or agent that reads a changed template (grep the template filename under `plugins/project-init/`) | Update if it restates what changed |

`CONTRIBUTING.md` names "Sonnet 5, Haiku 4.5" as the smaller consumer models; it gets the same model-set fix in both languages (found during execution). `docs/architecture.md` carries no stale model facts and stays unchanged.
No hook script changes, so the `.claude/hooks/` bullet in `docs/architecture.md` stays as it is.

## Testing (written first, seen failing, then implemented)

- `tests/structure/test-harness-check.sh`: an agent pinned to `claude-sonnet-5` gets
  `WARN compat-model-ids`. Agents pinned to `claude-opus-5-5` and `claude-fable-5-1` get
  `PASS compat-model-ids`.
- `tests/structure/test-prompt-contracts.sh`:
  - The plugin rules name Sonnet 5.5 and Haiku 5.5, and no longer give "Opus 5 models over-verify" as the reason.
  - `settings-json-template.md` has `## Optional: Subagent Model`, and its JSON block parses and sets `CLAUDE_CODE_SUBAGENT_MODEL`.
  - `agents-templates.md` cites that heading.
  - The CLAUDE.md template's verify rule and the `/test-all` not-run rule are present.
- Existing checks that read `settings-json-template.md` JSON blocks keep passing with the added block.
- `bash tests/run-all.sh` is green at the end. Changed bilingual docs pass `check-bilingual.py`.

## Out of scope

Model or effort pins in any agent, per-model prompt variants (they would break the single
source rule, ADR-003), renaming ADR-009, a version bump, commits, and changing existing
consumer projects (`/health-check` reports superseded pins; the user decides).
