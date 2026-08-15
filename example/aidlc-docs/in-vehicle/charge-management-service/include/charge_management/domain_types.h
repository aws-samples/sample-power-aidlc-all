// SPDX-License-Identifier: Apache-2.0
//
// Domain types for the in-vehicle charge-management service (Unit U3).
// Generated as QM code in the AI-DLC code-generation step (Chapter 7).
// Mirrors aidlc-docs/.../functional-design/domain-entities.md.
//
// Traces to: CS-FR-014, CS-FR-021, CS-FR-030, CS-FR-031, CS-SR-002, CS-SR-003.

#ifndef CHARGE_MANAGEMENT_DOMAIN_TYPES_H
#define CHARGE_MANAGEMENT_DOMAIN_TYPES_H

#include <cstdint>
#include <string>
#include <vector>

namespace charge_management {

// Charge-session state model (see business-logic-model.md).
enum class ChargeState {
  Idle,        // no active plan, or nothing due yet
  Requesting,  // plan due; asking the BMS for a charge envelope
  Charging,    // charging within the BMS-permitted envelope
  Complete,    // target SoC reached
  SafeIdle,    // BMS inhibit or interface loss forced a safe stop (BR-02/BR-03)
  Fault        // unrecoverable error
};

// Plan precedence source. Safety/charge limits always win over cost (BR-04),
// and where plans conflict, this ordering documents precedence (CS-FR-030).
enum class PlanSource {
  App,            // driver-set, highest user precedence
  Recurring,      // recurring schedule
  DemandResponse  // utility demand-response signal
};

struct TimeWindow {
  std::int64_t start_epoch_s = 0;
  std::int64_t end_epoch_s = 0;

  bool contains(std::int64_t t) const {
    return t >= start_epoch_s && t < end_epoch_s;
  }
};

// The resolved plan issued by the cloud planner (U2) and cached on-vehicle so it
// can execute with no connectivity (BR-05 / CS-FR-021).
struct ChargePlan {
  std::string plan_id;
  int target_soc_pct = 80;
  std::int64_t departure_epoch_s = 0;
  int precondition_window_min = 20;
  std::vector<TimeWindow> charge_windows;
  std::int64_t issued_at_epoch_s = 0;
  PlanSource source = PlanSource::App;
};

// Read-only view owned by the BMS, surfaced through the adapter (U4).
// `inhibit` is authoritative and non-overridable; `valid` is false when the
// BMS interface is lost.
struct BmsEnvelope {
  double max_charge_current_a = 0.0;
  bool inhibit = true;   // fail-safe default: assume inhibited until proven otherwise
  bool valid = false;    // fail-safe default: assume interface invalid
};

struct StatusEvent {
  std::string session_id;
  ChargeState state = ChargeState::Idle;
  int current_soc_pct = 0;
  std::string reason;
  std::int64_t timestamp_epoch_s = 0;
};

const char* to_string(ChargeState s);
const char* to_string(PlanSource s);

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_DOMAIN_TYPES_H
