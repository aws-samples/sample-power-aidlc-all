// SPDX-License-Identifier: Apache-2.0
//
// The contract the charge-management service depends on to talk to the BMS.
// The concrete implementation lives in the bms-interface-adapter unit (U4),
// which is the ONLY component that talks to the safety-relevant BMS.
//
// This interface is the agreed boundary contract (Chapter 6.2): the service may
// *request* charging within an envelope and must *honor* a BMS inhibit
// immediately (CS-SR-002, CS-SR-003).

#ifndef CHARGE_MANAGEMENT_I_BMS_ADAPTER_H
#define CHARGE_MANAGEMENT_I_BMS_ADAPTER_H

#include "charge_management/domain_types.h"

namespace charge_management {

class IBmsAdapter {
 public:
  virtual ~IBmsAdapter() = default;

  // Returns the current envelope. Implementations MUST return a fail-safe
  // envelope (inhibit=true, valid=false) when the BMS state is unknown.
  virtual BmsEnvelope ReadEnvelope() = 0;

  // Requests charging at up to `current_a`. Returns true only if the BMS
  // granted a charge within its envelope. Never overrides an inhibit.
  virtual bool RequestCharge(double current_a) = 0;

  // Commands an immediate stop of charge initiation. Always safe to call.
  virtual void StopCharge() = 0;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_I_BMS_ADAPTER_H
