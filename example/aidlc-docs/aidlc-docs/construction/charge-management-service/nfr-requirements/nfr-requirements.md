# NFR Requirements — charge-management-service

> AI-DLC Construction artifact (Chapter 9.1). Assessed per unit after functional
> design and before code, so the constraints shape the design. Each line traces
> back to an Inception requirement.

Safety:       BMS limits authoritative; freedom from interference (CS-SR-002/003)
Real-time:    soft RT for readiness-by-departure; HARD inhibit response (CS-FR-014)
Reliability:  operate with no connectivity; safe degraded modes (CS-FR-021)
Security:     authenticated, integrity-protected commands; R155 scope (CS-SEC-005)
Tech stack:   AUTOSAR Adaptive (C++), ara::com; cloud planner separate unit

## Detail
| Family | Constraint | Type | Source |
|---|---|---|---|
| Safety | BMS thermal/cell protection limits authoritative; QM service must not interfere | Hard | CS-SR-002 |
| Safety | Loss of BMS interface -> safe idle | Hard | CS-SR-003 |
| Real-time | Readiness-by-departure | Soft RT | CS-FR-014 |
| Real-time | Honor BMS inhibit within WCET budget | Hard RT | CS-SR-002 |
| Reliability | Execute cached plan offline; bounded retries | — | CS-FR-021, CS-NFR-009 |
| Security | mTLS identity + message integrity on commands | — | CS-SEC-005 |

## Tech-stack decision (recorded)
- In-vehicle: AUTOSAR Adaptive, C++17, `ara::com` service interfaces.
- Cloud planner (U2) and schedule API (U1) are separate units (Python backend).
- Safety-relevant boundary (U4) human-engineered; not generated.
