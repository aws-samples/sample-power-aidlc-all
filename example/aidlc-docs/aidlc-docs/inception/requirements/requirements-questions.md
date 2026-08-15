# Requirements Clarification Questions — EV Charge Scheduling

> AI-DLC Inception artifact (Mob Elaboration, Chapter 5.2). The workflow does not
> ask questions in chat; it writes them here as a multiple-choice questionnaire.
> Answer each by filling the letter after `[Answer]:`. If no option fits, choose
> the last "Other" option and describe your choice.
>
> You can EDIT this file before answering: add a question, modify or remove
> options, or delete a question that does not apply. The workflow re-reads the
> edited file, so the mob shapes the questions, not just the answers. Two such
> edits the mob made on this feature are marked below.
>
> Note: because the questions are generated, their exact wording and order may
> vary between runs — they may appear renumbered or rephrased. The recorded
> `[Answer]:` choices and the requirements they produce are authoritative, not
> the phrasing.

## Question 1
With no connectivity at the departure time, what should the vehicle do?

A) Execute the most recent cached schedule locally, with no cloud dependency

B) Fall back to immediate charge within the BMS-permitted envelope

C) Wait for connectivity and take no action until a plan arrives

D) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
How should conflicting schedules (app vs. recurring vs. demand-response) be resolved?

A) Documented precedence App > Recurring > Demand-response, with safety/charge limits always winning over cost

B) Cheapest-cost plan always wins regardless of source

C) Most recently issued plan always wins

D) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
What target state-of-charge (SoC) range should the app allow the driver to set?

A) 50-100% with no further restriction

B) 50-80% default for battery longevity, with 100% available as an explicit opt-in

C) Fixed at 100% only

D) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 4   (added by the functional-safety engineer)
On a battery thermal event, which component stops charging?

A) The BMS autonomously, with no dependency on the scheduling logic

B) The charge-management service, on a command from the scheduler

C) Other (please describe after [Answer]: tag below)

[Answer]: A

# Removed before answering
# Q. "Which mobile OS versions must the app support?" — removed by the mob as out
#    of scope for this feature (handled by the separate app program).

## How the answers became requirements / code
| Answer | Decision | Requirement | Realized in |
|--------|----------|-------------|-------------|
| Q1 = A | Cached plan executes offline | CS-FR-021 (BR-05) | `in-vehicle/charge-management-service/src/schedule_executor.cpp` (`Tick` has no cloud dependency) |
| Q2 = A | Source precedence; limits beat cost | CS-FR-030 (BR-04) | `schedule_executor.cpp` (`LoadPlan` precedence) |
| Q3 = B | Default SoC capped; BMS keeps hard limit | requirement note + CS-SR-002 | `ChargePlan.target_soc_pct`; BMS enforces independently (U4) |
| Q4 = A | Inhibit owned by BMS | CS-SR-002 (constraint) | `in-vehicle/bms-interface-adapter/` (human-engineered) |
