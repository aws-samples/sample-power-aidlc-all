# Units of Work — EV Charge Scheduling

> AI-DLC Inception artifact (Chapter 6.3). Decomposition makes the cloud/in-vehicle
> split and the safety boundary structural. Two principles: isolate the safety
> boundary in its own unit, and align units with how they are verified.

## Unit table
| Unit | Where it runs | Traces to | Safety posture |
|---|---|---|---|
| U1 Schedule API & app integration | Cloud | US-03, CS-SEC-005 | QM; security-sensitive |
| U2 Tariff-optimization & planning | Cloud | US-07, CS-FR-014 | QM |
| U3 In-vehicle charge-management service | Vehicle | CS-FR-014, CS-FR-021 | QM, but interfaces with BMS |
| U4 BMS interface adapter | Vehicle | CS-SR-002, CS-SR-003 | Safety-relevant boundary |
| U5 OTA packaging & delivery | Cloud + vehicle | OTA intent, R156 baseline | QM; release-governed |
| U6 Status & telemetry feedback | Vehicle -> Cloud | US-15 acceptance criteria | QM; privacy-sensitive |

## Compact form
```text
U1  cloud-schedule-api       stories: US-03        deploy: cloud service
U2  tariff-planner           stories: US-07        deploy: cloud service
U3  charge-management-svc    stories: US-03, US-11 deploy: in-vehicle (AUTOSAR Adaptive)
U4  bms-interface-adapter    stories: US-11        safety-relevant boundary
U5  ota-delivery             R156 baseline         deploy: cloud + vehicle
U6  telemetry-feedback       privacy-sensitive     vehicle -> cloud
```

## Dependency matrix
```text
U3 -> U4   (BMS interface contract stabilizes first)
U1 -> U2   (API surfaces the planner)
U6 -> U1   (telemetry flows back through the cloud)
```

## Mapping to source tree (this repo)
| Unit | Path under code/ |
|---|---|
| U1 | cloud/schedule-api/ |
| U2 | cloud/tariff-planner/ |
| U3 | in-vehicle/charge-management-service/ |
| U4 | in-vehicle/bms-interface-adapter/ |
| U5 | ota/ |
| U6 | telemetry/ |

## Sequencing note
Each unit is a candidate Bolt. The BMS interface contract (U4) stabilizes before
the in-vehicle service (U3) that depends on it, even though U3 is generated
against the agreed contract in parallel.
