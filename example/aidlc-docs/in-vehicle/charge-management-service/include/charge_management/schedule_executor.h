// SPDX-License-Identifier: Apache-2.0
//
// Schedule executor: the QM state machine that runs the cached plan within the
// BMS-permitted envelope (Unit U3, AI-generated, CI-verified).
//
// Implements the behavior in business-logic-model.md and the business rules:
//   BR-01 charge only within the BMS envelope
//   BR-02 a BMS inhibit stops charge initiation immediately (via BmsClient)
//   BR-03 loss of the BMS interface drives a safe idle state
//   BR-04 safety/charge limits always win over cost optimization
//   BR-05 with no connectivity, the most recent cached plan executes locally
//
// Traces to: CS-FR-014, CS-FR-021, CS-FR-030, CS-SR-002, CS-SR-003.

#ifndef CHARGE_MANAGEMENT_SCHEDULE_EXECUTOR_H
#define CHARGE_MANAGEMENT_SCHEDULE_EXECUTOR_H

#include <cstdint>
#include <optional>
#include <string>

#include "charge_management/domain_types.h"
#include "charge_management/i_bms_adapter.h"
#include "charge_management/soc_tracker.h"
#include "charge_management/telemetry_publisher.h"

namespace charge_management {

class ScheduleExecutor {
 public:
  ScheduleExecutor(IBmsAdapter& bms, SocTracker& soc,
                   TelemetryPublisher* telemetry = nullptr);

  // Cache a resolved plan locally. Higher-precedence sources (App over Recurring
  // over DemandResponse) replace lower ones; equal/higher precedence and newer
  // issuance wins (CS-FR-030, BR-04).
  void LoadPlan(const ChargePlan& plan);

  bool has_plan() const { return plan_.has_value(); }

  // Drive the state machine one step at the given wall-clock time. Returns the
  // resulting state. Has NO cloud dependency, so it runs offline (BR-05).
  ChargeState Tick(std::int64_t now_epoch_s);

  ChargeState state() const { return state_; }
  const std::string& reason() const { return reason_; }

  // Latest moment charging must start to be ready by departure, given current
  // SoC and the granted current. Exposed for tests and diagnostics.
  std::int64_t LatestStartTime(double charge_current_a) const;

 private:
  void Transition(ChargeState next, const std::string& reason,
                  std::int64_t now_epoch_s);
  bool ShouldChargeNow(std::int64_t now_epoch_s, double envelope_current_a) const;
  static bool HigherOrEqualPrecedence(PlanSource incoming, PlanSource current);

  IBmsAdapter& bms_;
  SocTracker& soc_;
  TelemetryPublisher* telemetry_;

  std::optional<ChargePlan> plan_;
  ChargeState state_ = ChargeState::Idle;
  std::string reason_ = "no plan";
  std::string session_id_;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_SCHEDULE_EXECUTOR_H
