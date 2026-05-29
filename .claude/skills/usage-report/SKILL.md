---
name: usage-report
description: Generates a session-end usage report showing time, tokens, cost, and per-phase breakdown for the work just completed, plus concrete recommendations for reducing cost on the next run. Invoke after a `/business-intake` or `/orchestrator` flow completes, or at any natural endpoint where you want hard numbers. Reads from Claude Code's `/usage` output (the user pastes it) and writes a structured markdown report to `docs/usage-<YYYY-MM-DD>-<short-name>.md`. Trigger on phrases like "what did this session cost", "how much did this run cost", "show me usage", "session report", "usage report", "what did we spend".
---

# Usage Report Skill

You generate a session-end usage report when invoked. The report captures how much time, money, and tokens the session consumed, breaks it down by phase where possible, and gives the user concrete recommendations for reducing cost on the next similar run.

## What you produce

A single markdown file at `docs/usage-<YYYY-MM-DD>-<short-name>.md` with:

1. **Header** — session date, total wall-clock duration, total cost
2. **Summary table** — total tokens (input / output), cost, cache hit rate, model breakdown
3. **Per-phase breakdown** — business-intake / spec-writer brief-driven / orchestrator pipeline / etc., to the extent the data supports it
4. **Cache performance** — hit rate and estimated savings
5. **Recommendations** — concrete suggestions tied to the observed data, using the team's pipeline heuristics

## Procedure

### Step 0: Detect invocation context

Check if the skill was invoked with args. Two patterns to handle:

- **`args: "post-orchestrator-run; spec=<spec-name>"`** — auto-invoked by the `/orchestrator` command's Step 6 after a pipeline run. Use `<spec-name>` as the short-name in the output filename (e.g., `spec=refund-router` → `docs/usage-<YYYY-MM-DD>-refund-router.md`). Skip the "what was this session about" question; the spec name carries it. Frame the opening message as: *"Generating the usage report for the `<spec-name>` pipeline run."*
- **No args, or args you don't recognize** — manual invocation. Ask the user what the session topic was at Step 3 (the per-phase categorization) as normal.

Either way, proceed to Step 1.

### Step 1: Capture the usage data

Ask the user to run `/usage` and paste the output:

> "I'll generate a usage report for this session. Run `/usage` in this conversation and paste the output. Once I have it, I'll write the report and surface the headline cost + recommendations inline. One minute."

`/usage` is Claude Code's built-in slash command. Its output includes total tokens (input / output), cost, cache statistics, and a per-model breakdown for the current session. Wait for the paste before proceeding.

If the user can't or won't paste, fall back to: ask for just total cost + duration. A degraded report is better than no report.

### Step 2: Parse what's in the paste

From `/usage` output, extract:

- **Total input tokens** (across all calls)
- **Total output tokens**
- **Cache read tokens** (input tokens that hit the prompt cache)
- **Cache write tokens** (input tokens that wrote to cache)
- **Per-model breakdown** — Opus tokens / Sonnet tokens / Haiku tokens (input + output for each)
- **Estimated total cost** — `/usage` typically reports this directly; use that value rather than recalculating
- **Session duration** — `/usage` may show this; if not, ask the user for an approximate start time

### Step 3: Categorize by phase (best effort)

If the session walked through the canonical business-intake flow, ask the user to confirm the rough phase boundaries:

> "To break down the cost by phase, can you tell me roughly which parts of the session were which?
>
> - business-intake interview + proposal review + brief generation (Sonnet)
> - spec-writer brief-driven subagent reasoning (Opus)
> - orchestrator pipeline (Sonnet, multiple agents)
> - Other work outside the pipeline (writing code by hand, exploring, etc.)
>
> Rough percentages or 'roughly half and half' is fine — I just want order-of-magnitude attribution."

If the user says they don't know, skip the per-phase table and note: *"Per-phase breakdown not available — only session totals captured."*

### Step 4: Generate recommendations

Apply these heuristics, tailored to this team's pipeline:

