---
description: Hands a completed 7-section spec to the orchestrator agent, which runs the full pm → architect → executor → tester → reviewer → self-update pipeline end-to-end.
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

## Step 3: Pre-flight check the runtime environment (host-side guard)

This pipeline runs *inside* the Docker `dev` container per `CLAUDE.md` (Node 20, npm, git, curl, `uv` pre-installed). Probing on the host is the failure mode CLAUDE.md cites — the host typically has a different Node version (or none), `uv` is missing, etc.

Run these guards before invoking the orchestrator agent — they fail fast without spending an agent invocation.

1. **Dev service running?**
   ```bash
   docker compose ps --services --filter "status=running" | grep -q '^dev$'
   ```
   Non-zero → halt:
   > ⛔ Cannot start pipeline. The `dev` service is not running.
   > Run `docker compose up -d` from the repo root, then re-invoke `/orchestrator`.

2. **Exec works?**
   ```bash
   docker compose exec -T dev true
   ```
   Non-zero → halt:
   > ⛔ Cannot exec into the `dev` container. Run `docker compose down && docker compose up -d` and retry.

Pass the container-up confirmation forward in Step 4's briefing — the orchestrator agent must run its own pre-flight probes via `docker compose exec -T dev <command>`, not on the host.

## Step 4: Hand off to the orchestrator agent

Invoke the orchestrator agent via the Agent tool:

- `subagent_type`: `orchestrator`
- `description`: short summary of the spec (3–5 words pulled from the Intent line)
- `prompt`: a self-contained briefing that includes:
  - The absolute path to the validated spec
  - An instruction to run the pipeline per `.claude/agents/orchestrator.md`'s defined order: pm → architect → executor (+ mid-level-engineer as needed) → tester → reviewer → self-update
  - The retry budgets from `CLAUDE.md`: 3 executor retries on tester fail, 2 on reviewer fail
  - The authority model: do NOT auto-commit changes to `.claude/agents/*.md` or `CLAUDE.md`; stage them in a `self-update/<date>-<desc>` git branch and add them to the JIRA artifact at `docs/self-update-<date>-<desc>.md`
  - Confirmation that the dev container is running and `docker compose exec` works — the agent must run all environment probes (and any other host-tool calls) inside the container with `docker compose exec -T dev …`
  - Any explicit user constraints from this turn that aren't already in the spec (e.g., "skip the self-update step", "stop after the executor finishes")

Run the orchestrator agent in the foreground — its results are needed before reporting back to the user.

## Step 5: Report results

When the orchestrator returns, surface to the user:

- **Success criteria verification trail:** which Section 3 criteria were verified (with exit-code-0 evidence per the spec's Handoff Protocol) and which failed or were skipped.
- **Blockers (if any):** missing prerequisites caught at pre-flight, retry-budget exhaustion, reviewer rejections, environment failures (e.g., missing runtime, permission denied on a runner tool).
- **Self-update artifact (if produced):** path to `docs/self-update-<date>-*.md` and a one-line summary of what changed. If the artifact staged any protected-tier changes (rules or agent definitions), name the git branch where they're staged.
- **Final output destination (if reached):** the deployed URL, file path, or other artifact location named in the spec's Section 7 Final Output subsection.

If the pipeline halted mid-flight (self-update flagged a protected-tier change requiring sign-off, or a runner-tool blocker the orchestrator could not resolve), explain:

- Exactly what's needed to unblock
- What the user should run next (e.g., `/jira-ticket docs/self-update-<date>-<slug>.md`, manual branch review, fixing a missing runtime, etc.)

## Notes

- This command is a thin wrapper. The orchestrator agent (`.claude/agents/orchestrator.md`) holds the pipeline logic, retry budgets, and escalation rules. Keep both in sync: if pipeline order or retry budgets change in the agent file, update Step 3's briefing here.
- The host-side container guard in Step 3 is the cheap belt; the orchestrator agent's Step 1 in-container probes are the suspenders. Both exist on purpose — the command guard catches "no container" without burning an agent invocation; the agent's probes catch missing tools *inside* the container.
- Do not run the orchestrator's logic inline — always delegate via the Agent tool so the pipeline runs in its own context window with its own tool allowlist.
