// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// SAFETY-RELEVANT BOUNDARY COMPONENT — REVIEW-GATED, HUMAN-ENGINEERED
// =============================================================================
// Per the code-generation plan (Step 4) and Chapter 7.2, this file is flagged
// review-gated. The logic below that interprets and honors a BMS inhibit is
// safety-relevant (CS-SR-002, CS-SR-003) and was written and reviewed by
// engineers, not generated. Changes here require functional-safety review and
// HIL re-verification.
//
// Design intent: be a fail-safe facade. When in doubt, inhibit.
// =============================================================================

#include "charge_management/bms_client.h"

namespace charge_management {

BmsClient::BmsClient(IBmsAdapter& adapter) : adapter_(adapter) {}

BmsEnvelope BmsClient::ReadEnvelope() {
  // A fail-safe envelope: assume the worst until the adapter proves otherwise.
  BmsEnvelope safe;
  safe.max_charge_current_a = 0.0;
  safe.inhibit = true;
  safe.valid = false;

  BmsEnvelope env = adapter_.ReadEnvelope();

  // Treat an invalid read (interface loss, CS-SR-003) as a latched inhibit.
  if (!env.valid) {
    inhibit_latched_ = true;
    return safe;
  }

  // An explicit inhibit (CS-SR-002) latches and is never overridden downstream.
  if (env.inhibit) {
    inhibit_latched_ = true;
    env.max_charge_current_a = 0.0;  // no charging permitted under inhibit
    return env;
  }

  // Defensive clamp: a negative permitted current is nonsensical -> treat as 0.
  if (env.max_charge_current_a < 0.0) {
    env.max_charge_current_a = 0.0;
  }
  return env;
}

bool BmsClient::RequestCharge(double current_a) {
  // Re-read the envelope at the moment of the request; do not trust stale state.
  const BmsEnvelope env = ReadEnvelope();

  // Bright line: never request charge under inhibit or an invalid interface.
  if (!env.valid || env.inhibit) {
    adapter_.StopCharge();
    return false;
  }

  // BR-01: charge only within the BMS-permitted envelope. Clamp the request.
  double permitted = current_a;
  if (permitted > env.max_charge_current_a) {
    permitted = env.max_charge_current_a;
  }
  if (permitted <= 0.0) {
    adapter_.StopCharge();
    return false;
  }

  return adapter_.RequestCharge(permitted);
}

void BmsClient::StopCharge() {
  // Always safe; forward unconditionally.
  adapter_.StopCharge();
}

}  // namespace charge_management
