# Phase 7 — Detailed Component Design (Example)

> **Group:** Construction · **Greenfield phase 6 / Brownfield phase 7**
> **Purpose:** Design individual components, their interfaces, and data shapes in
> enough detail to implement.

## 1. Tasks API component

### Endpoints

| Method | Path | Body / Query | Returns |
|--------|------|--------------|---------|
| GET | `/projects/:id/tasks` | `page`, `pageSize` | `{ items: Task[], nextCursor }` |
| POST | `/projects/:id/tasks` | `{ title, description?, assigneeId?, dueDate? }` | `Task` |
| PATCH | `/tasks/:id` | `{ status? , assigneeId?, dueDate? }` | `Task` |

### Task shape

```json
{
  "id": "t_123",
  "projectId": "p_9",
  "title": "Write API docs",
  "status": "todo",
  "assigneeId": "u_42",
  "dueDate": "2026-09-01T00:00:00Z"
}
```

### Rules

- `status` transitions limited to `todo -> doing -> done` (and back).
- Pagination uses a keyset cursor on `(dueDate, id)` for stable ordering.

## 2. Reminder worker component

- Runs every 5 minutes.
- Query: tasks with `dueDate` within the next 24h or overdue and not yet notified.
- Writes a `Notification` row with an idempotency key `taskId:window`.
- Enqueues an email job; the queue handles retries.

## 3. Session middleware component

- Reads `sid` cookie → looks up session in Redis → attaches `req.user`.
- On login: create session, set `sid` (HttpOnly, Secure, SameSite=Lax).
- TTL 7 days, sliding expiration.

## 4. Error handling

Uniform error envelope: `{ error: { code, message } }` with appropriate HTTP
status codes (400/401/403/404/409/500).
