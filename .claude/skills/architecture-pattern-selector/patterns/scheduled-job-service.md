---
pattern_id: scheduled-job-service
display_name: Scheduled Job Service
technical_name: Cron-Triggered Container (AKS CronJob)
status: approved
last_reviewed: 2026-05-29
monthly_cost_estimate: $5–15/mo
---

# Pattern: Scheduled Job Service

## One-line description

A backend job that runs on a fixed schedule (every morning, every hour, every Monday, etc.) — pulls data from somewhere, processes it, produces an output, and exits. The clock is the trigger; no upstream queue, no human waiting, no API surface.

## What it looks like to the user

The end user doesn't see this run directly. At a scheduled time, the job wakes up, fetches what it needs (from a system, a database, an API), does its work — generating a report, sending an email, syncing data, cleaning up records — and the output lands wherever it's supposed to go (an inbox, a file share, a downstream system). The user finds the output ready and waiting.

## When to choose this

- The work runs on a **fixed schedule** — every X minutes / hours / days / weeks
- **No human is waiting in real-time** for the result
- The job is **bounded** — pull, process, output, done (not a continuously running service)
- Typical run duration is seconds to minutes, not hours
- **No upstream queue or event source** — the clock IS the trigger
- Output is **pushed** to a destination (email, file, downstream API call), not exposed via an endpoint
- Common shape: "every morning, pull from System A, transform, send to System B or to people"

## When NOT to choose this

- Triggered by an upstream event (webhook, message queue) → use **Event-Driven Service**
- A human is waiting for a synchronous response → use **Integration Service** or **Interactive Dashboard App**
- The job runs for hours or doesn't have a clear end → needs a long-running worker pattern (not yet in this catalog)
- Work needs to scale with input volume per-message → use **Event-Driven Service**
- There's a UI where users trigger it manually → use **Interactive Dashboard App** + **Multi-Container Service**
- The schedule is "as often as possible" (effectively continuous) — that's a long-running worker, not a scheduled job

## Real-world examples

- **Daily team summary email** — pull yesterday's support tickets from Zendesk every morning at 6am, summarize, email to the team (the canonical example; see `docs/daily-ticket-summary.md` for a worked spec)
- **Nightly data sync** — every night, pull updates from Salesforce, transform, push to the data warehouse
- **Weekly executive report** — every Monday at 8am, run analytics queries, generate a PDF, email to leadership
- **Hourly cache refresh** — every hour, pull the latest catalog from the vendor API, write to a local store the rest of the app reads from
- **Monthly billing run** — first of every month, compute usage from the prior month, generate invoices, queue them for sending
- **Scheduled cleanup** — every Sunday, purge records older than 90 days from the archive table

## What's bundled out of the box

- Pre-built scaffold with cron schedule config in `cron-schedule.yaml` + an entrypoint function
- Kubernetes CronJob manifest for AKS-native scheduling (standard cron syntax)
- **Dry-run mode flag** — entrypoint accepts `--dry-run` so the executable definition of done can run without sending real emails / writing real records
- Logging captured by the platform; metrics for run duration and success/failure rate
- Failure alerts when a scheduled run fails or is skipped (e.g., the cluster was down at scheduled time)
- Test setup with `pytest` + fixture data so the job's logic is unit-testable without live external systems
- Type-checking with `mypy` configured to project defaults

## Pairs well with

- **[Data & Automation Service](./data-and-automation-service.md)** — when the same business logic ALSO needs to be callable on-demand via API. Put the logic in a shared `core/` module; both this scheduled job and the Data & Automation Service call into it.
- **[Multi-Container Service](./multi-container-service.md)** — when this scheduled job is one piece of a larger system that also has an API + shared database. The CronJob becomes another container in the multi-container deployment.

## Cost estimate

- **Typical monthly cost:** $5–15/mo for jobs that run hourly or less frequently — Kubernetes CronJob only consumes resources during the run itself
- **What drives cost up:** very frequent runs (every minute), long run duration (>10 minutes per invocation), heavy CPU or memory per run, large outbound traffic or database queries

## Technical details

- **Language / runtime:** Python 3.11+ by default (matches the rest of the Python catalog and the typical "fetch / transform / send" workload); Node.js 22 LTS as an alternative when the work is pure glue with no data processing
- **Scheduler:** Kubernetes CronJob on AKS — uses standard cron syntax (`"0 6 * * *"` for 6am daily); the platform handles scheduling, failure-restart policy, and concurrency control
- **Framework:** No web framework needed — plain Python script with an `if __name__ == "__main__"` entry point; for Node, a plain script entry as well
- **Build / test:** `uv` for dependency management; `pytest` for unit tests against the job's logic with fixture data; `mypy` strict mode auto-enabled if the spec touches money / auth / PII / regulated data per CLAUDE.md
- **Deployment shape:** Single container, single replica per run, **run-to-completion** semantics. Kubernetes spawns a new pod for each scheduled invocation; the pod exits when the job completes.
- **Repo template:** *to be added by the team — see Owner contact below*
- **Notes for the architect:**
  - **Design for idempotency.** A scheduled job can run twice for the same window (manual retry, scheduler restart, missed-run replay). The second run should either be a no-op OR produce the same result. Single-run semantics are NOT guaranteed by Kubernetes CronJob.
  - **Cron timezone.** Kubernetes CronJob runs in UTC by default; align the schedule with the destination's expected timezone (e.g., 6am US Eastern = 11:00 UTC during EDT).
  - **`concurrencyPolicy: Forbid`** is the right default for most scheduled jobs — prevents overlapping runs if the previous run hasn't finished.
  - **Failure mode in spec.** The "missing or malformed input" failure mode (Section 4) should explicitly cover: external system unreachable at scheduled time. Default fallback: send a "data unavailable" notification rather than skipping silently.

## Owner contact for questions

- **Slack:** *to be filled in by the team*
- **Escalation:** *to be filled in by the team*
