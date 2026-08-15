# Design Questions — EV Charge Scheduling (Mob Construction)

> AI-DLC Construction artifact (Mob Construction, Chapter 7.4). The AI proposes
> architecture options with trade-offs as a questionnaire; the mob decides. Each
> answered question becomes an architecture decision record (ADR). Answer with
> the letter after `[Answer]:`; choose "Other" to record a different decision.
>
> The mob may add, modify, or remove questions — the workflow re-reads the file
> and records the chosen options as ADRs.
>
> Note: question wording and order are generated and may vary between runs; the
> recorded `[Answer]:` choices and the ADRs they produce are authoritative, not
> the phrasing.

## Question 1
Where should the scheduling intelligence live?

A) Plan in the cloud; ship a resolved plan to the vehicle with an on-vehicle cache and safe local fallback

B) Push full planning logic onto the vehicle for maximum autonomy

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
How should the BMS boundary be structured?

A) A single, isolated BMS interface adapter unit (U4) — the only component that talks to the BMS

B) Inline the BMS calls inside the charge-management service

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
How are cloud-to-vehicle commands secured?

A) mTLS + IAM-scoped credentials

B) Static API key

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## ADRs recorded from these answers
| Answer | ADR | Realized in |
|--------|-----|-------------|
| Q1 = A | Cloud planning + on-vehicle resolved-plan cache & fallback (CS-FR-021) | `cloud/tariff-planner/`, `schedule_executor.cpp` plan-cache |
| Q2 = A | Isolated BMS adapter as sole safety-relevant component | `in-vehicle/bms-interface-adapter/` |
| Q3 = A | mTLS + IAM-scoped credentials (CS-SEC-005, R155) | `cloud/schedule-api/.../auth.py`, infrastructure-design.md |
