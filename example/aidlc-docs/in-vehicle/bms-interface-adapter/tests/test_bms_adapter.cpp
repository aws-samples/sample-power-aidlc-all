// SPDX-License-Identifier: Apache-2.0
// UNIT U4 — SAFETY-RELEVANT — safety-constraint tests are engineer-owned.
//
// Verifies CS-SR-002 (inhibit authoritative) and CS-SR-003 (safe idle on
// interface loss), plus the hard staleness deadline.

#include <cstdio>

#include "bms_adapter/bms_interface_adapter.h"
#include "bms_adapter/safety_monitor.h"

namespace {
int g_failures = 0;
void check(bool cond, const char* what) {
  std::printf(cond ? "  [PASS] %s\n" : "  [FAIL] %s\n", what);
  if (!cond) ++g_failures;
}
}  // namespace

using namespace bms_adapter;

// Controllable BMS link: holds the next sample and records commands.
class FakeLink : public IBmsLink {
 public:
  BmsSample next;
  double last_command = -1.0;
  int command_calls = 0;

  FakeLink() {
    next.read_ok = true;
    next.permitted_current_a = 32.0;
    next.inhibit_asserted = false;
    next.timestamp_ms = 0;
  }
  BmsSample Read() override { return next; }
  bool Command(double current_a) override {
    ++command_calls;
    last_command = current_a;
    return current_a > 0.0;  // accept positive setpoints
  }
};

void TestGoodSampleIsSafe() {
  FakeLink link;
  link.next.timestamp_ms = 1000;
  BmsInterfaceAdapter adapter(link, /*deadline_ms=*/100);

  const BmsEnvelope env = adapter.ReadEnvelope(1050);
  check(env.valid && !env.inhibit, "CS-SR good sample -> valid, not inhibited");
  check(env.max_charge_current_a == 32.0, "envelope exposes permitted current");
}

void TestInhibitWins() {
  FakeLink link;
  link.next.timestamp_ms = 1000;
  link.next.inhibit_asserted = true;  // BMS asserts inhibit
  BmsInterfaceAdapter adapter(link, 100);

  const BmsEnvelope env = adapter.ReadEnvelope(1050);
  check(env.inhibit, "CS-SR-002 inhibit surfaced");
  check(adapter.monitor().latched_unsafe(), "CS-SR-002 unsafe latched");
  check(link.last_command == 0.0, "CS-SR-002 stop commanded on inhibit");

  // Even if a later request comes in, it must be refused.
  const bool granted = adapter.RequestCharge(32.0, 1100);
  check(!granted, "CS-SR-002 charge never granted under inhibit");
}

void TestInterfaceLossIsSafeIdle() {
  FakeLink link;
  link.next.read_ok = false;  // transport error
  BmsInterfaceAdapter adapter(link, 100);

  const BmsEnvelope env = adapter.ReadEnvelope(5000);
  check(!env.valid || env.inhibit, "CS-SR-003 interface loss -> not chargeable");
  check(!adapter.RequestCharge(32.0, 5001), "CS-SR-003 no charge on lost interface");
}

void TestStaleSampleRejected() {
  FakeLink link;
  link.next.timestamp_ms = 1000;  // sample is old
  BmsInterfaceAdapter adapter(link, 100);

  // now is 1500ms, sample is 500ms old > 100ms deadline -> unsafe.
  const BmsEnvelope env = adapter.ReadEnvelope(1500);
  check(env.inhibit || !env.valid, "hard deadline: stale sample is not chargeable");
}

void TestRequestClampsToEnvelope() {
  FakeLink link;
  link.next.timestamp_ms = 1000;
  link.next.permitted_current_a = 16.0;  // BMS permits only 16A
  BmsInterfaceAdapter adapter(link, 100);

  const bool granted = adapter.RequestCharge(63.0, 1050);  // ask for more
  check(granted, "request granted within envelope");
  check(link.last_command == 16.0, "CS-SR-002 request clamped to BMS envelope (16A)");
}

void TestMonitorResetRequiresFreshSample() {
  SafetyMonitor mon(100);
  BmsSample s;
  s.read_ok = true;
  s.inhibit_asserted = true;
  s.timestamp_ms = 100;
  mon.Evaluate(s, 100);
  check(mon.latched_unsafe(), "monitor latches on inhibit");

  mon.Reset();
  check(!mon.safe_to_charge(), "after reset, not safe until a fresh good sample");

  s.inhibit_asserted = false;
  s.timestamp_ms = 200;
  mon.Evaluate(s, 200);
  check(mon.safe_to_charge(), "fresh good sample after reset restores safe state");
}

int main() {
  std::printf("RUN U4 bms-interface-adapter safety tests\n");
  TestGoodSampleIsSafe();
  TestInhibitWins();
  TestInterfaceLossIsSafeIdle();
  TestStaleSampleRejected();
  TestRequestClampsToEnvelope();
  TestMonitorResetRequiresFreshSample();
  std::printf("\n%s (%d failure%s)\n",
              g_failures == 0 ? "ALL TESTS PASSED" : "TESTS FAILED", g_failures,
              g_failures == 1 ? "" : "s");
  return g_failures == 0 ? 0 : 1;
}
