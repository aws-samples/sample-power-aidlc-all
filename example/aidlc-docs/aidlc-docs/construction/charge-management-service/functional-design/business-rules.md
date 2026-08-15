# Business Rules — charge-management-service

> AI-DLC Construction artifact (Chapter 7.2). Technology-agnostic. These rules
> encode the safety boundary as behavior so no later platform choice can discard
> it.

BR-01  Charging MAY be commanded only within the BMS-permitted envelope.
BR-02  A BMS inhibit MUST stop charge initiation immediately (hard, non-overridable).
BR-03  Loss of the BMS interface MUST drive a safe idle state.
BR-04  Safety/charge limits ALWAYS take precedence over cost optimization.
BR-05  With no connectivity, the most recent cached plan executes locally.

## Rule -> requirement traceability
| Rule  | Source requirement |
|-------|--------------------|
| BR-01 | CS-SR-002 |
| BR-02 | CS-SR-002 |
| BR-03 | CS-SR-003 |
| BR-04 | CS-FR-030 |
| BR-05 | CS-FR-021 |

## Notes
- BR-02 and BR-03 are HARD real-time and safety-relevant. They are realized in
  the BMS adapter / safety monitor (U4), which is human-engineered and HIL-verified.
- The QM-rated service (U3) must not be able to interfere with the BMS authority
  (freedom from interference).
