# Phase 4 — Application Design (Example)

> **Group:** Inception · **Greenfield phase 3 / Brownfield phase 4**
> **Purpose:** Define the target architecture that satisfies the requirements.

## 1. Architecture overview

```
                 +-------------------+
   Browser  ---> |  CDN / Static SPA |  (React, Vite build)
                 +-------------------+
                          |
                          v  HTTPS / REST
                 +-------------------+       +------------------+
   Load        > |   API service     | ----> |  PostgreSQL (RDS)|
   Balancer      |   (Express, stateless)     +------------------+
                 +-------------------+
                          |
                          v
                 +-------------------+       +------------------+
                 |  Redis (sessions  |       |  Worker (cron)   |
                 |   + job queue)    | <---- |  reminders       |
                 +-------------------+       +------------------+
```

## 2. Key design decisions (ADR-style)

| ID | Decision | Rationale |
|----|----------|-----------|
| AD-1 | Move sessions from memory to **Redis**. | Enables stateless API and horizontal scaling (NFR-4). |
| AD-2 | Add a **background worker** for reminders. | Keeps request path fast; scheduled jobs handle notifications (FR-5). |
| AD-3 | Keep **PostgreSQL + Prisma**. | Reuse v1 data model; low migration risk. |
| AD-4 | Serve SPA from a **CDN**. | Meet page-load target (NFR-1). |

## 3. Major components

- **Web SPA** — React app; talks to the API over REST.
- **API service** — auth, projects, tasks, notifications endpoints.
- **Worker** — polls for due tasks and enqueues notifications.
- **Data stores** — PostgreSQL (durable), Redis (sessions + queue).

## 4. Data model (target)

Extends the reverse-engineered model with a `Notification` entity and adds
`Project.archivedAt` for FR-2.

## 5. Traceability

Every component ties to at least one requirement, and the design resolves the two
critical v1 gaps found in Reverse Engineering (sessions, scaling).
