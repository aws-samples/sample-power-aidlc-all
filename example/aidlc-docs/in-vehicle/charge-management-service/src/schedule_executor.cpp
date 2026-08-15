// SPDX-License-Identifier: Apache-2.0
#include "charge_management/schedule_executor.h"

namespace charge_management {

namespace {
int Rank(PlanSource s) {
  switch (s) {
    case PlanSource::App: return 2;
    case PlanSource::Recurring: return 1;
    case PlanSource::DemandResponse: return 0;
  }
  return -1;
}
}  // namespace

ScheduleExecutor::ScheduleExecutor(IBmsAdapter& bms, SocTracker& soc,
                                   TelemetryPublisher* telemetry)
    : bms_(bms), soc_(soc), telemetry_(telemetry) {}

bool ScheduleExecutor::HigherOrEqualPrecedence(PlanSource incoming,
                                               PlanSource current) {
  return Rank(incoming) >= Rank(current);
}

void ScheduleExecutor::LoadPlan(const ChargePlan& plan) {
  // CS-FR-030 / BR-04: resolve conflicts by source precedence, then recency.
  if (plan_.has_value()) {
    const bool higher = Rank(plan.source) > Rank(plan_->source);
    const bool same_but_newer =
        Rank(plan.source) == Rank(plan_->source) &&
        plan.issued_at_epoch_s >= plan_->issued_at_epoch_s;
    if (!higher && !same_but_newer) {
      return;  // keep the existing, higher-precedence/newer plan
    }
  }
  plan_ = plan;
  session_id_ = plan.plan_id + "-sess";
  state_ = ChargeState::Idle;
  reason_ = "plan loaded";
}

std::int64_t ScheduleExecutor::LatestStartTime(double charge_current_a) const {
  if (!plan_.has_value()) {
    return 0;
  }
  const int est_min =
      soc_.EstimateMinutesToTarget(plan_->target_soc_pct, charge_current_a);
  const std::int64_t lead_s =
      static_cast<std::int64_t>(est_min + plan_->precondition_window_min) * 60;
  return plan_->departure_epoch_s - lead_s;
}

bool ScheduleExecutor::ShouldChargeNow(std::int64_t now_epoch_s,
                                       double envelope_current_a) const {
  // Deadline pressure: if we are at/after the latest safe start, charge now even
  // if it is not the cheapest window (BR-04: readiness/limits beat cost).
  if (now_epoch_s >= LatestStartTime(envelope_current_a)) {
    return true;
  }
  // Otherwise, only charge inside a cheap/off-peak window (cost optimization).
  for (const auto& w : plan_->charge_windows) {
    if (w.contains(now_epoch_s)) {
      return true;
    }
  }
  return false;
}

void ScheduleExecutor::Transition(ChargeState next, const std::string& reason,
                                  std::int64_t now_epoch_s) {
  const bool changed = (next != state_) || (reason != reason_);
  state_ = next;
  reason_ = reason;
  if (changed && telemetry_ != nullptr) {
    StatusEvent ev;
    ev.session_id = session_id_;
    ev.state = state_;
    ev.current_soc_pct = soc_.current_soc();
    ev.reason = reason_;
    ev.timestamp_epoch_s = now_epoch_s;
    telemetry_->Publish(ev);
  }
}

ChargeState ScheduleExecutor::Tick(std::int64_t now_epoch_s) {
  const BmsEnvelope env = bms_.ReadEnvelope();

  // BR-03 / CS-SR-003: loss of the BMS interface -> safe idle (hard).
  if (!env.valid) {
    bms_.StopCharge();
    Transition(ChargeState::SafeIdle, "BMS interface lost", now_epoch_s);
    return state_;
  }

  // BR-02 / CS-SR-002: a BMS inhibit stops charge initiation immediately.
  if (env.inhibit) {
    bms_.StopCharge();
    Transition(ChargeState::SafeIdle, "BMS inhibit honored", now_epoch_s);
    return state_;
  }

  // BR-05 / CS-FR-021: with no connectivity the cached plan still executes; the
  // tick has no cloud dependency. If there is no cached plan at all, idle.
  if (!plan_.has_value()) {
    bms_.StopCharge();
    Transition(ChargeState::Idle, "no plan", now_epoch_s);
    return state_;
  }

  // CS-FR-014: done once the target SoC is reached.
  if (soc_.ReachedTarget(plan_->target_soc_pct)) {
    bms_.StopCharge();
    Transition(ChargeState::Complete, "target SoC reached", now_epoch_s);
    return state_;
  }

  if (ShouldChargeNow(now_epoch_s, env.max_charge_current_a)) {
    // BR-01: request only within the permitted envelope (BmsClient clamps too).
    const bool granted = bms_.RequestCharge(env.max_charge_current_a);
    if (granted) {
      Transition(ChargeState::Charging, "charging within envelope", now_epoch_s);
    } else {
      bms_.StopCharge();
      Transition(ChargeState::SafeIdle, "charge not granted by BMS",
                 now_epoch_s);
    }
  } else {
    bms_.StopCharge();
    Transition(ChargeState::Idle, "waiting for charge window", now_epoch_s);
  }
  return state_;
}

}  // namespace charge_management
