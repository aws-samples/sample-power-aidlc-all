"""Run the schedule API locally (demo).

    python3 main.py          # serves on 127.0.0.1:8080

Then, for example:
    curl -s -X POST localhost:8080/v1/schedules \
      -H 'Authorization: Bearer demo-token' -H 'Content-Type: application/json' \
      -d '{"vehicle_id":"VIN123","current_soc_pct":50,"target_soc_pct":80,
           "departure_epoch_s": 1893456000}'
"""

from schedule_api.app import serve
from schedule_api.auth import TokenAuthenticator
from schedule_api.service import ScheduleService
from tariff_planner import TariffWindow  # via service.py sys.path insertion


def build_service() -> ScheduleService:
    auth = TokenAuthenticator(
        tokens={"demo-token": "mobile-app", "vehicle-token": "vehicle-fleet"},
        signing_key=b"demo-signing-key-not-for-production",
    )
    # A couple of illustrative tariff windows (cheap overnight, pricey daytime).
    tariffs = [
        TariffWindow(0, 6 * 3600, price_per_kwh=0.10),
        TariffWindow(6 * 3600, 22 * 3600, price_per_kwh=0.35),
    ]
    return ScheduleService(auth, tariffs=tariffs)


if __name__ == "__main__":
    httpd = serve(service=build_service())
    print("schedule-api listening on http://127.0.0.1:8080  (Ctrl-C to stop)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.shutdown()
