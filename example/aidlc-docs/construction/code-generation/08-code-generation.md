# Phase 8 — Code Generation and Implementation (Example)

> **Group:** Construction · **Greenfield phase 7 / Brownfield phase 8**
> **Purpose:** Generate and implement the code for each component, following the
> detailed design.

This artifact records **what was implemented** and links design to source. In a
real run, the agent writes actual code files; here we show representative
snippets and a file map.

## 1. Implementation file map

| Component | Files (example) |
|-----------|-----------------|
| Session middleware | `src/api/middleware/session.ts` |
| Tasks API | `src/api/routes/tasks.ts`, `src/api/services/taskService.ts` |
| Reminder worker | `src/worker/reminders.ts` |
| Data model | `prisma/schema.prisma`, `prisma/migrations/` |

## 2. Representative snippet — paginated task list

```ts
// src/api/routes/tasks.ts
router.get("/projects/:id/tasks", requireAuth, async (req, res) => {
  const pageSize = Math.min(Number(req.query.pageSize ?? 25), 100);
  const cursor = req.query.cursor as string | undefined;
  const items = await taskService.list(req.params.id, { pageSize, cursor });
  res.json({ items, nextCursor: taskService.nextCursor(items, pageSize) });
});
```

## 3. Representative snippet — idempotent reminder

```ts
// src/worker/reminders.ts
for (const task of dueTasks) {
  const key = `${task.id}:${window}`;
  const created = await notifications.createIfAbsent(key, task);
  if (created) await queue.enqueue("email.reminder", { taskId: task.id });
}
```

## 4. Traceability

- FR-6 (pagination) → task list snippet.
- FR-5 (reminders) → worker snippet.
- AD-1 (Redis sessions) → session middleware.

## 5. Definition of done for this phase

Code compiles, adheres to the component contracts, and passes lint. Tests and QA
are handled in Phases 9–10.
