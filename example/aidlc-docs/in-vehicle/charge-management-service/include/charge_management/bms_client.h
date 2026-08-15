// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// SAFETY-RELEVANT BOUNDARY COMPONENT — REVIEW-GATED, HUMAN-ENGINEERED
// =============================================================================
// This file is the green/red boundary of Chapter 7-8. The AI-DLC workflow may
// scaffold its *structure* against the agreed interface contract, but the logic
// that interprets and honors a BMS inhibit is safety-relevant (CS-SR-002,
// CS-SR-003) and is human-engineered, reviewed, and HIL-verified. Generative AI
// is NOT in this loop.
//
// BmsClient is a fail-safe facade in front of the BMS interface adapter (U4):
// any uncertainty (invalid read, lost interface, exception) is treated as an
// inhibit. It enforces the bright-line rule that the inhibit always wins.
// =============================================================================

#ifndef CHARGE_MANAGEMENT_BMS_CLIENT_H
#define CHARGE_MANAGEMENT_BMS_CLIENT_H

#include "charge_management/i_bms_adapter.h"

namespace charge_management {

// Wraps the underlying adapter (U4) and guarantees fail-safe semantics to the
// rest of the QM-rated service. Implements IBmsAdapter so the executor can
// depend only on the contract.
class BmsClient final : public IBmsAdapter {
 public:
  explicit BmsClient(IBmsAdapter& adapter);

  // Returns a fail-safe envelope (inhibit=true, valid=false) if the underlying
  // read is invalid or throws. A valid envelope is passed through unchanged.
  BmsEnvelope ReadEnvelope() override;

  // Requests charge ONLY if the latest envelope is valid and not inhibited and
  // the requested current is within the permitted maximum. Otherwise refuses.
  bool RequestCharge(double current_a) override;

  // Always forwarded; stopping charge is always safe.
  void StopCharge() override;

  // True once an inhibit or interface loss has been observed in this session.
  bool inhibit_latched() const { return inhibit_latched_; }

 private:
  IBmsAdapter& adapter_;
  bool inhibit_latched_ = false;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_BMS_CLIENT_H
