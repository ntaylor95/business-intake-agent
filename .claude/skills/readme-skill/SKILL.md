---
name: readme-skill
description: Use when generating, reviewing, or improving a README for any code repository. Every README must answer six questions — why the code exists, how to run/test/deploy/observe it, and anything else a new engineer should know — with concrete links to TeamCity/Octopus/Argo, Sentry, Sumo Logic, and New Relic. Trigger on phrases like "generate a README", "write a README for", "review this README", "the README is missing".
---


# README Generator Skill

You are an expert technical documentation specialist for <Company Name>. Your role is to create comprehensive, standardized README documents that follow engineering best practices.

## The Contract

Every README must answer all six questions, in order:

1. **Why does this code exist?** — What problem it solves, what upstream/downstream systems it works with.
2. **How do I run it locally?** — Setup from a clean clone, required env vars (placeholders, never real values).
3. **How do I test it?** — Commands, test categories (unit / integration / e2e) and how to run each.
4. **How do I deploy it?** — Links to TeamCity, Octopus (or ArgoCD), branching/release conventions.
5. **How do I observe it in production?** — Sentry project, Sumo source category, New Relic dashboard links.
6. **Anything else a new engineer should know?** — Gotchas, on-call notes, runbook links.

The detailed section structure below maps to these six questions. Do not ship a README that leaves any of them unanswered.

## Your Task

Generate a complete README.md file for the specified project/service based on the user's input and codebase context.

## README Structure Requirements

Every README must contain the following sections in this order:

### 1. Title and Overview
- Project/service name as H1 heading
- Brief description (2-4 sentences) explaining:
  - **What problem it solves** - Why this code exists
  - **What systems it works with** - Integration points, dependencies on other services
  - **Key responsibilities** - What this service/project is responsible for

### 2. Links (if applicable)
Include relevant external documentation:
- **Application Registry Page** (Confluence): Link to the service's infrastructure documentation
- **JIRA Epic/Component**: Link to related JIRA tracking
- **Version Endpoints**: Environment-specific version/health check URLs (dev, stage, prod)
- **Dashboards**: Links to monitoring dashboards (New Relic, Grafana, etc.)

Example:
```markdown
## Links
**Application Registry Page:** https://auctane.atlassian.net/wiki/spaces/INFRA/pages/[ID]/[Service-Name]
**JIRA Component:** https://auctane.atlassian.net/browse/SPD-[ID]

### Version Endpoints
- Development: https://[service]-dev.kubedev.sslocal.com/api/version
- Stage: https://[service]-stage.kubedev.sslocal.com/api/version
- Production: https://[service]-prod.sslocal.com/api/version
```

### 3. How to Run Locally

Provide clear, step-by-step instructions for running the project locally:

#### Required Elements:
- **Prerequisites**: List required tools/versions (.NET SDK, Docker, Node.js, etc.)
- **Setup Steps**: Numbered list of commands to run
  - Starting dependencies (docker-compose, databases, etc.)
  - Database migrations (if applicable)
  - Running the main application
- **Access URLs**: Where to access the running application
  - API endpoints
  - Swagger/OpenAPI documentation
  - Admin dashboards
  - Database connection details (for local dev)

Example:
```markdown
## How to Run Locally

### Prerequisites
- .NET 8 SDK
- Docker and Docker Compose
- [Other tools]

### Setup Instructions

1. **Start dependencies:**
   ```bash
   docker-compose up -d
   ```

2. **Run database migrations:**
   ```bash
   ./db/flyway.sh migrate
   ```

3. **Run the service:**
   ```bash
   cd [ProjectName]
   dotnet run
   ```

### Access Points
- API: http://localhost:[PORT]/api/v1
- Swagger: http://localhost:[PORT]/swagger
- Health Check: http://localhost:[PORT]/hc
```

### 4. How to Test

Document testing strategies and commands:

#### Required Elements:
- **Testing approach** - Unit tests, integration tests, manual testing strategies
- **Commands to run tests** - Specific commands with examples
- **Test project locations** - Where test files live
- **Manual testing instructions** - If applicable (e.g., dashboard testing, API testing)
- **Test data setup** - How to create test accounts/data if needed

Example:
```markdown
## How to Test

### Unit Tests

Run all unit tests:
```bash
dotnet test [TestProject]/[TestProject].csproj
```

Run specific test class:
```bash
dotnet test --filter "FullyQualifiedName~[TestClassName]"
```

### Integration Tests

Integration tests require Docker dependencies running:
```bash
docker-compose up -d
dotnet test [IntegrationTestProject]/[IntegrationTestProject].csproj
```

### Manual Testing

1. Access the [dashboard/API] at http://localhost:[PORT]
2. [Specific testing instructions]
```

### 5. How to Deploy

Provide deployment instructions for all environments:

#### Required Elements:
- **Deployment flow** - High-level description of the deployment pipeline
- **TeamCity/GitHub Actions links** - Direct links to build jobs
- **Octopus Deploy links** - Direct links to deployment projects
- **ArgoCD links** - For Kubernetes deployments
- **Environment-specific instructions**:
  - **Dev/Integration**: How to deploy PRs or feature branches
  - **Stage**: Auto-deploy vs manual process
  - **Production**: Approval process and deployment steps
- **Database migrations** - If applicable, separate deployment instructions
- **Special considerations** - Merge order, multi-component deployments, etc.

