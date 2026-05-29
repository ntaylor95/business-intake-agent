---
pattern_id: data-and-automation-service
display_name: Data & Automation Service
technical_name: Python API
status: approved
last_reviewed: 2026-05-28
monthly_cost_estimate: $5–15/mo
---

# Pattern: Data & Automation Service

## One-line description

A behind-the-scenes service for crunching data, running calculations or ML models, and automating tasks — the kind of work Python is best at, exposed as an API other systems can call.

## What it looks like to the user

The end user usually doesn't see it directly. Another app — a dashboard, a scheduled job, an AI agent — sends it a request like "predict this," "score that," "transform this dataset," "run this automation," and it returns a result. Internally, it's likely using libraries from the Python data and ML ecosystem (pandas, scikit-learn, etc.).

## When to choose this

- The work involves data manipulation, analytics, statistics, or transformations
- You need to expose a machine learning model so other systems can get predictions from it
- The job is automation — "every time X happens, run this calculation and save the result"
- The team has existing Python code (notebooks, scripts, models) they want to turn into a real service
- The work benefits from Python's data / ML / scientific computing libraries
- You're building a tool an AI agent will call to get structured results (and **not** specifically tool-use with the Anthropic MCP SDK — that's a different pattern, when added)

## When NOT to choose this

- A human will use it directly through a browser → use **Interactive Dashboard App** or **Content Website**
- The work is just plumbing / glue between systems with no data crunching → use **Integration Service** (Node.js is lighter for this)
- It's mostly static content → use **Content Website**
- The job needs to run for hours, or on a strict schedule with no caller — needs a scheduled-job or worker pattern, not this one
- The expected request volume is very high (thousands per second) and latency is critical — Python's per-request overhead may not fit; revisit with the architect

## Real-world examples

- **ML prediction endpoint** that takes customer data and returns a churn-risk score, called by a dashboard or batch job
- **Data transformation API** that accepts a CSV, applies cleaning and enrichment rules, and returns the transformed file
- **"Script as a service"** — wrapping a Python automation script (PDF parsing, data scraping, report generation) as an HTTP endpoint so other systems can trigger it
- **Internal analytics API** that runs statistical calculations on team data and returns summary metrics

## What's bundled out of the box

- Pre-built FastAPI scaffold with example endpoints, request/response models, and auto-generated API docs
- Hosting with auto-deploy on push
- TLS / HTTPS handled by the platform
- Logging and observability wired in
- Test setup with `pytest`
- Type-checking with `mypy` configured to project defaults

## Pairs well with

- **[Interactive Dashboard App](./interactive-dashboard-app.md)** — the dashboard shows the results; this service produces them (predictions, analytics, transformations).
- **[Integration Service](./integration-service.md)** — pair when one part of the workload is glue (Node) and another is data crunching (Python). The Integration Service routes incoming requests; this service handles the heavy lifting.
- **[Event-Driven Service](./event-driven-service.md)** — pair when per-message work involves heavy data processing (ML inference, complex transformations). This service handles the per-message logic; the Event-Driven Service handles queueing + auto-scaling.
- **[Multi-Container Service](./multi-container-service.md)** — when this service IS the API portion of a larger CRUD app and a worker handles background data work, the Multi-Container Service is the parent shape.
- **[Scheduled Job Service](./scheduled-job-service.md)** — pair when the same business logic ALSO needs to run on a fixed schedule (nightly sync, hourly refresh). Put the logic in a shared `core/` module; both this service and the Scheduled Job Service call into it.

## Cost estimate

- **Typical monthly cost:** $5–15/mo for low-to-moderate request volume
- **What drives cost up:** large ML models (memory-heavy), high request volume, expensive third-party data sources

## Technical details

- **Language / runtime:** Python 3.12 (3.11+ supported)
- **Framework:** FastAPI + Uvicorn
- **Package manager:** `uv`
- **Build / test:** `pytest` for tests; `mypy` for type checking (strict mode auto-applied for money / auth / PII workloads per CLAUDE.md)
- **Deployment shape:** Long-running Uvicorn process in a container behind the platform's load balancer
- **Repo template:** <!-- TODO: link to scaffold repo -->
- **Notes for the architect:** Bind Uvicorn to `--host 0.0.0.0` for the Docker dev container. Use `pydantic-settings` for env config (raw `os.environ.get` is reviewer-flagged). Watch the `Form(...)` 422-vs-400 footgun called out in CLAUDE.md. Add `B008` to ruff ignore for FastAPI's `Depends()` / `Form()` / etc. defaults.

## Owner contact for questions

- **Slack:** <!-- TODO: team channel -->
- **Escalation:** <!-- TODO: person or role -->
