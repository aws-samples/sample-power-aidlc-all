# U6 — telemetry-feedback (vehicle -> cloud)

Publishes charge-session telemetry from the vehicle (privacy-minimized at the
boundary) and aggregates it in the fleet pipeline to produce the monitoring
metrics of Chapter 10.2. QM-rated; privacy-sensitive.

Traces to: US-15, CS-FR-031. Feeds operations/monitoring-summary.md.

## Run tests
```
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

## Key ideas
- `privacy.minimize` runs on the vehicle side: it drops precise location and
  replaces the raw vehicle id with a salted pseudonym before data leaves the car.
- `ingest.FleetAggregator` refuses un-minimized records, then computes readiness
  accuracy, median cost savings, and the cold-ambient early-inhibit anomaly — the
  signal that becomes the next Bolt's intent (the inhibit worked as designed, so
  it is not a safety regression).
