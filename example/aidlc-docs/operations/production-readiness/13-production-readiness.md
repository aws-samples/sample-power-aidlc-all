# Phase 13 — Production Readiness Validation (Example)

> **Group:** Operations · **Greenfield phase 12 / Brownfield phase 13**
> **Purpose:** Final checks before going live.

## 1. Go-live checklist

| Area | Item | Status |
|------|------|--------|
| Reliability | Multi-AZ RDS + automated backups enabled | ✅ |
| Reliability | Health checks + auto-scaling configured | ✅ |
| Security | Secrets in Secrets Manager, no secrets in env files | ✅ |
| Security | TLS enforced end-to-end | ✅ |
| Observability | Dashboards + alerts live (Phase 12) | ✅ |
| Ops | Runbook for on-call written | ✅ |
| Ops | Rollback procedure tested in dev | ✅ |
| Data | Migration dry-run on prod-like snapshot | ✅ |

## 2. Runbook (excerpt)

- **Symptom:** reminder queue backing up.
  **Action:** scale worker desired_count; check email provider status; inspect
  dead-letter queue.
- **Symptom:** login failures spike after deploy.
  **Action:** verify Redis reachability; toggle the auth feature flag off (R-1).

## 3. SLOs published

- Availability 99.9% / month.
- API p95 < 300ms.
- Error budget policy: freeze feature deploys if budget exhausted.

## 4. Launch plan

1. Enable Redis-session flag for 10% of traffic; monitor 24h.
2. Ramp to 100%; then enable reminders flag.
3. Announce GA once SLOs hold for 7 days.

## 5. Sign-off

Engineering, QA, and (example) product owner have approved. TaskFlow v2 is
production-ready.
