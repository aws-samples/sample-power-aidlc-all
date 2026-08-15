// SPDX-License-Identifier: Apache-2.0
//
// Unit tests for SoC tracking / charge-time estimation (AI-generated, QM).

#include <cstdio>

#include "charge_management/soc_tracker.h"
#include "test_support.h"

using namespace charge_management;
using test_support::check;

namespace {

void TestClampsSoc() {
  SocTracker soc(150, 60.0, 400.0);
  check(soc.current_soc() == 100, "initial SoC clamped to 100");
  soc.Update(-5);
  check(soc.current_soc() == 0, "updated SoC clamped to 0");
}

void TestReachedTarget() {
  SocTracker soc(80, 60.0, 400.0);
  check(soc.ReachedTarget(80), "reached when equal to target");
  check(!soc.ReachedTarget(90), "not reached when below target");
}

void TestEstimateMinutes() {
  SocTracker soc(50, 60.0, 400.0);
  // 30% of 60 kWh = 18 kWh; at 12.8 kW (400V * 32A) ~= 84 minutes.
  const int minutes = soc.EstimateMinutesToTarget(80, 32.0);
  check(minutes >= 80 && minutes <= 88, "estimate ~84 min for 50->80% at 32A");
  check(soc.EstimateMinutesToTarget(80, 0.0) > 100000, "no progress at 0A returns sentinel");
  check(soc.EstimateMinutesToTarget(40, 32.0) == 0, "already above target -> 0 minutes");
}

}  // namespace

int main() {
  RUN_TEST(TestClampsSoc);
  RUN_TEST(TestReachedTarget);
  RUN_TEST(TestEstimateMinutes);

  const int failures = test_support::failures();
  std::printf("\n%s (%d failure%s)\n", failures == 0 ? "ALL TESTS PASSED" : "TESTS FAILED",
              failures, failures == 1 ? "" : "s");
  return failures == 0 ? 0 : 1;
}
