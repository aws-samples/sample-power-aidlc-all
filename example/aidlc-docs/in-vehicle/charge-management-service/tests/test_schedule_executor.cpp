// SPDX-License-Identifier: Apache-2.0
//
// Unit tests for the schedule executor (Step 2 of the code-generation plan).
// Tests trace directly to requirements (Chapter 7.4):
//   CS-FR-014  reach target SoC by departure
//   CS-FR-021  execute cached plan with no connectivity
//   CS-FR-030  plan-conflict precedence
//   CS-SR-002  never command charging the BMS has inhibited  [safety, engineer-owned]
//   CS-SR-003  safe idle on BMS interface loss               [safety, engineer-owned]

#include <cstdio>

#include "charge_management/bms_client.h"
#include "charge_management/schedule_executor.h"
#include "charge_management/soc_tracker.h"
#include "charge_management/telemetry_publisher.h"
#include "test_support.h"

using namespace charge_management;
using test_support::check;

namespace {

// Shared scenario constants (60 kWh pack, 400 V nominal).
constexpr double kCapacityKwh = 60.0;
constexpr double kPackVoltage = 400.0;
constexpr std::int64_t kDeparture = 100000;  // arbitrary epoch seconds

ChargePlan MakePlan(PlanSource source = PlanSource::App,
                    std::int64_t issued_at = 1000) {
  ChargePlan p;
  p.plan_id = "plan-001";
  p.target_soc_pct = 80;
  p.departure_epoch_s = kDeparture;
  p.precondition_window_min = 20;
  p.issued_at_epoch_s = issued_at;
  p.source = source;
  return p;
}

// CS-FR-014: charges when at/after the latest safe start, then completes.
void TestReachesTargetByDeparture() {
  FakeBmsAdapter fake;
  BmsClient bms(fake);
  SocTracker soc(50, kCapacityKwh, kPackVoltage);
  TelemetryPublisher tele;
  ScheduleExecutor exec(bms, soc, &tele);

  exec.LoadPlan(MakePlan());

  // At 95000 we are past the latest safe start, so charging must begin.
  exec.Tick(95000);
  check(exec.state() == ChargeState::Charging, "CS-FR-014 begins charging before departure");
  check(fake.last_requested_current == 32.0, "CS-FR-014 requests within envelope (32A)");

  // Battery reaches target -> session completes.
  soc.Update(80);
  exec.Tick(98000);
  check(exec.state() == ChargeState::Complete, "CS-FR-014 completes at target SoC");
  check(tele.published_count() >= 2, "status events published to telemetry (CS-FR-031)");
}

// CS-FR-021 / BR-05: the tick uses only the cached plan; no cloud dependency.
void TestOfflineCachedPlanExecutes() {
  FakeBmsAdapter fake;
  BmsClient bms(fake);
  SocTracker soc(40, kCapacityKwh, kPackVoltage);
  ScheduleExecutor exec(bms, soc);

  ChargePlan p = MakePlan();
  p.charge_windows.push_back(TimeWindow{90000, 92000});  // cheap off-peak window
  exec.LoadPlan(p);

  // Inside a cheap window and before the deadline: charge for cost reasons,
  // with no network call involved anywhere in Tick.
  exec.Tick(91000);
  check(exec.state() == ChargeState::Charging, "CS-FR-021 cached plan charges offline in window");
}

// Outside any window and before the deadline -> wait (cost optimization).
void TestWaitsOutsideWindow() {
  FakeBmsAdapter fake;
  BmsClient bms(fake);
  SocTracker soc(50, kCapacityKwh, kPackVoltage);
  ScheduleExecutor exec(bms, soc);

  exec.LoadPlan(MakePlan());  // no windows
  exec.Tick(90000);           // well before latest safe start (~93760)
  check(exec.state() == ChargeState::Idle, "waits outside window before deadline");
  check(fake.last_requested_current == -1.0, "no charge requested while waiting");
}

// CS-SR-002 [SAFETY]: never command charging that the BMS has inhibited.
void TestNeverChargesWhenInhibited() {
  FakeBmsAdapter fake;
  fake.envelope.inhibit = true;  // BMS asserts an authoritative inhibit
  BmsClient bms(fake);
  SocTracker soc(50, kCapacityKwh, kPackVoltage);
  ScheduleExecutor exec(bms, soc);

  exec.LoadPlan(MakePlan());
  exec.Tick(95000);  // past the deadline: would charge if not inhibited

  check(exec.state() == ChargeState::SafeIdle, "CS-SR-002 inhibit forces SAFE_IDLE");
  check(fake.request_calls == 0, "CS-SR-002 charge is never requested under inhibit");
  check(fake.stop_calls >= 1, "CS-SR-002 stop is commanded under inhibit");
  check(bms.inhibit_latched(), "CS-SR-002 inhibit latched at the boundary");
}

// CS-SR-003 [SAFETY]: loss of the BMS interface -> safe idle.
void TestSafeIdleOnInterfaceLoss() {
  FakeBmsAdapter fake;
  fake.envelope.valid = false;  // interface lost
  BmsClient bms(fake);
  SocTracker soc(50, kCapacityKwh, kPackVoltage);
  ScheduleExecutor exec(bms, soc);

  exec.LoadPlan(MakePlan());
  exec.Tick(95000);

  check(exec.state() == ChargeState::SafeIdle, "CS-SR-003 interface loss forces SAFE_IDLE");
  check(fake.request_calls == 0, "CS-SR-003 no charge requested with invalid interface");
}

// CS-FR-030 / BR-04: plan-conflict precedence (App > Recurring > DemandResponse).
void TestPlanPrecedence() {
  FakeBmsAdapter fake;
  BmsClient bms(fake);
  SocTracker soc(50, kCapacityKwh, kPackVoltage);
  ScheduleExecutor exec(bms, soc);

  exec.LoadPlan(MakePlan(PlanSource::Recurring, 1000));
  exec.LoadPlan(MakePlan(PlanSource::App, 500));  // lower issue time, higher source
  check(exec.has_plan(), "CS-FR-030 a plan is held");

  // A demand-response plan must not displace the higher-precedence App plan.
  ChargePlan dr = MakePlan(PlanSource::DemandResponse, 9999);
  dr.target_soc_pct = 100;
  exec.LoadPlan(dr);

  // The retained App plan targets 80%, so at 80% it completes (not 100%).
  soc.Update(80);
  exec.Tick(95000);
  check(exec.state() == ChargeState::Complete,
        "CS-FR-030 higher-precedence App plan (target 80) is retained");
}

}  // namespace

int main() {
  RUN_TEST(TestReachesTargetByDeparture);
  RUN_TEST(TestOfflineCachedPlanExecutes);
  RUN_TEST(TestWaitsOutsideWindow);
  RUN_TEST(TestNeverChargesWhenInhibited);
  RUN_TEST(TestSafeIdleOnInterfaceLoss);
  RUN_TEST(TestPlanPrecedence);

  const int failures = test_support::failures();
  std::printf("\n%s (%d failure%s)\n", failures == 0 ? "ALL TESTS PASSED" : "TESTS FAILED",
              failures, failures == 1 ? "" : "s");
  return failures == 0 ? 0 : 1;
}
