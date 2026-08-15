# Phase 3 — User Story Creation (Example)

> **Group:** Inception · **Greenfield phase 2 / Brownfield phase 3**
> **Purpose:** Turn requirements into user stories with acceptance criteria.

Stories use the form: _As a **role**, I want **capability**, so that **benefit**._
Each maps back to a requirement (FR/NFR) from Phase 2.

## US-1 — Sign in (FR-1)

As a team member, I want to log in with email and password, so that I can access
my team's projects.

**Acceptance criteria**
- Given valid credentials, when I submit the login form, then I land on my
  dashboard.
- Given invalid credentials, then I see an "invalid email or password" error.
- Given 5 failed attempts, then the account is rate-limited for 15 minutes.

## US-2 — Create a project (FR-2)

As a team member, I want to create a project, so that I can group related tasks.

**Acceptance criteria**
- A project requires a non-empty name.
- The creator becomes the project owner.
- The new project appears in my project list immediately.

## US-3 — Add and assign a task (FR-3)

As a project member, I want to create a task and assign it to a teammate, so that
responsibility is clear.

**Acceptance criteria**
- A task requires a title; description, assignee, and due date are optional.
- Only project members can be assignees.
- The assignee sees the task on their "My Tasks" view.

## US-4 — Move a task on the board (FR-4)

As a project member, I want to drag a task between columns, so that the board
reflects real progress.

**Acceptance criteria**
- Moving a task persists its new status.
- The board updates for other viewers within 5 seconds.

## US-5 — Get due-date reminders (FR-5)

As an assignee, I want reminders before a task is due, so that I don't miss
deadlines.

**Acceptance criteria**
- A notification is sent 24h before the due date and again if overdue.
- Notifications respect the user's per-project mute setting.

## Prioritization

US-1 → US-4 are the MVP (Must). US-5 is a fast-follow (Should).