| Observed signal | Recommendation |
|---|---|
| **Opus tokens > 30% of total** | The `spec-writer-brief-driven` subagent is meant to be the only Opus consumer. If Opus tokens are high, check whether the session model has drifted off Sonnet (settings.json's `model: claude-sonnet-4-6` may have been overridden). |
| **Cache hit rate < 50%** | Static content (CLAUDE.md, skill instructions) isn't hitting the cache consistently. Check that prompts haven't been changing turn-to-turn in ways that defeat caching. |
| **Cache hit rate > 80%** | Caching is working well. No action. |
| **business-intake phase > 25% of cost** | The interview ran longer than the model split anticipated. Consider whether some questions in the skill are eligible for auto-decision (see `docs/business-intake-todo.md` Concern #1 if present). |
| **spec-writer-brief-driven > 60% of cost** | The brief was thin or ambiguous, forcing the Opus subagent to reason from sparse signal. Consider enriching the brief at the source (more specific user answers, fewer TBDs). |
| **Orchestrator retries (tester retried > 3, reviewer retried > 2)** | Spec was vague in Section 4 (Failure Modes) or Section 6 (Decision Points). Tighten those before the next run on a similar workload. |
| **Total cost > $5 for a single-feature build** | Look at the per-phase breakdown for an outlier step. Compare against the pipeline cost-optimization target (~$3–4/run per the memory note). |
| **Total cost < $1** | The pipeline is well-optimized for this workload. Note this as a baseline for similar future runs. |

Always include at least 2 recommendations. If the run was clean (no signals triggered), the recommendations are: (1) baseline this cost for future comparison, (2) suggest re-running the same workload to validate the cache will warm up and reduce cost further.

### Step 5: Write the file

Use this template. Save to `docs/usage-<YYYY-MM-DD>-<short-name>.md` where `<short-name>` is a kebab-case slug derived from what the session built (e.g., `daily-ticket-summary` if the session ran `/business-intake` for the ticket summary workload, or `adhoc` if no clear single workload).

```markdown
# Session Usage Report — <YYYY-MM-DD>
*Session topic: <short summary, e.g. "daily-ticket-summary build" or "ad-hoc work">*
*Wall-clock duration: <X hours Y minutes>*
*Total cost: $<X.XX>*

## Summary

| Metric | Value |
|---|---|
| Total tokens | <input N> in / <output N> out |
| Total cost | $<X.XX> |
| Cache hit rate | <X>% |
| Cache savings (estimated) | $<X.XX> |
| Models used | Opus <X>% / Sonnet <Y>% / Haiku <Z>% |

## Per-phase breakdown

*(omit this section entirely if the user couldn't attribute by phase)*

| Phase | Approx. share | Approx. cost | Model |
|---|---|---|---|
| business-intake interview + proposal + brief | <X>% | $<X.XX> | Sonnet |
| spec-writer-brief-driven (silent reasoning) | <X>% | $<X.XX> | **Opus** |
| orchestrator pipeline (pm/architect/executor/tester/reviewer/self-update) | <X>% | $<X.XX> | Sonnet |
| Other (ad-hoc work outside the pipeline) | <X>% | $<X.XX> | mixed |

## Cache performance

- **Hit rate:** <X>%
- **Estimated savings vs uncached:** $<X.XX>
- **Notes:** <e.g. "Cache warmed by turn 5; subsequent reads hit consistently.">

## Recommendations

<bulleted list — at least 2 entries, each tied to a specific signal observed in the data>

- **<short recommendation title>** — <one-sentence explanation referencing the specific number that triggered it, plus the concrete action>.
- ...

## Comparison to prior runs

*(only include this section if `docs/usage-*.md` files already exist; otherwise omit)*

| Run | Date | Total cost | Tokens | Duration |
|---|---|---|---|---|
| This run | <date> | $<X.XX> | <N> | <duration> |
| <prior run date> | <date> | $<X.XX> | <N> | <duration> |
```

### Step 6: Surface the headline inline

After writing the file, tell the user:

> "Usage report written to `docs/usage-<YYYY-MM-DD>-<short-name>.md`.
>
> **Headline:** Total cost $<X.XX>, <X> tokens, <X>% cache hit rate.
>
> **Top recommendation:** <the most impactful recommendation from Step 4, in one sentence>.
>
> Open the file for the full breakdown."

Render the headline + top recommendation inline so the user sees them without opening the file. The rest of the report (per-phase, cache details, all recommendations) is in the file for later review or stakeholder sharing.

## What this skill does NOT do

- Does NOT trigger automatically — manually invoked at a natural endpoint
- Does NOT modify the spec, brief, decisions log, or any other pipeline artifact — strictly read-only on the pipeline state
- Does NOT propose changes to CLAUDE.md, skill files, or agent files — recommendations are advisory; the user decides what to act on
- Does NOT upload usage data anywhere — the report stays local in `docs/`
- Does NOT include personally-identifiable information from the session content — just token counts and cost

## When to invoke

- After `/orchestrator` reports pipeline complete on a full build
- After `/business-intake` produces the four artifacts but before invoking orchestrator (to see what the brief generation cost)
- At the end of a working session across multiple flows
- Before a sprint retrospective or postmortem when you want hard numbers to ground the conversation