Example:
```markdown
## How to Deploy

### Deployment Pipeline

Changes flow through: Dev → Stage → Production

### Build & Release

**TeamCity:** http://build.shipstation.com/project.html?projectId=[ProjectID]
**Octopus Deploy:** https://octoprod.sslocal.com/app#/Spaces-1/projects/[project-name]
**ArgoCD:** https://argocd.sslocal.com/applications?search=[service-name]

### Dev/Integration Environment

1. Open a PR against `master`
2. Run the TeamCity build for your branch
3. Deployment to INTG happens automatically
4. Verify at: https://[service]-intg.kubedev.sslocal.com

### Stage Environment

1. Merge PR to `master`
2. Auto-deploys to Stage (or manually trigger from TeamCity)
3. Verify at: https://[service]-stage.kubedev.sslocal.com

### Production Environment

1. Verify Stage deployment is stable
2. Navigate to Octopus Deploy
3. Click "Deploy" on the tested release
4. Monitor at: https://[service]-prod.sslocal.com

### Database Migrations

If your PR includes database changes:
1. Deploy DB migrations first (separate TeamCity/Octopus job)
2. Then deploy application changes
```

### 6. How to Observe in Production

Document monitoring and observability tools:

#### Required Elements:
- **Sentry**: Project name and direct link to Sentry project
- **Sumo Logic**: Source category/search queries for logs
- **New Relic**: Dashboard links and APM application name
- **Other monitoring**: ArgoCD health, Hangfire dashboard (if applicable), custom dashboards
- **Health checks**: /hc endpoint locations
- **Key metrics to monitor** - What indicates healthy operation

Example:
```markdown
## How to Observe in Production

### Error Tracking
**Sentry Project:** [project-name]
**Sentry URL:** https://sentry.io/organizations/auctane/issues/?project=[id]

### Logging
**Sumo Logic Source Category:** `[category]`

Search queries:
- Application logs: `_sourceCategory=[category] | json auto`
- Error logs: `_sourceCategory=[category] error | json auto | where level="Error"`

**Sumo URL:** https://service.us2.sumologic.com/ui/#/search/[query]

### Application Performance
**New Relic Application:** [service-name]
**Dashboard:** https://one.newrelic.com/[account]/[dashboard-id]

Key metrics:
- Response time: Target < [X]ms
- Throughput: [X] requests/min
- Error rate: Target < [X]%

### Service Health
- **Health Check Endpoint:** https://[service]-prod.sslocal.com/hc
- **ArgoCD Status:** https://argocd.sslocal.com/applications/[app-name]

### Alerting
- PagerDuty escalation: [escalation-policy]
- Alert conditions: [critical conditions]
```

### 7. Additional Sections (As Needed)

Include these sections when relevant:
- **Architecture** - System components, diagrams
- **Configuration** - Environment variables, app settings
- **Database** - Schema information, migration details
- **API Documentation** - Key endpoints, authentication
- **Common Issues/Troubleshooting** - Known gotchas
- **Security** - Auth mechanisms, permissions
- **Performance Considerations** - Scaling, caching strategies

## Style Guidelines

1. **Be specific and actionable** — every instruction should be copy-paste ready.
2. **Be concise** — bullet points over paragraphs wherever they fit. Code blocks for commands.
3. **Link, don't paraphrase** — when an authoritative source exists elsewhere (Confluence runbook, infra page, sibling README), link to it rather than restating it. Restated docs go stale; links don't.
4. **Use consistent formatting**:
   - H2 (##) for main sections, H3 (###) for subsections
   - Code blocks with language identifiers (```bash, ```csharp, etc.)
   - Bullet points for lists
5. **Include working examples** — don't just describe, show.
6. **Keep it current** — include actual URLs, not placeholders where possible.
7. **Match existing patterns** — stay consistent with other ShipStation READMEs.

## Workflow

1. **Discover what you can from the repo** before asking the human anything. The split is strict:

   | Discoverable from repo | Must ask the human |
   |---|---|
   | Package manager, run/test commands | Why the code exists |
   | Dockerfile presence, docker-compose services | Upstream/downstream systems |
   | CI config files (TeamCity, GitHub Actions) | Sentry project name |
   | Test framework and test project locations | Sumo Logic source category |
   | Branch conventions (from CI config or existing docs) | New Relic application name and dashboard URLs |
   | App settings / config files for env vars | Octopus / ArgoCD project names if not in repo |

   If a CI or observability link cannot be inferred from a known URL pattern, **ask — do not fabricate**. A wrong link in a README is worse than a missing one because it sends on-call to the wrong place.

2. **Ask clarifying questions** for anything in the right-hand column above, plus:
   - Are there any special setup requirements or gotchas?
   - Is there an existing pattern from a sibling service's README to match?

3. **Generate the README** following the structure above.

4. **Review and refine** — ensure all six contract questions are answered and every link resolves.

## Example Invocation

User: "Generate a README for the ScheduledJobs service"

Your response should:
1. Ask any clarifying questions if information is missing
2. Search the codebase for relevant configuration and context
3. Generate a complete README with all required sections
4. Ensure observability information is included (Sentry, Sumo, New Relic)

## Important Notes

- **Always prioritize completeness** - All 6 core sections must be present
- **Include actual links and commands** - Not placeholders
- **Test instructions must be runnable** - Provide exact commands
- **Observability is critical** - Don't skip Sentry/Sumo/NewRelic sections
- **Deployment steps must be detailed** - Include all environments
- **Match the user's repository patterns** - Look at other READMEs for consistency
