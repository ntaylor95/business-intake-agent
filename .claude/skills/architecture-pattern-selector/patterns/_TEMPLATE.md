---
pattern_id: <kebab-case-id>
display_name: <Business-friendly name — e.g. "Interactive Dashboard App">
technical_name: <Engineering shorthand — e.g. "React SPA">
status: <approved | beta | deprecated>
last_reviewed: <YYYY-MM-DD>
monthly_cost_estimate: <e.g. "$5–15/mo">
---

# Pattern: <Display Name>

> **Template for adding an architecture pattern to the catalog.** Copy this file to `<pattern-id>.md` and replace every section. Every field exists because the `architecture-pattern-selector` skill uses it to match user signals against patterns. Leaving sections empty will degrade recommendations silently. Delete this blockquote when filling in.

---

## One-line description

*One sentence in plain language. Describe what this pattern is **to a business user** — not what stack it's built on. The "what's under the hood" goes in `## Technical details` below.*

## What it looks like to the user

*Two or three sentences describing what someone interacting with this app would actually see and do. If there's no UI (it's a service), describe what calls it and how. Helps a non-technical user visualize whether the pattern matches what they're imagining.*

## When to choose this

*Bulleted list of concrete user-facing signals that point to this pattern. Write in plain language, not jargon — "the team needs a screen they log into and click around" is the right grain, not "interactive client-side state management." The skill matches the user's described workload against these bullets one-for-one.*

- <signal 1>
- <signal 2>
- <signal 3>
- <signal 4>

## When NOT to choose this

*Bulleted list of explicit anti-signals. If any match the user's described workload, this pattern is the wrong answer — the skill will exclude it regardless of how many "When to choose" bullets match. Anti-signals prevent confident-sounding bad recommendations.*

- <anti-signal 1>
- <anti-signal 2>
- <anti-signal 3>

## Real-world examples

*Two to four concrete examples a business user would recognize. Pattern-matching against examples is one of the skill's strongest signals — make them tangible.*

- <example 1 — what it is + why it's a good fit>
- <example 2>
- <example 3>

## What's bundled out of the box

*What does a new project on this pattern get for free? Listed so the user understands they don't need to spec or build these.*

- <bundled item 1 — e.g., "ready-to-edit page layout with header and navigation">
- <bundled item 2 — e.g., "automatic deploys when you push code">
- <bundled item 3 — e.g., "TLS / HTTPS handled by the platform">
- <bundled item 4>

## Pairs well with

*Other patterns in this catalog that commonly combine with this one. If the user's signals span this pattern + another, the skill recommends both as a pair. Empty if this pattern is fully standalone.*

- **[<Other Pattern Name>](./<other-pattern-id>.md)** — <one sentence on when you'd pair them and how they connect>
- <another pairing if applicable>

## Cost estimate

*Rough monthly hosting cost for a typical small deployment. Used to set expectations — the user shouldn't be surprised by the bill. Repeat the `monthly_cost_estimate` from frontmatter here in prose with any caveats.*

- **Typical monthly cost:** <e.g., "$5–15/mo for a low-traffic deployment">
- **What drives cost up:** <e.g., "heavy traffic, large file storage, database size">

## Technical details

*The engineering details — for the architect agent, reviewer, or curious engineers. The skill does not match against this section, but the architect needs it once a pattern is picked.*

- **Language / runtime:** <e.g., "TypeScript on Node.js 22 LTS">
- **Framework:** <e.g., "React 18 + Vite">
- **Build / test:** <e.g., "Vite for build; Vitest for tests">
- **Deployment shape:** <e.g., "Static assets served by nginx in a container">
- **Repo template:** <link or path to the scaffold repo / starter>
- **Notes for the architect:** <anything pattern-specific that affects design — strict-mode defaults, env conventions, scaffold footguns, etc.>

## Owner contact for questions

- **Slack:** <#channel-name>
- **Escalation:** <person or role>
