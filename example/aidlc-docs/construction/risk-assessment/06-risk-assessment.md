# Phase 6 — Risk Assessment and Complexity Evaluation (Example)

> **Group:** Construction · **Greenfield phase 5 / Brownfield phase 6**
> **Purpose:** Identify risks, estimate complexity, and plan mitigations before
> heavy implementation.

## 1. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|------------|
| R-1 | Session migration (memory → Redis) breaks logins | Medium | High | Feature-flag rollout; dual-read during cutover |
| R-2 | Reminder worker sends duplicate notifications | Medium | Medium | Idempotency key per (task, window) |
| R-3 | Task list slow at scale | Low | High | Keyset pagination + index on `(projectId, dueDate)` |
| R-4 | Data migration adds nullable columns incorrectly | Low | Medium | Reversible Prisma migrations + backup before deploy |
| R-5 | Third-party email provider outage | Low | Medium | Queue + retry with backoff; fallback provider |

## 2. Complexity evaluation

| Unit of work | Complexity | Notes |
|--------------|-----------|-------|
| UoW-A Auth/Redis | High | Security-sensitive; touches every request |
| UoW-B Projects | Low | Standard CRUD |
| UoW-C Tasks | Medium | Pagination + status transitions |
| UoW-D Board UI | Medium | Drag-and-drop, optimistic updates |
| UoW-E Reminders | High | Scheduling, idempotency, external I/O |

## 3. Overall assessment

Two high-risk, high-complexity units (Auth/Redis and Reminders) drive the plan.
Both get extra review, feature flags, and integration tests before rollout.
