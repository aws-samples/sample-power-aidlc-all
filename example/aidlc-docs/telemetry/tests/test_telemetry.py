"""Unit tests for telemetry feedback (U6). Trace to US-15, CS-FR-031, privacy."""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from telemetry_feedback import ChargeSessionRecord, FleetAggregator, minimize


def record(**kwargs):
    base = dict(
        session_id="s1",
        vehicle_id="VIN-REAL-123",
        reached_target=True,
        departure_met=True,
        cost_savings_pct=18.0,
        early_inhibit=False,
        ambient_c=15.0,
        safe_idle_regression=False,
        location="51.5074,-0.1278",
    )
    base.update(kwargs)
    return ChargeSessionRecord(**base)


class TestPrivacy(unittest.TestCase):
    def test_minimize_drops_location_and_pseudonymizes(self):
        m = minimize(record(), salt="fleet-salt")
        self.assertIsNone(m.location)
        self.assertNotEqual(m.vehicle_id, "VIN-REAL-123")
        self.assertTrue(m.vehicle_id.startswith("veh_"))

    def test_pseudonym_is_stable(self):
        a = minimize(record(), salt="fleet-salt")
        b = minimize(record(), salt="fleet-salt")
        self.assertEqual(a.vehicle_id, b.vehicle_id)


class TestAggregator(unittest.TestCase):
    def setUp(self):
        self.agg = FleetAggregator()

    def _add(self, **kwargs):
        self.agg.add(minimize(record(**kwargs), salt="s"))

    def test_rejects_unminimized_record(self):
        with self.assertRaises(ValueError):
            self.agg.add(record())  # still has location

    def test_readiness_and_savings(self):
        for _ in range(95):
            self._add(departure_met=True, cost_savings_pct=18.0)
        for _ in range(5):
            self._add(departure_met=False, cost_savings_pct=5.0)
        m = self.agg.metrics()
        self.assertEqual(m.sessions, 100)
        self.assertGreaterEqual(m.readiness_accuracy_pct, 95.0)
        self.assertGreater(m.median_cost_savings_pct, 0.0)

    def test_cold_ambient_early_inhibit_anomaly(self):
        for _ in range(99):
            self._add(ambient_c=10.0, early_inhibit=False)
        self._add(ambient_c=-8.0, early_inhibit=True)  # cold + early inhibit
        m = self.agg.metrics()
        self.assertGreater(m.cold_early_inhibit_rate_pct, 0.0)
        self.assertEqual(m.safe_idle_regressions, 0)
        # It's an anomaly (candidate next-Bolt intent), not a safety regression.
        self.assertTrue(self.agg.anomaly_detected())

    def test_safety_regression_blocks_anomaly_only_flag(self):
        self._add(ambient_c=-8.0, early_inhibit=True, safe_idle_regression=True)
        m = self.agg.metrics()
        self.assertEqual(m.safe_idle_regressions, 1)
        self.assertFalse(self.agg.anomaly_detected())


if __name__ == "__main__":
    unittest.main()
