"""U6 - Status & telemetry feedback (vehicle -> cloud).

Publishes charge-session telemetry from the vehicle and aggregates it in the
fleet data pipeline to produce the monitoring metrics of Chapter 9.2 (readiness
accuracy, cost savings, anomaly detection). QM-rated; privacy-sensitive, so the
vehicle side minimizes data before it leaves the car (Chapter 12).

Traces to: US-15 acceptance criteria, CS-FR-031.
"""

from .events import ChargeSessionRecord
from .privacy import minimize
from .ingest import FleetAggregator, FleetMetrics

__all__ = [
    "ChargeSessionRecord",
    "minimize",
    "FleetAggregator",
    "FleetMetrics",
]
