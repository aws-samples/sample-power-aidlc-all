"""Unit tests for the schedule service (U1).

Trace to US-03, US-15, CS-SEC-005 (auth + integrity), CS-FR-030.
These are the kind of tests the AI-DLC test step generates for cloud units
(Chapter 7.4); CI verification is fully automated for this tier.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "tariff-planner"))

from schedule_api.auth import AuthError, TokenAuthenticator
from schedule_api.service import ScheduleService
from tariff_planner import TariffWindow

HOUR = 3600


def make_service():
    auth = TokenAuthenticator(
        tokens={"good-token": "mobile-app"},
        signing_key=b"unit-test-key",
    )
    tariffs = [
        TariffWindow(0, 6 * HOUR, price_per_kwh=0.10),
        TariffWindow(6 * HOUR, 22 * HOUR, price_per_kwh=0.35),
    ]
    # Fixed clock so plan times are deterministic.
    return ScheduleService(auth, tariffs=tariffs, clock=lambda: 0), auth


VALID_BODY = {
    "vehicle_id": "VIN123",
    "current_soc_pct": 50,
    "target_soc_pct": 80,
    "departure_epoch_s": 8 * HOUR,
}


class TestAuth(unittest.TestCase):
    def test_rejects_missing_token(self):
        svc, _ = make_service()
        with self.assertRaises(AuthError):
            svc.set_schedule("", VALID_BODY)

    def test_rejects_invalid_token(self):
        svc, _ = make_service()
        with self.assertRaises(AuthError):
            svc.set_schedule("Bearer nope", VALID_BODY)

    def test_accepts_valid_token(self):
        svc, _ = make_service()
        plan = svc.set_schedule("Bearer good-token", VALID_BODY)
        self.assertEqual(plan["vehicle_id"], "VIN123")
        self.assertIn("charge_windows", plan)


class TestCommandIntegrity(unittest.TestCase):
    def test_signature_present_and_verifies(self):
        svc, auth = make_service()
        plan = svc.set_schedule("Bearer good-token", VALID_BODY)
        signature = plan.pop("signature")
        plan.pop("issued_by")
        auth.verify_command(plan, signature)  # raises if invalid

    def test_tampered_command_fails(self):
        svc, auth = make_service()
        plan = svc.set_schedule("Bearer good-token", VALID_BODY)
        signature = plan.pop("signature")
        plan.pop("issued_by")
        plan["target_soc_pct"] = 100  # tamper
        with self.assertRaises(AuthError):
            auth.verify_command(plan, signature)


class TestScheduleFlow(unittest.TestCase):
    def test_vehicle_can_pull_plan(self):
        svc, _ = make_service()
        svc.set_schedule("Bearer good-token", VALID_BODY)
        plan = svc.get_plan("Bearer good-token", "VIN123")
        self.assertEqual(plan["target_soc_pct"], 80)

    def test_status_roundtrip(self):
        svc, _ = make_service()
        svc.set_schedule("Bearer good-token", VALID_BODY)
        svc.report_status("Bearer good-token", {
            "vehicle_id": "VIN123", "state": "CHARGING",
            "reason": "charging within envelope", "current_soc_pct": 62,
        })
        status = svc.get_status("Bearer good-token", "VIN123")
        self.assertEqual(status["state"], "CHARGING")
        self.assertEqual(status["current_soc_pct"], 62)

    def test_invalid_target_rejected(self):
        svc, _ = make_service()
        bad = dict(VALID_BODY, target_soc_pct=150)
        with self.assertRaises(ValueError):
            svc.set_schedule("Bearer good-token", bad)


if __name__ == "__main__":
    unittest.main()
