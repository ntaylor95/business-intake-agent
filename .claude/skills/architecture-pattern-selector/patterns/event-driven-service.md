---
pattern_id: event-driven-service
display_name: Event-Driven Service
technical_name: Queue + Consumer (AKS, auto-scaling)
status: approved
last_reviewed: 2026-05-29
monthly_cost_estimate: $30–100/mo
---

# Pattern: Event-Driven Service

## One-line description

A backend service that listens to a message queue and processes each message as it arrives — perfect when work needs to happen reactively as things occur upstream, with the consumer scaling up automatically when traffic spikes and back down when it's quiet.

## What it looks like to the user

The end user doesn't see this directly. Something happens upstream — a customer places an order, a webhook fires from a vendor, a file finishes uploading, an internal system emits an event — and a message lands on the queue. This service consumes the message, does whatever it needs to do (transform data, send a notification, write a record, call another API), and acknowledges the message. If a burst of messages arrives, more consumer pods spin up automatically; when the queue is empty, they spin down.

## When to choose this

- Work is **triggered by upstream events**, not by a scheduled clock or a synchronous request
- The volume is bursty — quiet most of the time, then heavy spikes you need to absorb without overprovisioning
- Tight coupling to the producer would be bad — the queue gives you decoupling and replay safety
- You need at-least-once or exactly-once delivery guarantees for the work
- Multiple producers can drop work onto the queue and the consumer doesn't need to know about them
- You want failed messages to retry automatically (queue's dead-letter / requeue semantics) without writing retry logic from scratch

## When NOT to choose this

- Work runs on a **schedule** (cron at 6am), not in response to an event — needs a scheduled-job pattern (not yet in this catalog), not this one
- The workload is synchronous request/response — the caller is waiting for a result → use **Integration Service** or **Multi-Container Service**
- There's no upstream system emitting events — you'd have to invent the producer side, which defeats the pattern
- Volume is constantly low (a few messages per day) — queue infrastructure costs more than the workload justifies
- The work is heavy data processing or analytics with no event trigger → use **Data & Automation Service**

## Real-world examples

- **Webhook fan-out** — Stripe sends a payment event → it lands on a queue → multiple consumers process it (update DB, send receipt, notify accounting); slow consumers don't block fast ones
- **Audit log writer** — every change in the system emits an event → consumer batches them and writes to long-term storage; the queue absorbs bursts during business hours
- **Image / file processor** — user uploads a file → upload completion event → consumer resizes, watermarks, or scans for content → finishes asynchronously without blocking the upload UI
- **Order fulfillment** — order placed → fulfillment event → consumer reserves inventory, schedules shipping, emails the customer — and consumer pool scales up on Black Friday without manual intervention
- **AI inference job runner** — model inference requests queue up → GPU-backed consumer pulls one at a time and processes; auto-scales when the backlog grows

## What's bundled out of the box

- Pre-built consumer scaffold with message-handler examples, retry/backoff, and dead-letter queue support
- Message queue connection setup (Azure Service Bus, RabbitMQ, or equivalent — chosen by the platform)
- Auto-scaling consumer pods on AKS, with replica count tied to queue depth (KEDA or equivalent)
- TLS for queue connections handled by the platform
- Idempotency key helper for safe replay
- Centralized logging with message correlation IDs
- Health checks so unhealthy consumer pods get replaced
- Test setup with `pytest` + in-memory queue mock for handler tests

## Pairs well with

- **[Integration Service](./integration-service.md)** — the Integration Service receives webhooks / external calls from upstream systems and enqueues messages; the Event-Driven Service consumes them. This is the most common pairing.
- **[Multi-Container Service](./multi-container-service.md)** — pair when the API portion of a Multi-Container Service should enqueue work instead of running it inline in a fixed worker pool. The Event-Driven Service replaces the worker piece with auto-scaling consumers.
- **[Data & Automation Service](./data-and-automation-service.md)** — pair when consumers need to do heavy data work per message (Python ML inference, complex transformations); the data service handles the per-message logic, the event-driven service handles the queueing + scaling.

## Cost estimate

- **Typical monthly cost:** $30–100/mo for low-to-moderate volume (a few thousand messages/day, 1–3 consumer pods)
- **What drives cost up:** very high message volume, GPU-backed consumers, expensive per-message third-party API calls, large dead-letter retention, messages that take minutes each to process

## Technical details

- **Language / runtime:** Python 3.11+ for the consumer (Node.js is an alternative when the work is purely glue, but Python is the default to match the rest of the catalog)
- **Message queue:** Azure Service Bus by default (managed, integrates with AKS identity); RabbitMQ if a self-hosted queue is required
- **Framework:** Plain Python consumer loop OR `arq` / `Celery` worker with queue backend swapped to Service Bus
- **Auto-scaler:** KEDA (Kubernetes Event-Driven Autoscaling) — scales consumer pods based on queue depth
- **Build / test:** `uv` for dependency management, `pytest` with an in-memory queue mock for handler tests, integration tests with a sandbox queue
- **Deployment shape:** Single consumer deployment on AKS with KEDA-managed replica count (often 0 when idle, scales to N under load); queue is a managed resource
- **Repo template:** *to be added by the team — see Owner contact below*
- **Notes for the architect:** **Idempotency is mandatory**. Messages can be delivered more than once (at-least-once semantics). Every handler must be safe to run twice on the same message. Use an idempotency key (message ID hashed against a "processed" table, or equivalent) and check it before doing irreversible work. Skipping this guarantees future incidents.

## Owner contact for questions

- **Slack:** *to be filled in by the team*
- **Escalation:** *to be filled in by the team*
