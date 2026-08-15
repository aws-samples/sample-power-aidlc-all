# EV Charge Scheduling — the book's worked example, built with AI-DLC

This directory is the end-to-end, runnable realization of the book's running
example (Chapters 5-10 and the Chapter 17 worked example): **EV charge
scheduling**, carried through one AI-DLC Bolt from intent to field.

It contains both halves the book describes:

1. **`aidlc-docs/`** — the documentation-first AI-DLC artifact trail, named
   exactly as the chapters reference them (intent, requirements, stories, units,
   functional/NFR/infra design, code-gen plan, build-and-test summary, release
   record, monitoring summary, and the audit trail).
2. **The six units of work (U1-U6)** — actual source code spanning cloud,
   in-vehicle, and OTA, with the safety boundary isolated and human-engineered.

## The feature
A driver sets a departure time from an app; the vehicle charges to a target SoC
by then, preferring cheap off-peak tariff windows, pre-conditions the cabin, and
behaves safely with no connectivity. Most of the feature is AI-DLC-accelerated;
the battery's thermal/cell protection limits stay human-engineered and out of the
AI's loop.

## Layout
```
code/
├── aidlc-docs/                     AI-DLC documentation-first artifact trail
│   ├── inception/                  reverse-engineering (Ch 13), requirements, user-stories, application-design, next-bolt intent
│   ├── construction/               functional/NFR/infra design, plans, build-and-test summary
│   ├── operations/                 release-record, monitoring-summary
│   ├── aidlc-state.md              stage progress + extension config
│   └── audit.md                    human-accountable evidence spine
│
├── cloud/
│   ├── schedule-api/               U1  authenticated REST API (Python)        US-03, CS-SEC-005
│   └── tariff-planner/             U2  cost-optimizing planner (Python)        US-07, CS-FR-014
├── in-vehicle/
│   ├── charge-management-service/  U3  AUTOSAR-Adaptive-style service (C++)    CS-FR-014/021/030
│   └── bms-interface-adapter/      U4  SAFETY boundary, human-engineered (C++) CS-SR-002/003
├── ota/                            U5  packaging/signing + staged rollout      R156
├── telemetry/                     U6  vehicle->cloud feedback + fleet metrics  CS-FR-031
└── run_all_tests.sh                run every unit's tests
```

## Units of work and the safety boundary
| Unit | Path | Tier | Language | Safety posture |
|---|---|---|---|---|
| U1 schedule-api | `cloud/schedule-api` | Cloud | Python | QM; security-sensitive |
| U2 tariff-planner | `cloud/tariff-planner` | Cloud | Python | QM |
| U3 charge-management-service | `in-vehicle/charge-management-service` | Vehicle | C++17 | QM; interfaces with BMS |
| U4 bms-interface-adapter | `in-vehicle/bms-interface-adapter` | Vehicle | C++17 | **Safety-relevant; human-engineered** |
| U5 ota-delivery | `ota` | Cloud+vehicle | Python | QM; release-governed |
| U6 telemetry-feedback | `telemetry` | Vehicle->cloud | Python | QM; privacy-sensitive |

The bright line of Chapters 8-9: **generative AI never authors the safety-
critical control path.** U4 and U3's `bms_client.cpp` are human-engineered,
review-gated, and HIL-verified; everything else is AI-DLC-accelerated QM code.

## Brownfield companion (Chapter 14)
The running example is built **greenfield** (units U1-U6 from scratch), which is
why the trail above starts at intent and requirements. Chapter 14 addresses the
more common **brownfield** case — adding this feature into an existing vehicle
software estate — and its reverse-engineering artifacts live at:

```
aidlc-docs/inception/reverse-engineering/   (business-overview, architecture,
    code-structure [Existing Files Inventory], api-documentation,
    component-inventory, technology-stack, dependencies, code-quality-assessment,
    reverse-engineering-timestamp)
```

These describe the *pre-existing platform* the feature integrates into (the
supplier telematics gateway, the certified frozen `bms-control`, the R156 OTA
service), named exactly as Chapter 14 references them. They are the brownfield
front end — detect, then reverse-engineer — that precedes the same Inception the
rest of the trail shows.

## Build and test everything
```
./run_all_tests.sh
```
Requirements: `python3` (stdlib only — no pip installs), `cmake >= 3.16`, and a
C++17 compiler. Each unit can also be built/tested on its own (see its README).

## How the code maps to the AI-DLC trail
- Requirement IDs (`CS-FR-014`, `CS-SR-002`, `CS-SEC-005`, ...) appear both in
  `aidlc-docs/` and as comments/tests in the source — the bidirectional
  traceability the book describes (ISO 26262 / ASPICE / R156).
- AI-DLC poses decisions as editable multiple-choice questionnaires (the
  `*-questions.md` files: `inception/requirements/requirements-questions.md`,
  `inception/user-stories/story-planning-questions.md`,
  `construction/charge-management-service/nfr-requirements/nfr-questions.md`,
  `construction/design-questions.md`). Each file's answer-to-code table shows how
  a chosen option became a requirement/decision and where it is realized in source.
- The business rules `BR-01..05` in `functional-design/business-rules.md` are
  implemented by U3's `ScheduleExecutor` and enforced at the boundary by U4.
- The release and monitoring artifacts in `operations/` are produced, in code,
  by U5 (`RolloutController`) and U6 (`FleetAggregator`).
