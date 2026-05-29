# AI Pipeline: From Idea to Working Software

> Describe your idea in plain language. A team of AI agents asks the right questions, writes the spec, builds the code, tests it, reviews it, and stages improvements back to the team.

This repo gives you a complete AI development pipeline with **two entry points**, depending on how you think about your idea:

- **`/business-intake`** *(recommended for non-technical users)* — a plain-language interview about the problem you want to solve. The skill drafts a short business proposal you can share with stakeholders, then automatically produces the technical spec for you. **You never write the spec yourself.**
- **`/spec-writer`** *(for technical users)* — a section-by-section interview that produces the spec directly.

Either path produces the same artifact: a structured 7-section plan called a **spec**. You hand the spec to the orchestrator, and a team of specialized AI agents takes it through the build.

Vague prompts produce vague software. The pipeline is designed so the vague-to-clear conversion happens up front — once, with you — and everything downstream runs from a precise plan.

---

## Who this is for

You should be comfortable with the following before starting:

- Using a terminal (running commands, reading the output)
- Reading and editing files in a code editor (VS Code, Cursor, etc.)
- The general idea that a project lives in a folder, and `git` keeps a history of changes to that folder

You **do not** need to know how to write code in the language your project will be in. The pipeline does that. For non-technical users, `/business-intake` will write the spec for you too — you describe the problem in plain language and review the result before the build starts.

---

## What you need installed before you start

| Tool | Why | If you don't have it |
|---|---|---|
| **Claude Code** | Runs the pipeline. | https://docs.claude.com/claude-code |
| **Docker Desktop** | Provides the dev environment (Node, npm, git, everything else). You don't need to install Node or React on your machine — the container has them. | https://www.docker.com/products/docker-desktop |
| **git** (on the host) | For cloning this repo and committing your work. | https://git-scm.com/downloads |
| **Atlassian CLI (`acli`)** | Optional — only needed if you want the pipeline to file JIRA tickets automatically. | The pipeline will show you install instructions when you get there. |

### Starting the dev container

The repo includes a `Dockerfile` and `docker-compose.yml` that give you Node 20, npm, git, and everything needed to scaffold React apps. From the repo root:

```bash
docker compose up -d                  # Start the container in the background
docker compose exec dev bash          # Open a shell inside it
```

Once inside, you can scaffold a React + TypeScript + Vite project:

```bash
npm create vite@latest my-app -- --template react-ts
cd my-app && npm install
npm run dev                            # Vite dev server at http://localhost:5173
```

The container has a volume mount for the repo root, so files you create inside `/workspace` show up on your host machine immediately (and vice versa).

---

## The big picture

```
1. You describe your idea
   In plain language?   →  business-intake (produces proposal + spec for you)
   In spec format?      →  spec-writer (section-by-section interview)
2. The pipeline takes over                      →  orchestrator
3. Build, test, review                          →  pm → architect → executor → tester → reviewer
4. Reflect on what was learned                  →  self-update
5. File the learnings back to the team          →  jira-ticket
```

You stay in the loop in three places: **the interview / proposal review** at the start, **any sign-off** the orchestrator asks for in the middle, and **filing learnings** at the end. Between those, the agents handle everything.

---

## Quick start: one full run

Here's the entire flow, end to end.

### 1. Start the conversation

Choose your entry point.

#### Option A — Plain-language interview *(recommended for non-technical users)*

In Claude Code, type:

```
/business-intake
```

You'll answer roughly 20 plain-language questions about the problem you want to solve — what's painful today, who uses it, what inputs and outputs are involved, what's NOT in scope. You will **not** be asked about technology, frameworks, hosting, login, environment variables, or any other "how it's built" question. Those decisions get made for you.

When the interview is complete, business-intake drafts a short **business proposal** you can review and share with stakeholders. After you confirm it, the skill writes a structured **business brief** and hands off to spec-writer in brief-driven mode (silently — no further questions for you). Spec-writer reads the brief and produces the full 7-section spec plus a **decision log** showing every technical choice that was made on your behalf.

You'll end up with four files in `docs/`:

