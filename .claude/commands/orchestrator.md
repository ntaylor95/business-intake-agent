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

## Step 3: Detect and validate the runtime environment (tiered)

Pre-flight checks that the host has *somewhere* to run build commands (npm install, pytest, etc.) before the orchestrator writes any files. Three tiers, checked in order — pick the highest tier that works.

### Tier 1: Docker dev container (preferred when available)

The repo ships with `Dockerfile` + `docker-compose.yml` providing a known-good environment.

```bash
docker --version && docker compose version
```

If both succeed, Docker is available:

1. **Dev service running?**
   ```bash
   docker compose ps --services --filter "status=running" | grep -q '^dev$'
   ```
   If zero, try to start it:
   ```bash
   docker compose up -d
   ```
   If that fails too, fall through to Tier 2 — don't keep the user stuck on a broken Docker install.

2. **Exec works?**
   ```bash
   docker compose exec -T dev true
   ```
   Non-zero → halt with: *"⛔ Cannot exec into the `dev` container. Run `docker compose down && docker compose up -d` and retry."*

Pass `tier=docker` to Step 4. The orchestrator agent wraps all build calls with `docker compose exec -T dev <command>`.

### Tier 2: Host-native tools (fallback when Docker is absent)

If Docker isn't installed, check whether the host has the tools the spec actually needs.

From the validated spec (Step 2), determine required tools:

- **React / Vite / TypeScript spec** → needs `node` (20+) and `npm`
- **Python / FastAPI / MCP / pytest spec** → needs `python3` (3.11+) and `uv`
- **Both** → both sets must be available

Probe:

```bash
node --version 2>/dev/null
npm --version 2>/dev/null
python3 --version 2>/dev/null
uv --version 2>/dev/null
```

If ALL required tools are present with sufficient versions (Node ≥ 20, Python ≥ 3.11), pass `tier=host-native` to Step 4. The agent runs build commands directly on the host shell.

If some required tools are missing or versions are too old, fall through to Tier 3 — do NOT proceed half-equipped.

### Tier 3: Cloud fallback — GitHub Codespaces

If neither Docker nor sufficient host-native tools are available, halt with a friendly handoff to Codespaces. The repo ships with `.devcontainer/devcontainer.json` pre-configured (Node 20, Python 3.11, uv, Claude Code extension auto-installed).

Detect the repo URL:

```bash
git remote get-url origin
```

Parse `<owner>/<repo>` (handles both `https://github.com/<owner>/<repo>.git` and `git@github.com:<owner>/<repo>.git` forms).

Then surface this message to the user verbatim:

> 👋 This build needs Node.js, Python, or Docker — and your computer doesn't have any of them installed yet. **Not a problem.**
>
> **Fastest fix:** open this project in GitHub Codespaces. It's a free, cloud-based dev environment that's already pre-configured for this pipeline.
>
> **Step 1.** Open this URL in your browser:
>
> `https://codespaces.new/<owner>/<repo>?quickstart=1`
>
> **Step 2.** Wait about 30 seconds while Codespaces sets up. Everything you need (Node, Python, Claude Code) is pre-installed.
>
> **Step 3.** Once Codespaces opens, look for the Claude Code icon in the left sidebar. Click it and re-run `/orchestrator <your-spec-path>`. The pipeline will pick up from there.
>
> Your spec, brief, proposal, and decision log are all in this repo already — they'll be there when Codespaces opens.

Halt the orchestrator — do NOT invoke the orchestrator agent. Step 3 ends here for Tier 3.

### Notes on the tier decision

- The chosen tier is passed forward to Step 4 so the orchestrator agent knows whether to wrap commands in `docker compose exec -T dev` (Tier 1) or run them directly (Tier 2). Tier 3 never reaches Step 4.
- **Do not silently downgrade between tiers when a higher tier was *attempted but failed*.** If Tier 1 was attempted (Docker present) but the dev container failed to start with `up -d`, that's a Tier 1 broken state — fall through to Tier 2 only if no Docker daemon is reachable at all.
- **Tier 2 is the realistic default for many developers** (Macs with prior Node/Python installs). Tier 3 is for greenfield machines, especially business users with no dev tooling.

## Step 4: Hand off to the orchestrator agent

Invoke the orchestrator agent via the Agent tool:

- `subagent_type`: `orchestrator`
- `description`: short summary of the spec (3–5 words pulled from the Intent line)
- `prompt`: a self-contained briefing that includes:
  - The absolute path to the validated spec
  - An instruction to run the pipeline per `.claude/agents/orchestrator.md`'s defined order: pm → architect → executor (+ mid-level-engineer as needed) → tester → reviewer → self-update
  - The retry budgets from `CLAUDE.md`: 3 executor retries on tester fail, 2 on reviewer fail
  - The authority model: do NOT auto-commit changes to `.claude/agents/*.md` or `CLAUDE.md`; stage them in a `self-update/<date>-<desc>` git branch and add them to the JIRA artifact at `docs/self-update-<date>-<desc>.md`
  - **Runtime tier from Step 3 (`docker` or `host-native`).** If `tier=docker`, the agent must wrap all environment probes and build calls with `docker compose exec -T dev <command>` (the dev container is already up and exec-tested). If `tier=host-native`, the agent runs commands directly on the host shell — no `docker compose` wrapper. Tier 3 (Codespaces handoff) never reaches Step 4; the user is in a different environment by the time they re-invoke.
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

## Step 6: Auto-invoke usage-report

After surfacing the results in Step 5, **automatically invoke the `usage-report` skill via the Skill tool**. This gives the user a session-end cost / token breakdown plus recommendations without requiring them to remember to run `/usage-report` manually.

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

**When to skip Step 6:**

- If pre-flight failed before the orchestrator agent ran (Step 2 or Step 3 halted), skip — there's nothing meaningful to report. Tell the user: *"Skipping the usage report — the pipeline halted at pre-flight before doing significant work. Run `/usage-report` manually if you want to see the pre-flight cost anyway."*
- If the user explicitly said "skip the usage report" in this session, honor that. Acknowledge: *"Skipping the auto usage report as you requested. You can run `/usage-report` manually any time."*

Otherwise, the auto-invoke fires regardless of whether the pipeline completed cleanly or halted mid-flight. A partial-run cost report is just as useful as a complete-run report for identifying expensive failure modes.

## Notes

- This command is a thin wrapper. The orchestrator agent (`.claude/agents/orchestrator.md`) holds the pipeline logic, retry budgets, and escalation rules. Keep both in sync: if pipeline order or retry budgets change in the agent file, update Step 3's briefing here.
- The host-side container guard in Step 3 is the cheap belt; the orchestrator agent's Step 1 in-container probes are the suspenders. Both exist on purpose — the command guard catches "no container" without burning an agent invocation; the agent's probes catch missing tools *inside* the container.
- Do not run the orchestrator's logic inline — always delegate via the Agent tool so the pipeline runs in its own context window with its own tool allowlist.
