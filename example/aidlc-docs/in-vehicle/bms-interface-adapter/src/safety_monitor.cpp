// SPDX-License-Identifier: Apache-2.0
// UNIT U4 — SAFETY-RELEVANT, HUMAN-ENGINEERED
#include "bms_adapter/safety_monitor.h"

namespace bms_adapter {

bool SafetyMonitor::Evaluate(const BmsSample& sample, std::int64_t now_ms) {
  // Rule 1 (CS-SR-002): an asserted inhibit latches unsafe immediately.
  if (sample.inhibit_asserted) {
    latched_unsafe_ = true;
    safe_to_charge_ = false;
    return safe_to_charge_;
  }

  // Rule 2 (CS-SR-003): a failed read means the interface is not trustworthy.
  if (!sample.read_ok) {
    // Do not update last_valid_ms_. Staleness is judged below.
    if (last_valid_ms_ < 0 || (now_ms - last_valid_ms_) > deadline_ms_) {
      latched_unsafe_ = true;
      safe_to_charge_ = false;
    }
    return safe_to_charge_;
  }

  // A good, non-inhibited sample arrived. Record its time.
  last_valid_ms_ = sample.timestamp_ms;

  // Rule 3 (hard timing): even a "good" sample is rejected if it is too old
  // relative to now — a stale link must not keep charging alive.
  if ((now_ms - sample.timestamp_ms) > deadline_ms_) {
    latched_unsafe_ = true;
    safe_to_charge_ = false;
    return safe_to_charge_;
  }

  // Once unsafe has latched, recovery is only via an explicit Reset(). This is
  // deliberate: we never silently resume charging after a safety event.
  if (latched_unsafe_) {
    safe_to_charge_ = false;
    return safe_to_charge_;
  }

  safe_to_charge_ = true;
  return safe_to_charge_;
}

void SafetyMonitor::Reset() {
  latched_unsafe_ = false;
  safe_to_charge_ = false;  // require a fresh good sample before charging
  last_valid_ms_ = -1;
}

}  // namespace bms_adapter
