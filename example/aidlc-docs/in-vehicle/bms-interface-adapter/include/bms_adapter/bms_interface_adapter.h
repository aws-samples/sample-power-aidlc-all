// SPDX-License-Identifier: Apache-2.0
//
// UNIT U4 — SAFETY-RELEVANT, HUMAN-ENGINEERED
//
// BmsInterfaceAdapter is the single, isolated path between the QM charge-
// management service (U3) and the safety-relevant BMS. It enforces the bright
// line of Chapter 8: a BMS inhibit always wins and is never AI-generated.
//
// It exposes the same shape U3 depends on (ReadEnvelope / RequestCharge /
// StopCharge); a thin glue type in U3 (BmsClient) adapts it to U3's IBmsAdapter.

#ifndef BMS_ADAPTER_BMS_INTERFACE_ADAPTER_H
#define BMS_ADAPTER_BMS_INTERFACE_ADAPTER_H

#include "bms_adapter/bms_types.h"
#include "bms_adapter/i_bms_link.h"
#include "bms_adapter/safety_monitor.h"

namespace bms_adapter {

class BmsInterfaceAdapter {
 public:
  BmsInterfaceAdapter(IBmsLink& link, std::int64_t staleness_deadline_ms = 100);

  // Read the current envelope. Returns a fail-safe envelope (inhibit, invalid)
  // whenever the safety monitor is not satisfied (CS-SR-002/003).
  BmsEnvelope ReadEnvelope(std::int64_t now_ms);

  // Request charge at up to current_a. Honored only when safe and within the
  // permitted envelope; otherwise commands a stop and returns false.
  bool RequestCharge(double current_a, std::int64_t now_ms);

  // Always commands the BMS to stop charging. Safe to call in any state.
  void StopCharge();

  const SafetyMonitor& monitor() const { return monitor_; }

 private:
  IBmsLink& link_;
  SafetyMonitor monitor_;
};

}  // namespace bms_adapter

#endif  // BMS_ADAPTER_BMS_INTERFACE_ADAPTER_H
