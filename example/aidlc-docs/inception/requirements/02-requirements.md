# Phase 2 — Requirements Analysis and Validation (Example)

> **Group:** Inception · **Greenfield phase 1 / Brownfield phase 2**
> **Purpose:** Gather, analyze, and validate what the product must do and why.

## 1. Problem statement

Small teams juggle tasks across chat threads and spreadsheets. They need one
place to organize projects, assign work, and see status at a glance.

## 2. Goals

- G1 — Let a team create projects and manage tasks on a Kanban board.
- G2 — Assign tasks to members and track status (todo / doing / done).
- G3 — Notify assignees of upcoming and overdue due dates.
- G4 — Support horizontal scaling (fix the v1 single-instance limitation).

## 3. Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | A user can sign up, log in, and log out. | Must |
| FR-2 | A user can create, rename, and archive projects. | Must |
| FR-3 | A user can create tasks with a title, description, assignee, and due date. | Must |
| FR-4 | A user can move a task between columns (todo/doing/done). | Must |
| FR-5 | The system notifies assignees 24h before and on overdue. | Should |
| FR-6 | Task lists are paginated (25 per page). | Must |

## 4. Non-functional requirements

- **NFR-1 Performance:** task board loads in < 1s for 500 tasks.
- **NFR-2 Availability:** 99.9% monthly uptime target.
- **NFR-3 Security:** passwords hashed; sessions valid across instances.
- **NFR-4 Scalability:** stateless API behind a load balancer.

## 5. Assumptions & constraints

- Web-only for v2 (no native mobile app yet).
- PostgreSQL retained from v1 to reduce migration risk.

## 6. Validation

Each requirement is testable and traces forward to a user story in Phase 3.
Open questions were resolved with the (example) product owner before sign-off.
