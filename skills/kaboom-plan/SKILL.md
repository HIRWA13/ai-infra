---
name: kaboom-plan
description: "Turn an OpenSpec change, a GitHub ticket, or a plan discussion into a kaboom task queue (prd.json). Use when the user wants to queue work for the kaboom loop. Usage: /kaboom-plan <openspec/changes/NAME | gh:NUMBER | path/to/plan.md | 'this conversation'>"
---

# /kaboom-plan

Produce `prd.json` entries for the `kaboom` loop. The loop picks the first `pending` task with empty `blocked_by`, runs one agent session on it, ticks its checkbox, verifies, and commits per ticket. You only plan; never implement.

## prd.json schema

`{"version":1,"issues":[ ... ]}`. Each issue:

| field | meaning |
|---|---|
| `id` | unique, derived from the source (`<change>-1.2`, `gh-123-03`) so re-runs merge |
| `title` | short label |
| `status` | `pending`, `blocked` (has unmet `blocked_by`), or `done` |
| `blocked_by` | array of issue ids; empty if none |
| `spec` | path to a markdown file with `- [ ]` checkboxes |
| `task` | the checkbox text after `- [ ] ` — verbatim, one task per issue |
| `files` | array of paths in scope (explore the codebase to fill this) |
| `parent` | ticket id grouping tasks; kaboom commits once all tasks of a parent are done |

State is per project, never global. The state dir is `tmp/kaboom/` (gitignored) holding `prd.json`, `progress.txt` and `specs/`. If the project already has `kaboom/` or `ralph/` with a `prd.json`, keep using that; otherwise create `tmp/kaboom/`. Project settings (`VERIFY_CMD` etc.) live in `kaboom/config.env`, which is committed.

## Sources

1. **OpenSpec change** (`openspec/changes/<name>`): the spec is `tasks.md` itself, edited in place by the loop. Every `- [ ] N.M text` line becomes one task: `id = <name>-N.M`, `parent = <name>`, `task = "N.M text"` (everything after `- [ ] `). Skip `- [x]` lines (create no task). Read `proposal.md` and `design.md` for context to fill `files` and `blocked_by`.
2. **GitHub ticket** (`gh:123`): read with `gh issue view 123 --comments`. Write a spec to `tmp/kaboom/specs/gh-123.md`: `# <ticket title>`, a `## Solution` paragraph, then a `- [ ]` checklist of small, independently verifiable steps. `parent = gh-123`, ids `gh-123-01`, `gh-123-02`...
3. **Plan / conversation / markdown file**: same as GitHub, with a slug you choose: `tmp/kaboom/specs/<slug>.md`, `parent = <slug>`.

Specs for sources 2 and 3 live in the project's `tmp/` (never committed). Make sure `tmp/` is in the project's `.gitignore`; if not, tell the user and add it after they agree. OpenSpec `tasks.md` stays where it is.

## Rules for good tasks

- One task = one agent session. Split anything touching many files or needing more than one clear behaviour.
- `blocked_by`: add an id only when the task truly needs the other's output. Tasks with unmet blockers get status `blocked`, otherwise `pending`.
- `files`: real paths found by exploring the code, not guesses. Directories are fine.
- Each task must be verifiable by the project's `VERIFY_CMD` (see `<dir>/config.env`) or by an explicit check the agent can run. If a task can't be, say so.
- Every checkbox must be a complete instruction on its own; the agent sees the spec plus only that one line.

## Procedure

1. Identify the source and read it. If ambiguous, ask.
2. Explore the codebase enough to set `files` and dependencies.
3. If `prd.json` exists, read it. Merge by `id`: keep existing tasks (and all `done` ones) untouched; add new ones; report source lines that no longer exist instead of deleting.
4. Show the user the proposed queue as a table (id, task, blocked_by, files) plus any splits or assumptions. **Wait for confirmation. Do not write before it.**
5. Write `prd.json` (valid JSON, 2-space indent) and any spec file.
6. Run `kaboom-validate`. Fix and re-run until it prints `OK`.
7. Tell the user to run `KABOOM_DRY=1 kaboom` to preview, then `kaboom`.
