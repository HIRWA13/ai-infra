---
name: crucible
description: "Fan-out + harsh critic loop for every substantive task. Supports three modes: build (fan-out builders + critic), audit (critics only on existing code), and spec (spec file as frozen rubric). Scoping flags let you target a file, function, component, or current branch diff. Passes only on an explicit verdict — never vibes."
---

# /crucible

Every substantive task enters the crucible. Nothing ships until a blind critic explicitly passes it.

**Non-negotiable**: permanent opt-in to multi-agent orchestration (Workflow tool / ultracode). Activates on every substantive task automatically.

---

## Modes

Three modes cover every scenario — building new, reviewing existing, or working from a spec.

### `--build` (default)
Fan-out builders in parallel → blind critic judges output → loop until pass.
Use when: starting or continuing work on a feature, fix, or component.

### `--audit`
No builders. Critics only. Send existing code straight to the critic loop.
Use when: you've already written something and want it judged — a function, a file, a component, or a whole feature branch.

### `--spec <file>`
The spec file becomes the frozen rubric at Step 0. The critic checks implementation against every spec criterion line by line.
Use when: you're in a spec-driven workflow (`/sc:implement`, PRD-based, or your own spec file) and want to gate completion against the spec rather than vibes.

These modes compose:
```
/crucible --audit --spec auth.spec.md --target src/auth/
```
→ audit existing `src/auth/` code against `auth.spec.md` with no new builders.

---

## Targeting

By default crucible operates on the current task scope. Narrow it with:

| Flag | Scope | Git equivalent |
|------|-------|---------------|
| `--target <path>` | File, directory, or glob — `src/Button.tsx`, `src/auth/`, `src/**/*.test.ts` | — |
| `--target <symbol>` | Named function or component — `validateUser`, `AuthModal` | — |
| `--staged` | Changes in the index, not yet committed | `git diff --cached` |
| `--unstaged` | Working tree changes not yet staged | `git diff` |
| `--staged --unstaged` | Everything modified since last commit — staged + unstaged combined | `git diff HEAD` |
| `--diff` | Current branch changes vs default base (`main`) | `git diff main` |
| `--diff <base>` | Changes since a specific base — `--diff origin/main`, `--diff HEAD~3` | `git diff <base>` |

Targeting works in all three modes. The critic receives only what's in scope — it never sees the full project unless no target is given.

---

## Step 0 — Write the reference before building or auditing

No reference, no verdict. If you can't define "wow" for this scope, stop and clarify first.

Pick one, in order:

1. **Real thing** (copy/parity): the actual product being matched — blind side-by-side
2. **Best-in-class analog** (new work): named explicitly — judged side-by-side, not copied
3. **Spec file** (`--spec`): the spec IS the reference — critic checks each criterion
4. **Frozen rubric** (nothing comparable): concrete acceptance criteria written on the critic side before work starts — builder cannot negotiate it down

---

## The loop

### 1. Decompose and fan out (`--build` only)

Independent units → one builder sub-agent per unit → run in parallel via the Workflow tool.

**Variant tournament** — run whenever the unit is judgment-heavy (design, approach, UX, content):
- Default: **2 competing builders** on the same unit
- `--high-stakes`: **3 competing builders**

**Skip-tournament checklist** — all three must be true to skip:
- [ ] Approach is unambiguous (only one sensible solution path)
- [ ] No design or UX tradeoffs in scope
- [ ] Output is fully deterministic given the input

If any box is unchecked, run the tournament.

In `--audit` mode step 1 is skipped entirely — the existing code goes straight to step 2.

### 2. Critic is separate and blind

