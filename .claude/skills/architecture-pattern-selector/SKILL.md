---
name: architecture-pattern-selector
description: Picks an architecture pattern (the shape of the application — interactive dashboard, content website, behind-the-scenes service, etc.) using business-friendly descriptions. Use after a platform has been chosen, when the user knows roughly what they want to build but not which application shape fits. Trigger phrases like "what kind of app should I build", "is this a website or a service", "do I need a frontend or just an API", "pick an architecture pattern", "register a new app". Reads pattern descriptions from `patterns/` in this skill folder.
---

# Architecture Pattern Selector Skill

You help a non-technical user pick an **architecture pattern** — the *shape* of the application they want to build. Each pattern is a pre-configured template that comes with a chosen language, framework, repo scaffold, CI/CD pipeline, and hosting setup. The user describes what they want in plain language; you match against the patterns in `patterns/` and recommend one (or a pair, if the workload spans two).

Patterns sit a layer below platforms: the **platform** is *where* it runs (e.g. Web Container App). The **pattern** is *what shape* the app takes on that platform (interactive dashboard, content website, behind-the-scenes service, etc.).

This skill makes a **recommendation**, not a binding decision. The caller presents the recommendation to the user for confirmation before scaffolding any code.

---

## Input

The caller (or user directly) provides:

- **What they want to build** — a sentence or two in plain language.
- **Who will use it** — humans clicking through a browser? Another piece of software calling it? An AI agent?
- **What it does** — show information, let people do work, connect two systems, run automation, expose data.

If only one of these is clear, ask follow-up questions before recommending. Don't guess.

---

## Procedure

### Step 1: Read the pattern catalog

Read every file in `patterns/` in this skill folder, **except** `_TEMPLATE.md`. Each file is one architecture pattern. Hold the full set in working memory — you'll rank them against each other.

If `patterns/` is empty or only contains the template, stop and report: "No architecture patterns are defined in the catalog. Cannot recommend without patterns to choose from." Do not invent a pattern.

### Step 2: Extract decision signals

From the user's input, identify:

- **Consumer** — human in a browser, another piece of software (API caller), an AI agent
- **User interface needed?** — yes (interactive) / yes (read-only content) / no (headless)
- **Kind of work** — show information, gather information, run a calculation or automation, glue two systems together, expose data
- **Data shape** — records (create/read/update/delete), files, ML predictions, real-time streams, mostly static content
- **Who triggers it** — a person clicking, another system on a schedule or event, an agent calling a tool

Mark any signal that's genuinely unknown as `unknown` rather than guessing — it becomes a clarifying question in the output.

### Step 3: Match each pattern

For each pattern file, check the `## When to choose this` and `## When NOT to choose this` sections against the signals. Score:

- **Strong match** — multiple "When to choose this" signals match and no "When NOT" anti-signals trip
- **Weak match** — one signal matches and no anti-signals trip
- **No match** — no signals match, OR any anti-signal trips

### Step 4: Consider pattern pairings

Some workloads need **two patterns paired** — e.g. an Interactive Dashboard App for the UI plus an Integration Service for the backend it talks to. Each pattern file lists common combinations under `## Pairs well with`. If the user's signals span two patterns (e.g. UI work + backend logic, or content site + form-handler), recommend both and explain how they connect.

### Step 5: Return the recommendation

Use this structure (plain language — the user is not an engineer):

```
RECOMMENDED PATTERN(S): <business-friendly name(s)>

In one sentence: <what this pattern is in plain language>

Why this fits what you described:
- <bullet from "When to choose this" that matches a signal>
- <another matching bullet>

What you'll get out of the box:
- <bundled item, e.g. "ready-to-edit dashboard layout with login screen">
- <another bundled item>

Estimated cost: <range from the pattern file>

If you'd rather: <alternative pattern + the tradeoff in one sentence>

To confirm before we scaffold:
- <any signal that was guessed rather than stated>
```

---

## When two patterns are recommended together

Output both blocks above, then add:

```
HOW THEY WORK TOGETHER:
<one paragraph describing the connection — e.g. "The Interactive Dashboard App
is what your team sees and clicks; the Integration Service runs invisibly behind
it, handling the calls to <external system> so the dashboard stays simple.">
```

---

## What this skill does not decide

- **Platform / hosting** — the Tricentis portal layers in hosting, SSO, secrets, and CI/CD after the pipeline produces the repo. This skill picks the application *shape*; the portal handles where it runs.
- **Criticality tier** — Green / Yellow / Red classification is upstream; this skill picks a *shape*, not a governance tier.
- **Business logic** — what the app *does* is the user's call. This skill only picks the template it's built on.

---

## Adding a new pattern to the catalog

Copy `patterns/_TEMPLATE.md` to `patterns/<pattern-id>.md` and fill in every section. Keep the section names and order identical — this skill matches them by heading. A pattern with missing or stubbed sections will degrade recommendations silently.
