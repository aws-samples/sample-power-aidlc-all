# Hazard Analysis and Risk Assessment (HARA) — EV Charge Scheduling

> AI-DLC Inception artifact (Chapter 12.2). HARA is human-owned; AI-DLC does not
> perform it. This fragment fixes the top of one traceability thread: a hazard,
> its classification and safety goal, and the derived safety requirement that
> flows through design to hardware-verified test. It is recorded here so the
> human-owned safety activity has a clean place to attach in the requirements
> trail, and so an assessor can walk the thread backward from a field event to the
> controlling hazard.

```text
# HARA fragment — EV charge scheduling   (aidlc-docs/inception/requirements/safety/hara.md)

Hazard:          uncontrolled charging during a battery thermal fault
Consequence:     risk of thermal runaway
Classification:  ASIL-C/D (severity x exposure x controllability)
Safety goal:     charging must never proceed while the BMS signals a thermal inhibit
Derived req:     CS-SR-002 (honor BMS inhibit immediately; non-overridable)
```

## Second thread (BMS interface loss)

```text
Hazard:          charging continues after loss of the BMS interface
Consequence:     charging outside the authoritative safety envelope
Classification:  ASIL-relevant
Safety goal:     loss of the BMS interface must force a safe idle state
Derived req:     CS-SR-003 (stop initiating charge; enter safe idle)
```

## Traceability
| Hazard | Safety goal | Derived requirement | Design | Verification |
|---|---|---|---|---|
| Uncontrolled charging in thermal fault | Never charge while inhibited | CS-SR-002 | U4 bms-interface-adapter (isolated) | HIL, human-reviewed |
| Charge after interface loss | Safe idle on loss | CS-SR-003 | U4 safe-idle path | HIL, human-reviewed |

The derived requirements land in `../requirements.md` (CS-SR-002/003) and are
verified in `../../../construction/build-and-test/build-and-test-summary.md`.
Generative AI never authors this path; it only gives each human-owned safety
activity a traceable place to attach.
