---
description: Runs the validation phase of the D3 pipeline: tester → reviewer → self-update. Requires a runtime environment. Run after /orchestrator has written the code.
argument-hint: <path-to-spec.md>
args:
  prompt:
    description: Path to the spec file used to build the project (typically under `docs/`). Used to load success criteria and failure modes for the tester and reviewer agents.
    required: true
version: 1.0.0
---

You are running the `/validate` slash command. The user has already run `/orchestrator` and has written code that needs to be tested and reviewed.

## Step 1: Resolve and validate the spec path

The user provided: `$ARGUMENTS`

1. Strip surrounding quotes and whitespace.
2. If the path is relative, resolve it against the current working directory.
3. If the file does not exist, report the exact path you tried and ask the user to provide a valid spec path. Stop.

## Step 2: Detect and validate the runtime environment (tiered)

Checks that the host has somewhere to run build commands (npm test, pytest, tsc, etc.) before invoking any agents. Three tiers, checked in order — pick the highest tier that works.

### Tier 1: Docker dev container (preferred when available)

```bash
docker --version && docker compose version
```

If both succeed, Docker is available:

1. **Dev service running?**
   ```bash
   docker compose ps --services --filter "status=running" | grep -q '^dev$'
   ```
   If not running, try to start it:
   ```bash
   docker compose up -d
   ```
   If that fails, fall through to Tier 2.

2. **Exec works?**
   ```bash
   docker compose exec -T dev true
   ```
   Non-zero → halt with: *"⛔ Cannot exec into the `dev` container. Run `docker compose down && docker compose up -d` and retry."*

Pass `tier=docker` to Step 3.

### Tier 2: Host-native tools (fallback when Docker is absent)

Read the spec to determine required tools:
- **React / Vite / TypeScript** → needs `node` (20+) and `npm`
- **Python / FastAPI / MCP / pytest** → needs `python3` (3.11+) and `uv`
- **Both** → both sets must be available

Probe:
```bash
node --version 2>/dev/null
npm --version 2>/dev/null
python3 --version 2>/dev/null
uv --version 2>/dev/null
```

If all required tools are present with sufficient versions, pass `tier=host-native` to Step 3.

If any required tools are missing or wrong version, fall through to Tier 3.

### Tier 3: Cloud fallback — GitHub Codespaces

If neither Docker nor sufficient host-native tools are available, halt and surface a Codespaces handoff:

```bash
git remote get-url origin
```

Parse `<owner>/<repo>` from the remote URL (handles both https and ssh forms).

Then surface this message verbatim:

> 👋 Running tests requires Node.js, Python, or Docker — and your computer doesn't have any of them installed yet. **Not a problem.**
>
> **Fastest fix:** open this project in GitHub Codespaces. It's a free, cloud-based environment that's already pre-configured for this pipeline.
>
> **Step 1.** Open this URL in your browser:
>
> `https://codespaces.new/<owner>/<repo>?quickstart=1`
>
> **Step 2.** Wait about 30 seconds while Codespaces sets up. Everything you need (Node, Python, Claude Code) is pre-installed.
>
> **Step 3.** Once Codespaces opens, look for the Claude Code icon in the left sidebar. Click it and re-run `/validate <your-spec-path>`. The pipeline will pick up from there.
>
> Your code, spec, and proposal are all in this repo already — they'll be there when Codespaces opens.

Halt here — do NOT invoke the validate agent. Step 2 ends here for Tier 3.

## Step 3: Hand off to the validate agent

Invoke the validate agent via the Agent tool:

- `subagent_type`: `validate`
- `mode`: `bypassPermissions`
- `description`: short summary (3–5 words from the spec Intent)
- `prompt`: a self-contained briefing that includes:
  - The absolute path to the spec
  - An instruction to run: tester → reviewer → self-update per `.claude/agents/validate.md`
  - Retry budgets: 3 executor retries on tester fail, 2 on reviewer fail
  - The authority model: do NOT auto-commit changes to `.claude/agents/*.md` or `CLAUDE.md`; stage them in a `self-update/<date>-<desc>` git branch and add them to the JIRA artifact at `docs/self-update-<date>-<desc>.md`
  - **Runtime tier** (`docker` or `host-native`) so the agent wraps build/test commands correctly. If `tier=docker`, wrap all commands with `docker compose exec -T dev <command>`. If `tier=host-native`, run directly.

Run the agent in the foreground.

## Step 4: Report results

When the validate agent returns, surface to the user:

- **Test results:** pass/fail counts, any failures with detail
- **Reviewer verdict:** APPROVED or CHANGES REQUIRED (with required changes listed)
- **Success criteria verification trail:** which Section 3 criteria are VERIFIED (exit-code-0 evidence) and which are NOT VERIFIED or FAILED
- **Self-update artifact (if produced):** path to `docs/self-update-<date>-*.md` and a summary. If protected-tier changes were staged, name the git branch.

If any criterion is NOT VERIFIED or FAILED, report `VALIDATION BLOCKED` — not complete.

## Step 5: Auto-invoke usage-report

After reporting results, automatically invoke the `usage-report` skill:

Before invoking, tell the user:
> "Validation complete — generating the usage report now."

Then invoke:
```
Skill(
  skill: "usage-report",
  args: "post-validate-run; spec=<spec-name-from-Step-1>"
)
```

Skip if pre-flight failed before the agent ran (Step 2 Tier 3 halt). Tell the user: *"Skipping usage report — validation halted at pre-flight."*
