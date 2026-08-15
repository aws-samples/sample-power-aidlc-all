# Requirements — EV Charge Scheduling

> AI-DLC Inception artifact (Chapter 5.3). Structured, uniquely identified,
> individually verifiable, tagged for safety (ASIL) and timing. Safety
> constraints (CS-SR-*) bound what generated code may do; they are not features
> the AI builds.

## Intent Analysis
- User request:  Schedule EV charging to a target SoC by a driver-set departure time
- Request type:  New Feature
- Scope:         Multiple Components (cloud + in-vehicle + OTA)
- Complexity:    Complex

## Captured Intent (summary)
- **Intent:** charge an EV to a target SoC by a driver-set departure time,
  minimizing cost and battery wear, with cabin pre-conditioning.
- **In scope:** mobile trigger, cloud scheduling, tariff optimization, in-vehicle
  charge sequencing, OTA delivery, status feedback.
- **Out of scope:** the battery thermal protection and cell-balancing control
  itself (owned by the BMS; safety-relevant), public-charger payment.
- **Flags:** safety boundary at the BMS interface; UNECE R156 applies; location
  and usage data are privacy-sensitive (R155/privacy).
- **Open questions (resolved in Mob Elaboration):** behavior with no connectivity,
  conflicting schedules, tariff data source, target SoC limits.

## Functional Requirements
| ID | Requirement | Type | ASIL | Timing | Verify |
|---|---|---|---|---|---|
| CS-FR-014 | The vehicle shall begin charging so the battery reaches the target SoC no later than the set departure time, when a valid schedule and grid power are present. | Functional | QM | Soft: ready by departure | SIL + HIL |
| CS-FR-021 | When no connectivity is available, the vehicle shall execute the most recent cached schedule without requiring the cloud. | Functional | QM | — | SIL + field |
| CS-FR-030 | The system shall resolve conflicts between app, recurring, and demand-response schedules using a documented precedence in which safety/charge limits always win over cost optimization. | Functional | QM | — | SIL + review |
| CS-FR-031 | The system shall report charge status (on-track, delayed, complete, fault) back to the driver. | Functional | QM | Soft | SIL + field |

## Non-Functional Requirements
| ID | Requirement | Type | ASIL | Timing | Verify |
|---|---|---|---|---|---|
| CS-NFR-007 | Cabin pre-conditioning shall complete within a configurable window before departure without delaying readiness of the target SoC. | Non-functional | QM | Soft | SIL |
| CS-NFR-009 | The in-vehicle service shall continue safe degraded operation across connectivity loss and stale tariff data. | Non-functional (reliability) | QM | — | SIL + field |

## Safety Requirements / Constraints
| ID | Requirement | Type | ASIL | Timing | Verify |
|---|---|---|---|---|---|
| CS-SR-002 | The charge-management service shall treat BMS thermal and cell protection limits as authoritative and shall not command charging that the BMS has inhibited. | Safety constraint | Inherited (BMS ASIL-C/D) | Hard: honor inhibit immediately | HIL + review |
| CS-SR-003 | A loss of the BMS interface shall cause the service to stop initiating charge and enter a safe idle state. | Safety constraint | ASIL-relevant | Hard | HIL |

## Security Requirements
| ID | Requirement | Type | ASIL | Timing | Verify |
|---|---|---|---|---|---|
| CS-SEC-005 | All app-to-cloud and cloud-to-vehicle schedule commands shall be authenticated and integrity-protected. | Non-functional (security) | QM (security) | — | Review + penetration test |

## SOTIF / Edge-case scenarios (logged for test generation — ISO 21448)
- Degraded SoC/temperature sensor readings.
- Stale tariff data (planner falls back to a safe default window).
- Plug pulled mid-charge.
- Clock skew across cloud and vehicle.
- Cold ambient slowing charge acceptance (later surfaced in Operations).

## Traceability seeds
| Inception artifact | Links to | Seeds (standard) |
|---|---|---|
| Captured intent | Elaboration decisions | Rationale for the safety case |
| Elaboration decisions | Requirements + constraints | ASPICE work product traceability |
| Requirements (CS-FR/NFR/SR) | Design, code, tests | ISO 26262 bidirectional traceability |
| Safety constraints (CS-SR-*) | BMS interface, verification | Hazard-to-requirement links |
| Requirement baseline | OTA package | UNECE R156 version traceability |
