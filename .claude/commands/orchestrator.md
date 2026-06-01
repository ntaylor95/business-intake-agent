---
description: Runs the build phase of the D3 pipeline: pm → architect → executor → README. Writes all code files without requiring a local runtime. Run /validate afterwards to run tests and review.
argument-hint: <path-to-spec.md>
args:
  prompt:
    description: Path to a spec file (typically under `docs/`, e.g. `docs/skill_sharing_portal.md`). The spec must follow the 7-section format from the spec-writer skill.
    required: true
version: 1.0.0
---

You are running the `/orchestrator` slash command. The user has handed off a completed spec and wants the full D3 agent pipeline to execute it.

## Step 1: Resolve and validate the spec path

The user provided: `$ARGUMENTS`

1. Strip surrounding quotes and whitespace.
2. If the path is relative, resolve it against the current working directory.
3. If the file does not exist, report the exact path you tried and ask the user to provide a valid spec path. Stop.
4. If the file does not end in `.md`, ask the user to confirm — the spec format is markdown. Stop unless confirmed.

## Step 2: Pre-flight check the spec structure

Read the file. Verify the **7 sections are present in order**:

1. `## Intent`
2. `## Context`
3. `## Success Criteria`
4. `## Failure Modes`
5. `## Task Decomposition`
6. `## Decision Points`
7. `## Handoff Protocol`

If any section is missing or out of order, list which ones and stop. The orchestrator agent will reject the spec at its own pre-flight (per `.claude/agents/orchestrator.md` Step 1), so catching this here saves a round-trip.

Also surface (do not stop on):

- Whether the spec header includes `*Audience: business*` or `*Audience: technical*` — business-track specs may warrant lighter PM scrutiny on measurability per the spec-writer guidance.
- Whether Section 2 (Context) lists **build environment prerequisites** — required for any code-generation spec per `CLAUDE.md`'s "62 files written then npm install failed" rule.
- Whether Section 7 (Handoff Protocol) includes an **executable definition of done** with exit-0 checks — required for code-generation specs.

If any of these are missing on a code-generation spec, warn the user but allow the user to proceed.

## Step 3: Hand off to the orchestrator agent

Invoke the orchestrator agent via the Agent tool:

- `subagent_type`: `orchestrator`
- `description`: short summary of the spec (3–5 words pulled from the Intent line)
- `prompt`: a self-contained briefing that includes:
  - The absolute path to the validated spec
  - An instruction to run the pipeline per `.claude/agents/orchestrator.md`'s defined order: pm → architect → executor (+ mid-level-engineer as needed) → README
  - The authority model: do NOT auto-commit changes to `.claude/agents/*.md` or `CLAUDE.md`; stage them in a `self-update/<date>-<desc>` git branch and add them to the JIRA artifact at `docs/self-update-<date>-<desc>.md`
  - Any explicit user constraints from this turn that aren't already in the spec (e.g., "stop after the executor finishes")

Run the orchestrator agent in the foreground — its results are needed before reporting back to the user.

## Step 4: Report results

When the orchestrator returns, surface to the user:

- **Build results:** files written by the executor, README status, and any framework/language used.
- **Blockers (if any):** spec validation failures, PM clarification requests, or executor failures.
- **Environment variables required:** list every variable from `.env.example` (if present) so the team knows what to fill in before running the project.

Tell the user to run `/validate <spec-path>` as the next step to run tests and review the code.

## Step 5: Auto-invoke usage-report

After surfacing the results in Step 4, **automatically invoke the `usage-report` skill via the Skill tool**. This gives the user a session-end cost / token breakdown plus recommendations without requiring them to remember to run `/usage-report` manually.

Before invoking, tell the user in one line:

> "Pipeline run complete — generating the usage report now. I'll ask you to paste `/usage` output, then write the report with recommendations."

Then invoke:

```
Skill(
  skill: "usage-report",
  args: "post-orchestrator-run; spec=<spec-name-from-Step-1>"
)
```

The `args` string is a hint, not a contract — usage-report uses it to derive the short-name for the output file (e.g., a spec at `docs/refund-router.md` produces `docs/usage-<YYYY-MM-DD>-refund-router.md`) and to skip asking the user "what was this session about." If the spec name doesn't translate cleanly, usage-report falls back to asking the user.

**When to skip Step 5:**

- If pre-flight failed before the orchestrator agent ran (Step 2 halted), skip — there's nothing meaningful to report. Tell the user: *"Skipping the usage report — the pipeline halted at pre-flight before doing significant work. Run `/usage-report` manually if you want to see the pre-flight cost anyway."*
- If the user explicitly said "skip the usage report" in this session, honor that. Acknowledge: *"Skipping the auto usage report as you requested. You can run `/usage-report` manually any time."*

Otherwise, the auto-invoke fires regardless of whether the pipeline completed cleanly or halted mid-flight. A partial-run cost report is just as useful as a complete-run report for identifying expensive failure modes.

## Notes

- This command is a thin wrapper. The orchestrator agent (`.claude/agents/orchestrator.md`) holds the pipeline logic and escalation rules. Keep both in sync: if pipeline order changes in the agent file, update Step 3's briefing here.
- Runtime detection has moved to the `/validate` command. The orchestrator command only needs filesystem access — no runtime probing required.
- Do not run the orchestrator's logic inline — always delegate via the Agent tool so the pipeline runs in its own context window with its own tool allowlist.
