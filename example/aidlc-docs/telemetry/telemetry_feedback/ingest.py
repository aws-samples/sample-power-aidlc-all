"""Fleet aggregation and monitoring metrics (U6, cloud side).

Produces the numbers in monitoring-summary.md (Chapter 9.2): readiness accuracy,
median cost savings, and the cold-ambient early-inhibit anomaly. AI is useful for
anomaly detection across the fleet; humans judge severity (here we just compute
and flag — the judgment is the next-Bolt intent decision).
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass
from typing import List

from .events import ChargeSessionRecord


@dataclass
class FleetMetrics:
    sessions: int
    readiness_accuracy_pct: float
    median_cost_savings_pct: float
    cold_early_inhibit_rate_pct: float
    safe_idle_regressions: int

    def to_dict(self) -> dict:
        return {
            "sessions": self.sessions,
            "readiness_accuracy_pct": round(self.readiness_accuracy_pct, 1),
            "median_cost_savings_pct": round(self.median_cost_savings_pct, 1),
            "cold_early_inhibit_rate_pct": round(self.cold_early_inhibit_rate_pct, 1),
            "safe_idle_regressions": self.safe_idle_regressions,
        }


class FleetAggregator:
    COLD_THRESHOLD_C = 0.0  # "below 0 C" cold-ambient definition (Chapter 9.4)

    def __init__(self):
        self._records: List[ChargeSessionRecord] = []

    def add(self, record: ChargeSessionRecord) -> None:
        # Defensive: reject records that still carry raw location (not minimized).
        if record.location is not None:
            raise ValueError("record was not privacy-minimized before ingest")
        self._records.append(record)

    def metrics(self) -> FleetMetrics:
        n = len(self._records)
        if n == 0:
            return FleetMetrics(0, 0.0, 0.0, 0.0, 0)

        ready = sum(1 for r in self._records if r.departure_met)
        savings = [r.cost_savings_pct for r in self._records]
        cold = [r for r in self._records if r.ambient_c < self.COLD_THRESHOLD_C]
        cold_early = sum(1 for r in cold if r.early_inhibit)
        regressions = sum(1 for r in self._records if r.safe_idle_regression)

        cold_rate = (100.0 * cold_early / n) if n else 0.0

        return FleetMetrics(
            sessions=n,
            readiness_accuracy_pct=100.0 * ready / n,
            median_cost_savings_pct=statistics.median(savings) if savings else 0.0,
            cold_early_inhibit_rate_pct=cold_rate,
            safe_idle_regressions=regressions,
        )

    def anomaly_detected(self) -> bool:
        """Flag the cold-ambient early-inhibit anomaly as a candidate next-Bolt
        intent. This is a signal, not a defect: the inhibit worked as designed."""
        m = self.metrics()
        return m.cold_early_inhibit_rate_pct > 0.0 and m.safe_idle_regressions == 0
