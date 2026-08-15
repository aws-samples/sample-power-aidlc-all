# Operational Evidence Map

> AI-DLC Operations artifact (Chapter 15.4). Shows how the standing SDV operational
> framework draws each pillar's evidence from the per-Bolt audit trail, so
> assurance becomes a query against the trail rather than an after-the-fact
> reconstruction. Each pillar reads the slice of the trail it needs.

```text
# Operational Evidence Map (aidlc-docs/operations/ops-evidence-map.md)
# How the standing framework draws on the per-Bolt audit trail.

Release pillar    -> release-record.md      (R156 version baseline per VIN)
Monitoring pillar -> monitoring-summary.md  (product vs. safety signals, KPIs)
Assurance pillar  -> audit.md               (intent -> requirement -> test -> field)
Security pillar   -> security-compliance.md (SECURITY rules; SBOM; CS-SEC-005)
Boundary          -> BMS control unchanged; HIL evidence human-reviewed
```

## Pillar-to-artifact mapping
| Framework pillar | Per-Bolt artifact | What it supplies |
|---|---|---|
| Release & OTA management | `release-record.md` | R156 version baseline per VIN, staged rollout, proven rollback |
| Fleet monitoring & observability | `monitoring-summary.md` | Product vs. safety signals, KPIs, anomaly detection |
| Compliance & assurance | `audit.md` | Intent -> requirement -> test -> field traceability |
| Security operations | `security-compliance.md` | SECURITY rule results, SBOM, CS-SEC-005 posture |
| Safety boundary (all pillars) | HIL evidence | BMS control unchanged; result human-reviewed |

A regulator's question, "show me that CS-SR-002 is honored on the version this VIN
runs," resolves to a link across these artifacts, not a reconstruction. The BMS
control code is unchanged and its hardware-in-the-loop evidence is human-reviewed,
sitting outside the generated trail.
