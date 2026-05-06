# O-F-T-S Workflow — Multi-Agent Pipeline

> **Purpose:** Defines the four-agent pipeline for phased project implementation. Each phase or sub-phase becomes one cycle through the pipeline. The human operator passes handoff documents between agents and makes approval decisions at checkpoints.

---

## Pipeline Overview

```text
O (Orchestrator)
|  runs pre-flight checks
|  creates issue + branch
|  writes issue body with acceptance criteria
v
F (Feature Implementor)
|  reads issue, executes the work
|  runs Tier 1 + Tier 2 verification
|  writes handoff-F.md
v
T (Tester)
|  reads handoff-F.md, runs independent Tier 1 + Tier 2 verification
|  writes handoff-T.md
v
S (Spec Auditor)
|  reads handoff-T.md + handoff-F.md + issue
|  runs Tier 3 spec compliance + quality audit
|  writes handoff-S.md
v
O (Orchestrator)
   reads handoff-S.md
   decision: commit OR file new issue for rework
```

The human operator is the relay between agents. The human copies the relevant handoff document path into the next agent's prompt. The human does not need to interpret the handoff unless they want to; the receiving agent reads it directly.

---

## When to Use Full vs Shortened Pipelines

| Pipeline | When | Example |
|----------|------|---------|
| **O -> F -> T -> S -> O** | Work that produces user-facing output | UI, API endpoints, features with business logic |
| **O -> F -> T -> O** | Infrastructure with no user-facing output to audit | Schema, config, scaffolding, CI/CD setup |
| **O -> T -> S -> O** | Pure audit pass, no new code | Cross-cutting verification, final review |

---

## Agent Roles and Boundaries

| Agent | Can do | Cannot do |
|-------|--------|-----------|
| **O** Orchestrator | Create issues, create branches, read handoffs, commit, make approval decisions, update the build plan | Write implementation code, run verification commands |
| **F** Feature Implementor | Read issues and specs, write code, run Tier 1 + Tier 2 verification, stage files | Commit, push, create PRs, skip verification |
| **T** Tester | Read handoff-F, run independent Tier 1 + Tier 2 checks, flag failures | Write code, fix failures, run Tier 3 checks, commit |
| **S** Spec Auditor | Read all handoffs + issue, run Tier 3 spec compliance + quality audit | Write code, fix issues, commit, proceed if T has blockers |

---

## Verification Tiers

| Tier | Owner | Speed | What it checks |
|------|-------|-------|---------------|
| **Tier 1** | F, then T | Instant (1-10s) | Build, lint, existing tests, server starts, API smoke |
| **Tier 2** | F, then T | Fast (10-60s) | Test coverage, type safety, error handling, data integrity, API contracts, security basics |
| **Tier 3** | S only | Thorough (1-5 min) | Spec compliance, quality audit, UI/UX match, accessibility, code organization, security review |

F runs Tier 1 + 2 before writing the handoff. T independently re-runs Tier 1 + 2. S only runs Tier 3 and only after T reports zero blockers.

---

## Handoff Documents

All handoffs live in:

```text
docs/handoffs/
```

They are coordination artifacts, not project documentation. Delete them after the phase commits.

Naming convention:

```text
phase-[N]-[slug]-[agent].md
```

Where `[agent]` is `F`, `T`, or `S`.

Rework rounds append:

```text
phase-[N]-[slug]-F-rework.md
phase-[N]-[slug]-F-rework-2.md
```

---

## Issue Template

O creates one GitHub issue per pipeline cycle.

```markdown
## Phase [N] - [Title]

**Branch:** [branch-name]

### Objective
[One sentence describing the deliverable]

### Input documents
Read these before starting:
- [ ] [Spec section path and section name]
- [ ] [Build plan phase reference]
- [ ] [Any additional doc references]

### Acceptance criteria
[Copied from the build plan phase, as checkboxes]

### Handoff location
Write your handoff to: `docs/handoffs/phase-[N]-[slug]-F.md`

### Operating rules
- Read all input documents before writing code
- Follow project conventions (check existing code patterns)
- Read source files before referencing types, schemas, or APIs
- Run Tier 1 + Tier 2 verification before writing the handoff
- Stage files by explicit path, never `git add .`
```

---

## Project Files Expected

These files should exist in the project repository before the pipeline starts:

| File | Purpose | Created by |
|------|---------|-----------|
| `docs/planning/SPEC.md` | Project specification — the source of truth for what to build | Human or O |
| `docs/planning/BUILD_PLAN.md` | Phased build plan with acceptance criteria per phase | Human or O |
| `docs/handoffs/` | Directory for ephemeral handoff documents | O (created on first phase) |
| `CLAUDE.md` | Project-level instructions for AI agents (optional but recommended) | Human |

If any are missing, O's pre-flight checks will flag them.

---

## Rework Flow

When S returns a REWORK verdict:

1. O reads the S handoff and creates a new GitHub issue titled:
   `Rework: Phase [N] - [specific problem]`
2. The rework issue references the original issue and quotes the S findings.
3. F reads the rework issue and fixes the problems on the same branch.
4. F writes a new handoff: `phase-[N]-[slug]-F-rework.md`
5. The cycle resumes at T, who re-runs verification on the changed files.
6. If S passes on the second round, O commits.
7. If S returns REWORK again, repeat.
8. If a phase requires more than two rework cycles, O should pause and consult the human about whether the acceptance criteria or spec need revision.

---

## Quick Reference for the Human Operator

### Starting a Cycle

1. Open the O session.
2. Tell O: `Open Phase [N].`
3. O runs pre-flight checks, creates the issue and branch.
4. Open a new agent session with F.
5. Tell F: `Read issue #[N] and execute on branch [branch-name].`
6. When F finishes, it tells you where the handoff is.
7. Open a new agent session with T.
8. Tell T: `Read the F handoff at docs/handoffs/phase-[N]-[slug]-F.md and verify.`
9. When T finishes and reports no blockers, open a new agent session with S.
10. Tell S: `Read the T handoff at docs/handoffs/phase-[N]-[slug]-T.md and audit.`
11. When S finishes, return to O.
12. Tell O: `S has completed. Handoff is at docs/handoffs/phase-[N]-[slug]-S.md. Review and proceed.`

### If T Finds Blockers

Return to F (same session if still open, or new session).

Tell F:
`T found blocking issues. Read docs/handoffs/phase-[N]-[slug]-T.md and fix the reported problems.`

### If S Returns REWORK

Return to O. O creates a rework issue and hands back to F.

### Approval Checkpoints

At phases marked as checkpoints in the build plan, O presents a summary and waits for the human's explicit approval before proceeding to the next phase. O must never infer approval from prior context.
