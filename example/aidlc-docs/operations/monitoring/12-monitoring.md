# Phase 12 — Monitoring and Observability Setup (Example)

> **Group:** Operations · **Greenfield phase 11 / Brownfield phase 12**
> **Purpose:** Set up logging, metrics, traces, dashboards, and alerts.

## 1. The three pillars

| Pillar | Tooling (example) | What we capture |
|--------|-------------------|-----------------|
| Logs | CloudWatch Logs (structured JSON) | Request logs, worker runs, errors |
| Metrics | CloudWatch / Prometheus | Latency, error rate, queue depth |
| Traces | AWS X-Ray / OpenTelemetry | Request → DB/Redis spans |

## 2. Key metrics (SLIs)

- API p95 latency (target < 300ms).
- 5xx error rate (target < 0.5%).
- Reminder queue depth and job success rate.
- DB connection pool utilization.

## 3. Dashboards

- **Service health:** latency, error rate, request volume per endpoint.
- **Worker:** jobs processed, failures, retry count, oldest queued job age.
- **Infra:** ECS CPU/memory, RDS connections, Redis memory.

## 4. Alerts

| Alert | Condition | Route |
|-------|-----------|-------|
| High error rate | 5xx > 2% for 5 min | PagerDuty (on-call) |
| Latency SLO burn | p95 > 1s for 10 min | Slack #alerts |
| Queue backed up | depth > 1000 for 15 min | PagerDuty |
| DB near max conns | > 90% for 5 min | Slack #alerts |

## 5. Correlation

A `requestId` is logged and propagated as a trace header so logs, metrics, and
traces can be joined for a single request.
