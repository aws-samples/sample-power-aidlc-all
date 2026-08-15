# Story Planning Questions — EV Charge Scheduling

> AI-DLC Inception artifact (User Stories, Part 1 — Planning, Chapter 6.1). The
> workflow proposes the story plan as a questionnaire before generating stories.
> Answer with the letter after `[Answer]:`; choose "Other" to write your own.
>
> Edit freely: add a question, change options, or remove one that does not apply
> — the workflow re-reads the file and regenerates the plan from your answers.
>
> Note: question wording and order are generated and may vary between runs; the
> recorded `[Answer]:` choices are authoritative, not the phrasing.

## Question 1
Which actors should get first-class user stories for this feature?

A) Driver, the vehicle (autonomous actor), and the fleet operator

B) Driver only

C) Driver and fleet operator only

D) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
Should acceptance criteria include degraded-mode behavior?

A) Yes — when the target cannot be met (short plug-in, grid fault) the driver is notified with the reason

B) No — only the happy path

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
How should each story relate to the approved requirements?

A) Every story keeps an explicit "Traces to" link to a requirement ID

B) Stories stand alone; traceability is added later

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## How the answers shaped the stories
| Answer | Result | Realized in |
|--------|--------|-------------|
| Q1 = A | US-03 (driver), US-11 (vehicle), US-07 (fleet) | `inception/user-stories/stories.md`, `personas.md` |
| Q2 = A | Degraded-mode acceptance criteria on US-03/US-15 | `stories.md` (acceptance criteria) |
| Q3 = A | Each story carries "Traces to: CS-..." | `stories.md` |
