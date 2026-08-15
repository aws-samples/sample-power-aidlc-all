# Deployment Architecture — cloud-schedule-api

> AI-DLC Construction artifact (Chapter 7.3). How the three tiers connect.

## Tier map
| Tier | Components | Responsibility |
|---|---|---|
| Cloud | Schedule API & app integration; tariff-optimization & planning; OTA packaging; telemetry ingestion | Driver-facing API, planning, fleet data, software delivery |
| Edge (optional) | Tariff/grid-signal aggregation | Regional demand-response and tariff feeds where latency/scale warrants |
| In-vehicle | Charge-management service; BMS interface adapter; status feedback | Execute the plan within safe limits; report state |

## Text topology
```text
[Mobile App]
     | HTTPS (authenticated)            CS-SEC-005
     v
[Schedule API]  --calls-->  [Tariff Planner]
     |  schedule command (mTLS, signed)
     v
[OTA / Command channel]  ---->  [In-vehicle charge-management service]
                                        |  ara::com
                                        v
                                  [BMS interface adapter]  <-- safety boundary
                                        |
                                        v
                                  [BMS]  (human-engineered; inhibit always wins)

[In-vehicle telemetry] --MQTT--> [Broker] --stream--> [Fleet data pipeline]
                                                          |
                                                          v
                                                  readiness/cost metrics
```

## Key architecture decisions (ADRs, Chapter 7.4)
- ADR-1: Plan in the cloud; cache resolved plan on-vehicle with safe fallback
  (over full on-vehicle planning). Rationale: CS-FR-021 + smaller in-vehicle
  safety surface.
- ADR-2: Single isolated BMS interface adapter as the only safety-relevant
  component. Rationale: contain higher-rigor review/verification.
- ADR-3: mTLS + IAM-scoped credentials for cloud-to-vehicle commands. Rationale:
  CS-SEC-005 and R155 cybersecurity scope.

## OTA / R156
Every delivered version is traceable to the requirement set it satisfies;
rollback is a first-class capability (see ota/ and operations/release-record.md).
