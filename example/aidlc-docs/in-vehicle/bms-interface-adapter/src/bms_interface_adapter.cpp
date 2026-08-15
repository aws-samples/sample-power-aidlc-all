// SPDX-License-Identifier: Apache-2.0
// UNIT U4 — SAFETY-RELEVANT, HUMAN-ENGINEERED
#include "bms_adapter/bms_interface_adapter.h"

namespace bms_adapter {

BmsInterfaceAdapter::BmsInterfaceAdapter(IBmsLink& link,
                                         std::int64_t staleness_deadline_ms)
    : link_(link), monitor_(staleness_deadline_ms) {}

BmsEnvelope BmsInterfaceAdapter::ReadEnvelope(std::int64_t now_ms) {
  const BmsSample sample = link_.Read();
  const bool safe = monitor_.Evaluate(sample, now_ms);

  BmsEnvelope env;  // fail-safe defaults: inhibit=true, valid=false
  if (!safe) {
    // Any unsafe verdict surfaces as an inhibited, invalid envelope, and we
    // proactively command a stop so charging cannot continue.
    link_.Command(0.0);
    env.inhibit = true;
    env.valid = !(!sample.read_ok);  // valid only reflects link reachability
    env.max_charge_current_a = 0.0;
    return env;
  }

  env.valid = true;
  env.inhibit = false;
  env.max_charge_current_a =
      sample.permitted_current_a < 0.0 ? 0.0 : sample.permitted_current_a;
  return env;
}

bool BmsInterfaceAdapter::RequestCharge(double current_a, std::int64_t now_ms) {
  const BmsEnvelope env = ReadEnvelope(now_ms);
  if (!env.valid || env.inhibit) {
    link_.Command(0.0);
    return false;
  }
  double permitted = current_a;
  if (permitted > env.max_charge_current_a) {
    permitted = env.max_charge_current_a;  // clamp to envelope (CS-SR-002)
  }
  if (permitted <= 0.0) {
    link_.Command(0.0);
    return false;
  }
  return link_.Command(permitted);
}

void BmsInterfaceAdapter::StopCharge() { link_.Command(0.0); }

}  // namespace bms_adapter
