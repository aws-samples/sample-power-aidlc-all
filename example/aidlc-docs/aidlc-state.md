# AI-DLC State — TaskFlow (Example)

> This is an **example** state file showing how AI-DLC tracks progress through the
> workflow. It records the sample project, detected type, and the status of each
> phase. In a real project the agent updates this file as phases complete.

## Project

- **Name:** TaskFlow
- **Summary:** A team task-management SaaS that lets small teams create projects,
  assign tasks, track progress on a Kanban board, and get notified of due dates.
- **Detected project type:** Brownfield (existing code found) — so the workflow
  includes **Reverse Engineering** as phase 1. A greenfield project would skip it
  and start at Requirements.

## Phase status

| # | Phase | Group | Artifact | Status |
|---|-------|-------|----------|--------|
| 1 | Reverse Engineering | Inception | `inception/reverse-engineering/01-reverse-engineering.md` | ✅ Done |
| 2 | Requirements analysis and validation | Inception | `inception/requirements/02-requirements.md` | ✅ Done |
| 3 | User story creation | Inception | `inception/user-stories/03-user-stories.md` | ✅ Done |
| 4 | Application Design | Inception | `inception/design/04-application-design.md` | ✅ Done |
| 5 | Creating units of work for parallel development | Construction | `construction/units-of-work/05-units-of-work.md` | ✅ Done |
| 6 | Risk assessment and complexity evaluation | Construction | `construction/risk-assessment/06-risk-assessment.md` | ✅ Done |
| 7 | Detailed component design | Construction | `construction/component-design/07-component-design.md` | ✅ Done |
| 8 | Code generation and implementation | Construction | `construction/code-generation/08-code-generation.md` | ✅ Done |
| 9 | Build configuration and testing strategies | Construction | `construction/build-config/09-build-config.md` | ✅ Done |
| 10 | Quality assurance and validation | Construction | `construction/qa/10-quality-assurance.md` | ✅ Done |
| 11 | Deployment automation and infrastructure | Operations | `operations/deployment/11-deployment.md` | ✅ Done |
| 12 | Monitoring and observability setup | Operations | `operations/monitoring/12-monitoring.md` | ✅ Done |
| 13 | Production readiness validation | Operations | `operations/production-readiness/13-production-readiness.md` | ✅ Done |

## Notes

- **Greenfield vs brownfield:** greenfield projects have 12 phases (2–13 below,
  renumbered 1–12). Brownfield adds Reverse Engineering on top, for 13 total.
- The three groups map to the AI-DLC lifecycle: **Inception** (what & why),
  **Construction** (how), and **Operations** (deploy & run).
