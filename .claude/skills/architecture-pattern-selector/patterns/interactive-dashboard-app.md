---
pattern_id: interactive-dashboard-app
display_name: Interactive Dashboard App
technical_name: React SPA
status: approved
last_reviewed: 2026-05-28
monthly_cost_estimate: $5–15/mo
---

# Pattern: Interactive Dashboard App

## One-line description

A rich, clickable web application your team logs into through a browser — buttons, forms, charts, and live data on the same screen.

## What it looks like to the user

The user opens a URL, sees a logged-in dashboard or admin screen, and clicks around — filtering data, filling forms, drilling into details, viewing charts. The page updates instantly without reloading. Feels like a modern web app (Gmail, Linear, Notion) rather than a traditional website where every click loads a new page.

## When to choose this

- Internal team needs a screen they log into and use day-to-day
- The app shows live data the user filters, sorts, drills into, or edits
- People interact heavily — forms, dropdowns, buttons, charts, tables
- You want it to feel modern and responsive (no full page reloads on every click)
- A small group of named users (not the public internet) will use it
- You need a place to put an admin panel for an existing system

## When NOT to choose this

- You just need to publish a few pages of information that rarely change → use **Content Website**
- There's no user interface at all — another system calls it → use **Integration Service** or **Data & Automation Service**
- Public-facing marketing or landing pages where SEO matters more than interactivity → use **Content Website**
- The work is mostly running calculations, ML, or data crunching with no UI → use **Data & Automation Service**

## Real-world examples

- **Internal admin panel** for managing users, permissions, and feature flags — the team logs in, searches by user, flips toggles, saves changes
- **Operations dashboard** showing live status of jobs, queues, and alerts — filterable by team, drill-down to details
- **Prototype of a new product idea** put in front of a few testers to validate the interaction model before building the full backend
- **Internal CRM-style tool** for tracking customer accounts, notes, and follow-ups

## What's bundled out of the box

- Pre-built React app scaffold with a working layout, routing, and example screens
- Hosting that auto-deploys when you push code
- TLS / HTTPS handled by the platform
- Brand-matched colors and components ready to use (no design-from-scratch)
- Test setup so the team can run automated checks on changes

## Pairs well with

- **[Integration Service](./integration-service.md)** — pair when your dashboard needs to read or write data behind the scenes. The dashboard is what users see; the Integration Service is the backend it talks to (handles auth, database, calls to other systems).
- **[Data & Automation Service](./data-and-automation-service.md)** — pair when the dashboard displays results from ML models, data pipelines, or automation that runs in Python.

## Cost estimate

- **Typical monthly cost:** $5–15/mo for a low-traffic internal app
- **What drives cost up:** high traffic, heavy file uploads, very large user counts. The app itself is cheap; cost climbs with usage of paired services (database, file storage, ML inference).

## Technical details

- **Language / runtime:** TypeScript on Node.js 22 LTS (build-time only — runs as static files in the browser)
- **Framework:** React 18 + Vite
- **Build / test:** Vite for build; Vitest for tests
- **Deployment shape:** Static assets served by nginx in a container
- **Repo template:** Vite `react-ts` template; project CLAUDE.md "UI Stack" section is the source of truth for scaffold conventions
- **Notes for the architect:** Strict TypeScript on by default. `vite.config.ts` must bind `server.host: '0.0.0.0'` for Docker dev container. Keep `vite.config.ts` and `vitest.config.ts` as separate files. Brand tokens come from `assets/brand.css` — no hardcoded hex codes.

## Owner contact for questions

- **Slack:** <!-- TODO: team channel -->
- **Escalation:** <!-- TODO: person or role -->
