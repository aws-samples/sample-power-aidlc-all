"""Unit tests for the tariff planner (U2). Trace to US-07, CS-FR-014, CS-NFR-009."""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from tariff_planner import PlanRequest, TariffWindow, compute_plan, minutes_needed
from tariff_planner.models import ChargeWindow


HOUR = 3600


def base_request(**kwargs):
    req = PlanRequest(
        vehicle_id="VIN123",
        current_soc_pct=50,
        target_soc_pct=80,
        departure_epoch_s=8 * HOUR,
        battery_capacity_kwh=60.0,
        charge_power_kw=11.0,
        precondition_window_min=20,
    )
    for k, v in kwargs.items():
        setattr(req, k, v)
    return req


def total_minutes(windows):
    return sum((w.end_epoch_s - w.start_epoch_s) // 60 for w in windows)


class TestMinutesNeeded(unittest.TestCase):
    def test_basic(self):
        req = base_request()
        # 30% of 60 kWh = 18 kWh at 11 kW ~= 98 minutes.
        self.assertGreaterEqual(minutes_needed(req), 95)
        self.assertLessEqual(minutes_needed(req), 100)

    def test_already_at_target(self):
        self.assertEqual(minutes_needed(base_request(current_soc_pct=80)), 0)


class TestComputePlan(unittest.TestCase):
    def test_prefers_cheapest_windows(self):
        req = base_request()
        tariffs = [
            TariffWindow(0 * HOUR, 3 * HOUR, price_per_kwh=0.10),  # cheap, off-peak
            TariffWindow(3 * HOUR, 7 * HOUR, price_per_kwh=0.40),  # expensive
        ]
        plan = compute_plan(req, tariffs, now_epoch_s=0, plan_id="p1")
        self.assertFalse(plan.fallback)
        # All charging should fit inside the cheap window.
        for w in plan.charge_windows:
            self.assertLessEqual(w.end_epoch_s, 3 * HOUR)
        self.assertGreaterEqual(total_minutes(plan.charge_windows), plan.estimated_minutes - 1)

    def test_fallback_when_no_tariffs(self):
        req = base_request()
        plan = compute_plan(req, tariffs=None, now_epoch_s=0, plan_id="p2")
        self.assertTrue(plan.fallback)
        self.assertEqual(len(plan.charge_windows), 1)
        deadline = req.departure_epoch_s - req.precondition_window_min * 60
        self.assertEqual(plan.charge_windows[0].end_epoch_s, deadline)

    def test_meets_deadline_when_cheap_time_scarce(self):
        req = base_request()
        # Only 30 minutes of cheap window, far less than needed -> greedy fill.
        tariffs = [TariffWindow(0, 30 * 60, price_per_kwh=0.10)]
        plan = compute_plan(req, tariffs, now_epoch_s=0, plan_id="p3")
        self.assertTrue(plan.fallback)
        self.assertGreaterEqual(total_minutes(plan.charge_windows), plan.estimated_minutes - 1)

    def test_no_charging_when_at_target(self):
        req = base_request(current_soc_pct=80)
        plan = compute_plan(req, tariffs=None, now_epoch_s=0, plan_id="p4")
        self.assertEqual(plan.charge_windows, [])
        self.assertEqual(plan.estimated_minutes, 0)


if __name__ == "__main__":
    unittest.main()
