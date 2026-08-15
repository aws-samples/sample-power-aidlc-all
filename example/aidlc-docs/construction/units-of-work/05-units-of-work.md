# Phase 5 — Creating Units of Work for Parallel Development (Example)

> **Group:** Construction · **Greenfield phase 4 / Brownfield phase 5**
> **Purpose:** Break the design into independent units that teams can build in
> parallel, with clear interfaces and dependencies.

## 1. Units of work

| UoW | Scope | Depends on | Owner (example) |
|-----|-------|-----------|-----------------|
| UoW-A | Auth + Redis sessions | — | Team 1 |
| UoW-B | Projects CRUD API | UoW-A | Team 1 |
| UoW-C | Tasks API + pagination | UoW-B | Team 2 |
| UoW-D | Kanban board UI | UoW-C (API contract) | Team 3 |
| UoW-E | Reminder worker + Notifications | UoW-C | Team 2 |

## 2. Dependency graph

```
UoW-A ──> UoW-B ──> UoW-C ──> UoW-D
                       └────> UoW-E
```

## 3. Interface contracts (enable parallelism)

- **Auth:** `POST /auth/login`, `POST /auth/logout`, session cookie `sid`.
- **Tasks:** `GET /projects/:id/tasks?page=&pageSize=`, `POST /projects/:id/tasks`,
  `PATCH /tasks/:id`.
- UI teams code against these contracts (mocked) before the API is finished.

## 4. Parallelization plan

- Week 1: UoW-A in isolation; others scaffold against mock contracts.
- Week 2: UoW-B and UoW-C land; UoW-D and UoW-E integrate.
- Each unit is independently testable and mergeable behind a feature flag.
