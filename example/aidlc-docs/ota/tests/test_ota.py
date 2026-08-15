"""Unit tests for OTA packaging and staged rollout (U5).

Trace to: UNECE R156 baseline, Chapter 9.1 (human-gated staged rollout, rollback).
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from ota_delivery import (
    RolloutController,
    RolloutStage,
    build_package,
    verify_package,
)
from ota_delivery.rollout import KpiSample

KEY = b"ota-signing-key"
BASELINE = ["CS-FR-014", "CS-FR-021", "CS-SR-002", "CS-SR-003", "CS-SEC-005"]


def make_package(version="1.3.0", previous="1.2.4"):
    return build_package(
        component="charge-management-service",
        version=version,
        artifact_bytes=b"<binary artifact bytes>",
        requirement_baseline=BASELINE,
        signing_key=KEY,
        previous_version=previous,
    )


class TestPackaging(unittest.TestCase):
    def test_package_carries_r156_baseline(self):
        pkg = make_package()
        self.assertEqual(sorted(pkg.requirement_baseline), sorted(BASELINE))
        self.assertTrue(pkg.signature)

    def test_signature_verifies(self):
        pkg = make_package()
        self.assertTrue(verify_package(pkg, b"<binary artifact bytes>", KEY))

    def test_tampered_artifact_fails(self):
        pkg = make_package()
        self.assertFalse(verify_package(pkg, b"<tampered>", KEY))


class TestRollout(unittest.TestCase):
    def test_requires_signoff_before_start(self):
        rc = RolloutController(make_package(), fleet_size=1000)
        with self.assertRaises(RuntimeError):
            rc.start()

    def test_requires_rollback_path(self):
        with self.assertRaises(ValueError):
            RolloutController(make_package(previous=""), fleet_size=1000)

    def test_healthy_progression(self):
        rc = RolloutController(make_package(), fleet_size=1000)
        rc.sign_off("Quality Steward")
        self.assertEqual(rc.start(), RolloutStage.CANARY)
        good = KpiSample(readiness_accuracy_pct=97.4, safe_idle_regressions=0)
        self.assertEqual(rc.advance(good), RolloutStage.PHASED)
        self.assertEqual(rc.advance(good), RolloutStage.FLEET)
        self.assertEqual(rc.active_version, "1.3.0")

    def test_rollback_on_kpi_breach(self):
        rc = RolloutController(make_package(), fleet_size=1000)
        rc.sign_off("Quality Steward")
        rc.start()
        bad = KpiSample(readiness_accuracy_pct=88.0, safe_idle_regressions=0)
        self.assertEqual(rc.advance(bad), RolloutStage.ROLLED_BACK)
        self.assertEqual(rc.active_version, "1.2.4")

    def test_rollback_on_safety_regression(self):
        rc = RolloutController(make_package(), fleet_size=1000)
        rc.sign_off("Quality Steward")
        rc.start()
        unsafe = KpiSample(readiness_accuracy_pct=99.0, safe_idle_regressions=1)
        self.assertEqual(rc.advance(unsafe), RolloutStage.ROLLED_BACK)

    def test_stage_vehicle_counts(self):
        rc = RolloutController(make_package(), fleet_size=1000)
        self.assertEqual(rc.vehicles_in_stage(RolloutStage.CANARY), 10)
        self.assertEqual(rc.vehicles_in_stage(RolloutStage.PHASED), 250)
        self.assertEqual(rc.vehicles_in_stage(RolloutStage.FLEET), 1000)


if __name__ == "__main__":
    unittest.main()
