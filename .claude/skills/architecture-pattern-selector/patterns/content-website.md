---
pattern_id: content-website
display_name: Content Website
technical_name: Static Site
status: approved
last_reviewed: 2026-05-28
monthly_cost_estimate: $5–15/mo
---

# Pattern: Content Website

## One-line description

A simple, fast website that shows information — pages, text, images, links. No logins, no databases, nothing that changes based on who's looking. The cheapest and fastest pattern when you just need to publish content.

## What it looks like to the user

The user visits a URL and reads pages — like a documentation site, a landing page, a marketing site, or a simple internal info hub. They can click links to navigate between pages, but there are no logged-in accounts, no personalization, and nothing that updates live. Every visitor sees the same content. Pages load instantly because they're pre-built.

## When to choose this

- You're publishing information — docs, marketing copy, landing pages, a team handbook
- Content rarely changes (a few times a week at most), and changes are made by editing files
- The same content is shown to every visitor — no login, no personalization
- You want it to be fast, cheap, and search-engine-friendly
- You're prototyping a design or layout to show stakeholders before committing to a real app
- You need a simple tool that runs entirely in the browser (calculator, converter, lookup) with no server logic

## When NOT to choose this

- Users log in and see their own data → use **Interactive Dashboard App**
- Pages need to update based on who's viewing them or what's happening right now → use **Interactive Dashboard App**
- You need forms that save data anywhere → use **Interactive Dashboard App** or pair this with an **Integration Service**
- The content changes constantly from a database or external feed → use **Interactive Dashboard App** or **Integration Service**
- You need server-side logic (auth, business rules, API calls with secrets) → use **Integration Service** or **Data & Automation Service**

## Real-world examples

- **Documentation site** for an internal tool — explains how to use it, with code examples and screenshots
- **Marketing landing page** for a new product, optimized for search and shareability
- **Team handbook or wiki** with onboarding info, policies, and reference material
- **Design prototype** put in front of users to validate the look and flow before building a real app
- **Simple browser-only tool** like a unit converter or color picker that runs entirely client-side

## What's bundled out of the box

- Pre-built site scaffold with a working layout, navigation, and example pages
- Hosting with auto-deploy on push
- TLS / HTTPS handled by the platform
- No build step required — edit HTML / CSS / JS directly
- CDN-style fast page loads served by nginx

## Pairs well with

- **[Integration Service](./integration-service.md)** — pair when a mostly-static site needs one or two dynamic touches (contact form, newsletter signup, comments). The site stays simple; the service handles the few interactive bits.

## Cost estimate

- **Typical monthly cost:** $5–15/mo — the cheapest pattern in the catalog
- **What drives cost up:** very high traffic (millions of visits / month), large file or video hosting. For typical internal or modest-traffic public sites, this stays at the low end.

## Technical details

- **Language / runtime:** Plain HTML / CSS / JavaScript — no build step, no framework required
- **Framework:** None (or optional lightweight static-site generator if the team wants templating)
- **Build / test:** No build by default; optional build step if a generator is added later
- **Deployment shape:** Static files served by nginx in a container
- **Repo template:** <!-- TODO: link to scaffold repo -->
- **Notes for the architect:** No secrets in the browser — every config value the site uses is visible to anyone who views the page source. If a feature needs auth or server-side secrets, that feature belongs in a paired Integration Service, not here.

## Owner contact for questions

- **Slack:** <!-- TODO: team channel -->
- **Escalation:** <!-- TODO: person or role -->
