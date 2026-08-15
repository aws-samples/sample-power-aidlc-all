# Infrastructure Design — cloud-schedule-api

> AI-DLC Construction artifact (Chapter 7.3). Logical components mapped to real
> services, provisioned as infrastructure as code so the design is reviewable and
> reproducible.

```text
Compute:    container service (REST API), autoscaled
Datastore:  managed DB for schedules; object store for OTA packages
Messaging:  MQTT broker for vehicle telemetry -> stream -> fleet data pipeline
Security:   mTLS for cloud-to-vehicle commands; IAM-scoped credentials (CS-SEC-005)
Delivery:   OTA service — signed packages, staged rollout, rollback (R156)
IaC:        Terraform modules; CI validates the plan before apply
```

## Security note (Security Baseline extension — enabled)
The schedule API is an internet-facing, network-exposed endpoint. Authentication
and authorization are **design requirements** (CS-SEC-005), not later hardening:
an unauthenticated path that can influence vehicle charging is a cybersecurity
exposure under UNECE R155.

- All endpoints require authenticated callers (token / mTLS).
- Cloud-to-vehicle schedule commands are integrity-protected and signed.
- Credentials are IAM-scoped to least privilege.

## Three backends
1. **Service backend** — schedule API + tariff-optimization planner behind an
   authenticated API. Strong candidate for end-to-end AI-DLC generation.
2. **OTA backend** — packaging, signing, staged rollout of the in-vehicle
   component; R156 baseline forward; rollback first-class.
3. **Data pipeline** — telemetry over MQTT into a fleet pipeline for
   readiness-accuracy and cost-savings metrics; privacy-minimized (location/usage).
