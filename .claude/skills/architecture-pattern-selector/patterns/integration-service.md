---
pattern_id: integration-service
display_name: Integration Service
technical_name: Node.js API
status: approved
last_reviewed: 2026-05-28
monthly_cost_estimate: $5–15/mo
---

# Pattern: Integration Service

## One-line description

A behind-the-scenes service with no user interface — it connects systems together, receives data, and sends data, so other apps (or the public) can talk to your business.

## What it looks like to the user

The end user never sees this directly. Another app — your team's dashboard, a vendor's system, a webhook from Slack/Salesforce/Stripe — sends it a request, and it responds with data, saves something, or forwards the request somewhere else. It's the plumbing between systems.

## When to choose this

- Another system (a website, a vendor, a SaaS tool) needs to send you data
- You need to expose data to a partner app, mobile app, or third-party integration
- You're building the backend that a dashboard or website talks to
- You need to receive webhooks from services like Stripe, Slack, GitHub, Salesforce
- The work is "take a request, do something with it, return a response" — fast, transactional
- You need a thin layer that combines calls to multiple internal systems into one cleaner API for a frontend

## When NOT to choose this

- A human will use it directly through a browser → use **Interactive Dashboard App** or **Content Website**
- The work is heavy data processing, ML, or analysis — that's better in Python → use **Data & Automation Service**
- It's just publishing static content with no logic → use **Content Website**
- The job is long-running (more than ~4 minutes) or runs on a schedule rather than per-request — needs a worker or scheduled-job platform, not this pattern

## Real-world examples

- **Webhook handler** that receives events from Stripe (payment succeeded, subscription cancelled) and writes them into the team's internal database
- **Backend-for-frontend** sitting between an Interactive Dashboard App and three internal microservices — the dashboard talks to one clean API instead of three messy ones
- **Partner API** that lets a vendor's system pull customer data programmatically (with auth + rate limits)
- **Integration glue** that pulls data from Salesforce nightly and pushes it into the team's data warehouse

## What's bundled out of the box

- Pre-built API scaffold with example endpoints, request validation, and error handling
- Hosting with auto-deploy on push
- TLS / HTTPS handled by the platform
- Logging and observability wired in
- Health check endpoint for the platform's load balancer
- Test setup for endpoint-level integration tests

## Pairs well with

- **[Interactive Dashboard App](./interactive-dashboard-app.md)** — the dashboard is what users click; this service is the backend it talks to. Together they form a full web app.
- **[Content Website](./content-website.md)** — pair when a mostly-static website needs one or two dynamic features (e.g., a contact form, a newsletter signup).
- **[Event-Driven Service](./event-driven-service.md)** — pair when this service receives webhooks or external calls and enqueues work for asynchronous processing instead of handling it inline. Common shape: webhook in → enqueue → consumer processes.
- **[Multi-Container Service](./multi-container-service.md)** — when this service IS the API piece of a larger system with workers and a shared database, the Multi-Container Service is the parent shape that wraps all three.

## Cost estimate

- **Typical monthly cost:** $5–15/mo for low-to-moderate request volume
- **What drives cost up:** high request volume, paired database costs, third-party API calls billed per use

## Technical details

- **Language / runtime:** TypeScript on Node.js 22 LTS
- **Framework:** Express (with TypeScript)
- **Build / test:** `tsc` for build; Jest or Vitest for tests
- **Deployment shape:** Long-running Node process in a container behind the platform's load balancer
- **Repo template:** <!-- TODO: link to scaffold repo -->
- **Notes for the architect:** Use environment variables for every configurable value (per CLAUDE.md `.env` contract). For webhook endpoints, validate signatures before processing the body. Long-running jobs (>230s per request) won't fit on the Web Container App platform — escalate to a worker pattern.

## Owner contact for questions

- **Slack:** <!-- TODO: team channel -->
- **Escalation:** <!-- TODO: person or role -->
