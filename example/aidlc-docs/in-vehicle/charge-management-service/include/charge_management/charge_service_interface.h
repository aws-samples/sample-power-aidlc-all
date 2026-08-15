// SPDX-License-Identifier: Apache-2.0
//
// ara::com-style service interface for the charge-management service (Step 3 of
// the code-generation plan: "ara::com service interface (from IDL)").
//
// On a real AUTOSAR Adaptive target this would be GENERATED from a formal
// interface definition (e.g., a SOME/IP or DDS binding) by the AUTOSAR
// toolchain. We model the same shape here in portable C++ so the example builds
// without the AUTOSAR SDK. Service discovery and event/method semantics follow
// the middleware's model (Chapter 6.2), not a generic cloud request/response.

#ifndef CHARGE_MANAGEMENT_CHARGE_SERVICE_INTERFACE_H
#define CHARGE_MANAGEMENT_CHARGE_SERVICE_INTERFACE_H

#include <functional>

#include "charge_management/domain_types.h"

namespace charge_management {

// Offered service: ChargeManagement (service id reserved by ARXML in a real
// deployment). Methods are request/response; events are published to subscribers.
class IChargeManagementService {
 public:
  virtual ~IChargeManagementService() = default;

  // Method: SetSchedule — receive a resolved plan from the cloud command channel.
  // The command must be authenticated and integrity-protected upstream
  // (CS-SEC-005); this method assumes a verified payload.
  virtual void SetSchedule(const ChargePlan& plan) = 0;

  // Method: GetStatus — current charge session status (CS-FR-031).
  virtual StatusEvent GetStatus() const = 0;

  // Event: ChargeStatus — published on every state change to subscribers
  // (the app via the cloud, and the telemetry pipeline U6).
  using ChargeStatusHandler = std::function<void(const StatusEvent&)>;
  virtual void SubscribeChargeStatus(ChargeStatusHandler handler) = 0;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_CHARGE_SERVICE_INTERFACE_H
