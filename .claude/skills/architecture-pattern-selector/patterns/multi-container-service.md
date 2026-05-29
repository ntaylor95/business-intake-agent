---
pattern_id: multi-container-service
display_name: Multi-Container Service
technical_name: Containerized API + Worker + DB (AKS)
status: approved
last_reviewed: 2026-05-29
monthly_cost_estimate: $50–150/mo
---

# Pattern: Multi-Container Service

## One-line description

A backend service split into a web-facing API, one or more background workers, and a shared database — all running together as separate containers on Kubernetes so each piece can scale independently.

## What it looks like to the user

The end user doesn't see this directly. They use an app (a dashboard, a mobile app, an internal tool) that talks to the API for quick responses, while heavier work happens in the background — sending emails, generating reports, processing uploads — without making the user wait. The shared database keeps everything in sync.

## When to choose this

- The workload has **both** a fast request/response surface AND slow background work (e.g., a CRM that takes a request quickly but generates a report in the background)
- You need to persist state across runs — a database, not just ephemeral compute
- Background work is too heavy to run inline with the API request without blocking the user
- The API needs to keep responding while workers process queued jobs
- Different parts of the workload have different scaling needs — the API might handle 1000 req/min but the worker only needs 10 jobs/min
- The team is comfortable with Kubernetes operations OR the platform layer handles ops for them

## When NOT to choose this

- The workload is read-only / no background processing → use **Interactive Dashboard App** or **Content Website**
- It's a single-function service with no API and no persistent state → use **Data & Automation Service** or **Integration Service**
- There's no UI/API consumer at all — just a scheduled job that runs and exits → needs a scheduled-job pattern (not yet in this catalog)
- The team has no Kubernetes experience and the platform doesn't abstract it — operational overhead will eat the wins
- Expected request volume is very low (< 100 req/day) — multi-container infrastructure costs more than the workload justifies

## Real-world examples

- **Internal CRM** with a web API for the sales team's frontend, a background worker that sends bulk email campaigns, and a database storing customer records
- **Order processing system** with an API that accepts new orders (returns fast), a worker that handles payment processing + fulfillment in the background, and a database of order history
- **Reporting tool** where users request reports via API (returns "your report is queued"), a worker generates the PDF over the next few minutes, and the database tracks report metadata + completion status
- **Customer onboarding portal** with an API for the signup form, a worker that provisions accounts + sends welcome emails + notifies internal teams, and a database of customers and onboarding state

## What's bundled out of the box

- Pre-built FastAPI scaffold for the API container with auth + request validation
- Pre-built worker container with example job consumer + retry/backoff
- Postgres database container with migrations setup (Alembic for Python, or equivalent)
- Kubernetes manifests for all three containers with multi-pod replication
- Auto-scaling for the API container based on CPU/memory
- TLS / HTTPS handled by the platform's ingress
- Centralized logging across all containers
- Health checks for each container so the platform restarts unhealthy pods
- Inter-container service discovery (the API and worker can find the DB by service name)
- Test setup with `pytest` covering API endpoints + worker job handlers

## Pairs well with

- **[Interactive Dashboard App](./interactive-dashboard-app.md)** — the dashboard is the frontend users click; the API is its backend; the worker handles anything too slow for the UI.
- **[Integration Service](./integration-service.md)** — pair when external systems (webhooks, vendor APIs) feed into the workload; the Integration Service receives external traffic and routes to the Multi-Container Service for processing.
- **[Event-Driven Service](./event-driven-service.md)** — pair when the worker portion of this pattern would benefit from queue-based auto-scaling instead of a fixed worker pool; the Event-Driven Service replaces the worker container.
- **[Scheduled Job Service](./scheduled-job-service.md)** — pair when one of the workers in this multi-container shape is a clock-triggered scheduled job (nightly sync, weekly report) rather than a queue consumer; the Scheduled Job Service becomes one container in the deployment.

## Cost estimate

- **Typical monthly cost:** $50–150/mo for low-to-moderate traffic with 2–3 API pods, 1–2 worker pods, and a small managed database
- **What drives cost up:** higher pod replica counts, database size + IOPS, heavy outbound traffic, long-running worker jobs that keep pods warm

## Technical details

- **Language / runtime:** Python 3.11+ for both API and worker (FastAPI + a worker framework like Celery, RQ, or arq)
- **Database:** Postgres 16+ (managed by the platform; not a sidecar pod)
- **Framework:** FastAPI (API) + Celery or arq (worker)
- **Build / test:** `uv` for dependency management, `pytest` for tests, `mypy` for typing (strict mode auto-enabled if the spec touches money / auth / PII / regulated data per CLAUDE.md)
- **Deployment shape:** Three independent deployments on AKS — `api`, `worker`, `db` (the db is typically a managed service rather than a pod); ingress + service mesh handled by the platform
- **Repo template:** *to be added by the team — see Owner contact below*
- **Notes for the architect:** the API and worker share a codebase but separate entrypoints. The shared module (`core/`) holds business logic; both surfaces import from it. Avoid putting business logic in the API or worker entrypoints directly — that breaks the pairing with **Event-Driven Service** later.

## Owner contact for questions

- **Slack:** *to be filled in by the team*
- **Escalation:** *to be filled in by the team*
