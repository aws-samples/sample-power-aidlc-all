# Monitoring Summary — charge-management-service v1.3.0 (first 30 days)

> AI-DLC Operations artifact (Chapter 10.2). Monitoring separates product signals
> from safety signals; AI flags anomalies across the fleet, humans judge severity.

```text
Readiness accuracy:   97.4% reached target SoC by departure   (goal >= 95%)
Cost savings:         median 18% vs. unscheduled charging
Anomaly:              0.3% of sessions saw early BMS inhibit in cold ambient
Action proposed:      refine pre-conditioning window  -> candidate next-Bolt intent
Safety:               no inhibit-handling regressions; all safe-idle on link loss
```

## How these metrics are produced (modeled by U6)
The `telemetry/` unit (`FleetAggregator`) computes these exact figures from
privacy-minimized session records:
- `readiness_accuracy_pct` — share of sessions ready by departure (goal >= 95%).
- `median_cost_savings_pct` — median savings vs. unscheduled charging.
- `cold_early_inhibit_rate_pct` — early BMS inhibit in cold ambient (< 0 C).
- `safe_idle_regressions` — must be 0; a safety signal, not a product metric.

`anomaly_detected()` returns true exactly when there is a cold-ambient
early-inhibit signal AND zero safety regressions — i.e., the inhibit worked as
designed, but the orchestration could be smarter in the cold.

## Loop-back (Chapter 10.4)
The cold-weather anomaly is not hot-fixed in production. It enters the next Bolt
as fresh intent (see ../inception/next-bolt-intent.md), inheriting the existing
safety boundary unchanged.
