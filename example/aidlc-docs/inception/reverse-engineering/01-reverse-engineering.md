# Phase 1 — Reverse Engineering (Example)

> **Group:** Inception · **Applies to:** Brownfield projects only
> **Purpose:** Analyze an existing codebase to reconstruct requirements,
> architecture, and design artifacts before making changes.

This example assumes TaskFlow already had a small, undocumented v1 codebase. The
Reverse Engineering phase captures what exists so later phases build on reality.

## 1. Codebase inventory

| Area | Findings |
|------|----------|
| Language / runtime | TypeScript, Node.js 18, React 18 (Vite) |
| Backend | Express REST API in `src/api/` |
| Data store | PostgreSQL accessed via Prisma ORM |
| Auth | Session cookies, bcrypt password hashing |
| Tests | A handful of Jest unit tests in `src/__tests__/` |
| CI | None found |

## 2. Reconstructed architecture

```
Browser (React SPA)  ->  Express API  ->  PostgreSQL
                              |
                              +-- session store (in-memory, single instance)
```

## 3. Recovered domain model

- **User** — id, email, passwordHash, displayName
- **Project** — id, name, ownerId
- **Task** — id, projectId, title, status (todo/doing/done), assigneeId, dueDate

## 4. Observations & gaps

- No pagination on the task-list endpoint (will not scale).
- Sessions held in memory — breaks under horizontal scaling.
- No automated tests for the API layer.
- No infrastructure-as-code or deployment automation.

## 5. Output feeding later phases

These findings become inputs to **Requirements** (what to keep vs. change),
**Application Design** (target architecture), and **Risk assessment**
(scaling & session risks).
