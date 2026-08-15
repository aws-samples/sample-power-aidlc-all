# NFR Assessment Questions — charge-management-service

> AI-DLC Construction artifact (NFR Requirements, Chapter 9.1). The NFR step
> surfaces the constraint families as a questionnaire so they shape the design
> rather than being retrofitted. Answer with the letter after `[Answer]:`.
>
> Add, modify, or remove questions as the unit demands — e.g., a unit with no
> security surface can delete the security question; the workflow adapts.
>
> Note: question wording and order are generated and may vary between runs; the
> recorded `[Answer]:` choices and the NFR design they produce are authoritative,
> not the phrasing.

## Question 1
What timing class applies to honoring a BMS inhibit?

A) Hard real-time, non-overridable, within a worst-case execution time budget

B) Soft real-time (best effort)

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
What reliability behavior is required when connectivity is lost?

A) Execute the cached plan with bounded retries and fall to a safe idle on BMS interface loss

B) Require connectivity to operate

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
What is the in-vehicle technology stack for this unit?

A) AUTOSAR Adaptive, C++17, ara::com service interfaces

B) Linux container service

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
How are cloud-to-vehicle commands protected?

A) Authenticated and integrity-protected (mTLS + signed payload), R155 scope

B) Network isolation only

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## How the answers became NFR design
| Answer | Constraint | Realized in |
|--------|-----------|-------------|
| Q1 = A | Hard inhibit path (CS-SR-002) | `in-vehicle/bms-interface-adapter/` SafetyMonitor (staleness deadline) |
| Q2 = A | Offline cached plan + safe idle (CS-FR-021, CS-SR-003) | `schedule_executor.cpp`, `bms_client.cpp` |
| Q3 = A | AUTOSAR Adaptive / ara::com | `charge_service_interface.h`, `manifest/` |
| Q4 = A | Command integrity (CS-SEC-005) | `cloud/schedule-api/schedule_api/auth.py` |
