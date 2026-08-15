// SPDX-License-Identifier: Apache-2.0
//
// Charge-management service application entry point (Step 6: deployment
// artifacts). On a real AUTOSAR Adaptive target this binary is an Adaptive
// Application started by the Execution Manager and bound via `ara::com`. Here it
// runs a short, deterministic simulation so the example is runnable end-to-end.
//
// NOTE: the SimulatedBms below is a DEMO stand-in only. In the vehicle, the real
// safety-relevant adapter (Unit U4, bms-interface-adapter) provides IBmsAdapter
// and is wrapped by the fail-safe BmsClient.

#include <cstdio>

#include "charge_management/bms_client.h"
#include "charge_management/charge_service_interface.h"
#include "charge_management/schedule_executor.h"
#include "charge_management/soc_tracker.h"
#include "charge_management/telemetry_publisher.h"

using namespace charge_management;

namespace {

// Demo-only simulated BMS: grants a 32 A envelope and never inhibits. The real
// U4 adapter reads the vehicle's BMS over the in-vehicle network.
class SimulatedBms final : public IBmsAdapter {
 public:
  BmsEnvelope ReadEnvelope() override {
    BmsEnvelope e;
    e.max_charge_current_a = 32.0;
    e.inhibit = false;
    e.valid = true;
    return e;
  }
  bool RequestCharge(double) override { return true; }
  void StopCharge() override {}
};

}  // namespace

int main() {
  SimulatedBms sim_bms;          // demo stand-in for the U4 adapter
  BmsClient bms(sim_bms);        // fail-safe boundary facade
  SocTracker soc(50, 60.0, 400.0);

  TelemetryPublisher telemetry([](const StatusEvent& ev) {
    std::printf("[telemetry] t=%lld state=%s soc=%d%% reason=\"%s\"\n",
                static_cast<long long>(ev.timestamp_epoch_s), to_string(ev.state),
                ev.current_soc_pct, ev.reason.c_str());
  });

  ScheduleExecutor exec(bms, soc, &telemetry);

  ChargePlan plan;
  plan.plan_id = "demo-plan";
  plan.target_soc_pct = 80;
  plan.departure_epoch_s = 100000;
  plan.precondition_window_min = 20;
  plan.issued_at_epoch_s = 1000;
  plan.source = PlanSource::App;
  exec.LoadPlan(plan);

  std::printf("Charge-management service (demo simulation)\n");

  // Simulate ticks past the latest safe start, charging the battery over time.
  for (std::int64_t now = 94000; now <= 99000; now += 1000) {
    exec.Tick(now);
    if (exec.state() == ChargeState::Charging) {
      soc.Update(soc.current_soc() + 6);  // crude per-step SoC gain for the demo
    }
    std::printf("tick t=%lld -> %s (soc=%d%%)\n", static_cast<long long>(now),
                to_string(exec.state()), soc.current_soc());
  }

  std::printf("final state: %s\n", to_string(exec.state()));
  return 0;
}
