// SPDX-License-Identifier: Apache-2.0
//
// UNIT U4 — SAFETY-RELEVANT, HUMAN-ENGINEERED
//
// SafetyMonitor implements the fail-safe and hard-timing behavior of the
// boundary (NFR design: "safety-monitor watches inhibit signal; forces safe
// idle on loss"). It is deliberately tiny, allocation-free, and exception-free
// so it is amenable to review and to a worst-case execution time (WCET) bound.

#ifndef BMS_ADAPTER_SAFETY_MONITOR_H
#define BMS_ADAPTER_SAFETY_MONITOR_H

#include <cstdint>

#include "bms_adapter/bms_types.h"

namespace bms_adapter {

class SafetyMonitor {
 public:
  // staleness_deadline_ms: max age of a valid sample before the interface is
  // considered lost (the hard timing budget for honoring an inhibit / loss).
  explicit SafetyMonitor(std::int64_t staleness_deadline_ms = 100)
      : deadline_ms_(staleness_deadline_ms) {}

  // Feed each freshly read sample at monotonic time `now_ms`. Returns the
  // safety verdict. Once unsafe, the monitor LATCHES until an explicit Reset.
  bool Evaluate(const BmsSample& sample, std::int64_t now_ms);

  // True if it is currently safe to permit charging.
  bool safe_to_charge() const { return safe_to_charge_; }

  // True if an inhibit or interface loss has ever latched this session.
  bool latched_unsafe() const { return latched_unsafe_; }

  // Clear the latch (e.g., after the inhibit clears and a fresh valid sample
  // arrives). Kept explicit so recovery is a deliberate, reviewable action.
  void Reset();

 private:
  std::int64_t deadline_ms_;
  std::int64_t last_valid_ms_ = -1;
  bool safe_to_charge_ = false;   // fail-safe default: not safe until proven
  bool latched_unsafe_ = false;
};

}  // namespace bms_adapter

#endif  // BMS_ADAPTER_SAFETY_MONITOR_H