1. `<name>-business-proposal.md` — the stakeholder doc you reviewed
2. `<name>-business-brief.md` — the structured handoff (you don't need to read this)
3. `<name>.md` — the spec the orchestrator will run
4. `<name>-decisions.md` — what was chosen on your behalf, with rationale + override paths

**Review the decision log before invoking the orchestrator.** It's your safety net for catching anything that was inferred wrong. Anything you don't agree with, you can edit the spec directly OR re-run with a refined brief.

#### Option B — Section-by-section spec authoring *(for technical users)*

In Claude Code, type:

```
/spec-writer
```

The spec-writer agent will ask: *"What are we building?"* Answer in your own words.

You'll go through 7 short sections. After each one the agent shows you what it captured so you can correct it before moving on:

1. **Intent** — What does winning look like?
2. **Context** — What's the starting state? What constraints apply?
3. **Success Criteria** — How will you know it worked?
4. **Failure Modes** — What can go wrong, and what should happen when it does?
5. **Task Decomposition** — The ordered steps to build it.
6. **Decision Points** — Where the pipeline needs to make a judgment call.
7. **Handoff Protocol** — How the pieces fit together and what "done" looks like.

When all seven sections are confirmed, the spec is saved to `docs/<your-spec-name>.md`. The spec-writer will tell you the full path. A decision log is also written alongside the spec at `docs/<your-spec-name>-decisions.md`, capturing the defaults applied and any pushback you gave during the interview.

**Tip:** the more specific you are, the better the build. Pushy follow-ups from spec-writer are not nitpicking — they're closing the gaps that would otherwise become bugs.

### 2. Hand the spec to the orchestrator

Type:

```
/orchestrator docs/<your-spec-name>.md
```

For example: `/orchestrator docs/my_feature.md`.

The orchestrator will:

1. **Validate the spec** — checks all 7 sections are present.
2. **Run a pre-flight check** — confirms the tools your project needs are installed.
3. **Run the pipeline** — pm → architect → executor → tester → reviewer → self-update, in that order, looping back on failures.

If a required tool is missing, the orchestrator stops and tells you exactly what to install. Install it, re-run the command, and the pipeline picks up where it left off.

You can do other work while it runs. The orchestrator surfaces progress and only interrupts you when it actually needs you.

### 3. Read the final report

At the end you'll see one of two outcomes:

#### ✅ Pipeline Complete

Every criterion in your spec is verified. The code is ready.

#### ⚠ Pipeline Blocked

Something needs your input. The orchestrator is **honest** about partial progress — if a test couldn't run (missing tool, permission denied, etc.), it says so explicitly. Don't read "blocked" as "broken" — usually it just means there's one thing for you to do before the pipeline can finish.

Follow the "Required user actions" list in the blocked report, then re-run `/orchestrator` on the same spec.

### 4. File the self-update artifact

After every run, the self-update agent looks back and asks: *"Did we learn anything?"*

If yes, it writes a file at `docs/self-update-<date>-<short-description>.md`. This is the **feedback to the team** file — it contains improvements to the pipeline itself (a skill that needs updating, a rule that's now wrong, an agent definition that's missing an edge case).

To file the JIRA ticket from it:

```
/jira-ticket docs/self-update-<date>-<short-description>.md
```

The jira-ticket agent reads the file, builds a structured ticket with diffs and reasoning, asks you to confirm, and creates it. You get a JIRA link.

If you'd rather file it later, the file stays in `docs/` until you do.

---

## What if something goes wrong?

| You see this | What it means | What to do |
|---|---|---|
| **Pipeline halted at pre-flight** | A required tool isn't installed (Node, Python, etc.) | Install whatever it names. Re-run `/orchestrator`. |
| **Tests failed after 3 executor attempts** | The agents tried to fix the code three times and tests still failed. | Read the tester's report. Often the spec was vague about a behavior. Clarify the spec and re-run. |
| **BLOCKED — cannot execute tests** | The tester couldn't run tests at all (missing runner, permission denied). | Check the message. Usually means installing a test runner or adjusting permissions in `.claude/settings.local.json`. |
| **Changes to rules/agent definitions have been staged** | The self-update agent wants to update the pipeline itself. It put the change in a git branch — your code is untouched. | Run `/jira-ticket` to file it. The team will review and merge into the source repo. |
| **Spec is not ready for execution** | The spec is missing a required section or has unmeasurable success criteria. | Run `/spec-writer` again to fix what's flagged, then re-run `/orchestrator`. |

When in doubt: **the report is honest, read it carefully**. The orchestrator never marks unverified work as "complete."

---

## How learnings flow back to the team

Your local repo is **disposable**. When the next project starts, you'll get a fresh seed from the team's source-of-truth repo. The JIRA ticket is the only path by which a learning becomes permanent.

The full loop:

1. You run the pipeline in your repo.
2. The self-update agent notices something that should change — a skill, a rule, an agent definition.
3. **Locally**, it applies skill/spec changes right away so the rest of your session benefits. For protected files (rules, agent definitions), it stages the change in a git branch — your main code is untouched.
4. **For the team**, it writes everything to `docs/self-update-<date>-<short-description>.md` — categorized, with diffs, with reasoning.
5. You run `/jira-ticket docs/self-update-<date>-<short-description>.md`.
6. The agent creates a structured JIRA ticket with the proposed diffs.
7. The team reviews the ticket. If approved, they merge the change into the source repo.
8. Next time someone seeds a new repo, the improvement is included.

---

## Coding standards

The pipeline uses a single source of truth for coding standards: **`CLAUDE.md`**. This file is loaded every time the agents run. When the reviewer agent checks code, it checks against the standards in `CLAUDE.md`.

> **Coding standards content is being built out.** Sections coming: language-specific patterns, naming conventions, testing conventions, security checklist. As standards are added to `CLAUDE.md`, they automatically apply to every project using this pipeline.

If you discover a standard the team should add — for example, "always use early returns instead of nested conditionals" — note it down. The self-update agent can propose it as a rule change, and your `/jira-ticket` run will file it back to the team.

**Important:** don't edit `CLAUDE.md` directly to add a standard. That change would die when your repo ends. File it via JIRA so the team can apply it to the source.

---

## What lives where

You'll mostly only touch `docs/`. Everything else is the pipeline's machinery.

- **`docs/`** — Your specs and self-update artifacts. This is **your** folder.
- **`CLAUDE.md`** — The rules. Loaded automatically by Claude Code every session. Tells the agents what they can and can't change autonomously.
- **`.claude/agents/`** — One file per agent. Each describes the agent's job, its tools, and how it hands off to the next agent.
- **`.claude/skills/`** — On-demand processes (`business-intake`, `spec-writer`, `architecture-pattern-selector`, `readme-skill`).
- **`.claude/commands/`** — Slash commands you invoke directly (`jira-ticket`).
- **`.claude/settings.local.json`** — Your local permission overrides for Claude Code. You can edit this freely; it doesn't ship anywhere.

Everything in `.claude/` other than `settings.local.json` is the team's source of truth. Edits to those files don't persist past your local session — they have to go through the JIRA loop to stick.

---

## Glossary

| Term | What it means |
|---|---|
| **Spec** | A structured 7-section plan that tells the agents what to build. |
| **Agent** | An AI with one specific job — write code, run tests, review, etc. |
| **Orchestrator** | The agent that runs all the other agents in order. The pipeline's entry point. |
| **Pipeline** | The full sequence: pm → architect → executor → tester → reviewer → self-update. |
| **Skill** | A repeatable, on-demand process Claude can invoke (spec-writer, readme-skill). |
| **Self-update** | The agent that audits the pipeline and proposes improvements at the end of each run. |
| **Self-update artifact** | The `docs/self-update-<date>-<description>.md` file containing those improvements. |
| **JIRA ticket** | How learnings flow back to the team to update the source repo. |
| **Seed repo** | The team's source-of-truth repo that this one was generated from. |
| **D3** | The kind of orchestration this is: you write specs, AI manages execution, human reviews outcomes. |

---

## Proof it works

In one real run, the spec-writer produced a 7-section spec for a React + Node app. The orchestrator then built ~60 files of working code from it — and answered **zero** clarifying questions during the build itself, because every decision had already been made during the interview.

That's the whole point: invest in the spec, then let the pipeline run.