- Had no part in building and never sees builder reasoning — receives: scoped deliverable + reference only
- For tournaments: outputs labeled A/B in random order (critic doesn't know which is ours)
- `--high-stakes`: use a **different model family** for the critic — same-model critics share blind spots with same-model builders. In `--audit` mode this is the only effect (no builders to multiply); in `--build` mode it also bumps variants to 3

### 3. Pass threshold — concrete, not vibes

"Acceptable" is a FAIL. "Pretty good" is a FAIL. The critic names exactly why it passes or fails against the reference.

| Work type | Pass condition |
|-----------|---------------|
| Copy/parity | Blind side-by-side: critic can't tell which is the reference, or picks ours |
| New feature | Every rubric/spec criterion met; cold first-time-user test passes |
| Bug fix | Attacker can't re-break the fix; regression test fails with the bug present |
| Performance | Every numeric target from the pre-build budget is met |
| Docs | Critic follows them cold; zero moments of confusion on first read |
| Security/quality | Adversarial reviewer finds no inputs, races, or edge cases that break the invariant |
| Spec audit | Every spec criterion has a corresponding implementation; no criterion is partially met |

### 4. Loop until pass

Builder revises against the critic's named findings. Fresh critic re-judges cold each round — no memory, no accumulated goodwill.

**Disagreeing critics rule** — if critics split (e.g. 1-1):
- Escalate to a 3rd critic: *"Critic A said [X]. Critic B said [Y]. Adjudicate with concrete evidence."*
- 3rd verdict is final for that round.

### 5. Stall rule

If **3 consecutive rounds** produce no improvement on the critic's named criteria:
- Stop — report **BLOCKED**
- Include: last verdict, evidence, and exactly what's missing (asset, tool, or decision needed from Junior)
- Detect by comparing successive verdicts in `/tmp/<task>/critique/` — identical named findings = stall
- Never silently lower the bar to exit the loop

### 6. Evidence or it didn't happen

Every critic verdict ships with artifacts: screenshots, diffs, metrics, A/B result.
- Store under `/tmp/<task>/critique/`
- Reference exact paths in the final report
- Never commit to the repo

---

## Critic weapon by work type

| Work type | Reference | Critic stance |
|-----------|-----------|--------------|
| Copy/parity | Real product | Blind visual + behavioral side-by-side |
| New feature | Named best-in-class + frozen rubric | Cold first-time user; variant tournament always unless checklist clears |
| Bug fix | The repro | Attacker: re-break, probe neighbors, verify regression test fails with bug present |
| Performance | Numeric budget (pre-build) | Reads only the numbers |
| Docs | None (critic IS the user) | Follows cold; first confusion is a FAIL |
| Security/quality | Threat model | Adversarial: inputs, races, edge cases |
| Spec audit | Spec file | Line-by-line: every criterion accounted for, no partial credit |

---

## Solo (no fan-out) — allowed only for

- Conversational answers
- Trivial mechanical edits (single-line typo, rename with no tradeoffs)
- Pure reading/investigation that fits in one context

When in doubt, fan out.

---

## Usage

```
# Build modes
/crucible                                      # build — standard (2 variants, same-model critic)
/crucible --high-stakes                        # build — 3 variants + cross-model critic
/crucible --audit --high-stakes               # audit — cross-model critic only (no builders to multiply)
/crucible --skip-tournament                    # build — must pass all 3 checklist items

# Audit existing code
/crucible --audit                              # audit everything in current task scope
/crucible --audit --target src/Button.tsx      # audit a specific file
/crucible --audit --target validateUser        # audit a specific function
/crucible --audit --target src/auth/           # audit a directory
/crucible --audit --staged                     # audit only what's staged (git diff --cached)
/crucible --audit --unstaged                   # audit only unstaged working tree changes
/crucible --audit --staged --unstaged          # audit everything modified since last commit
/crucible --audit --diff                       # audit current branch changes only
/crucible --audit --diff origin/main           # audit changes since origin/main

# Spec-based
/crucible --spec auth.spec.md                  # build against a spec file
/crucible --audit --spec auth.spec.md          # audit existing code against spec
/crucible --audit --spec auth.spec.md --target src/auth/   # targeted spec audit

# Combinations
/crucible --audit --diff --high-stakes         # cross-model critic on branch diff
/crucible --spec prd.md --target src/feature/  # build one feature scoped to spec
```
