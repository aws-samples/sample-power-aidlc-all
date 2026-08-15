// SPDX-License-Identifier: Apache-2.0
//
// UNIT U4 — SAFETY-RELEVANT, HUMAN-ENGINEERED
//
// Low-level link to the BMS (CAN/automotive Ethernet/SOME/IP on target). The
// adapter depends only on this abstraction; the concrete transport is supplied
// by the platform. A simulated link is provided for the runnable example.

#ifndef BMS_ADAPTER_I_BMS_LINK_H
#define BMS_ADAPTER_I_BMS_LINK_H

#include "bms_adapter/bms_types.h"

namespace bms_adapter {

class IBmsLink {
 public:
  virtual ~IBmsLink() = default;

  // Read one sample. MUST set read_ok=false on any transport error; MUST NOT
  // throw. On error the adapter treats the interface as lost (CS-SR-003).
  virtual BmsSample Read() = 0;

  // Command the charger contactor / current setpoint at the BMS side.
  // `current_a == 0` means stop. Returns false if the command was not accepted.
  virtual bool Command(double current_a) = 0;
};

}  // namespace bms_adapter

#endif  // BMS_ADAPTER_I_BMS_LINK_H
