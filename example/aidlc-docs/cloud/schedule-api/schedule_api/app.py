"""HTTP shell for the schedule API (U1), built on the standard library so the
example runs without external web frameworks. In production this is a container
service behind an authenticated API gateway with mTLS (infrastructure-design.md).

Routes:
  POST /v1/schedules                 set/replace a schedule (US-03)
  GET  /v1/schedules/{vehicle_id}    vehicle pulls its resolved plan
  POST /v1/status                    vehicle reports status (US-15)
  GET  /v1/status/{vehicle_id}       driver/app reads status
  GET  /healthz                      liveness (unauthenticated)
"""

from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from .auth import AuthError, TokenAuthenticator
from .service import ScheduleService


def make_handler(service: ScheduleService):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def _send(self, code: int, payload: dict):
            body = json.dumps(payload).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _read_body(self) -> dict:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            return json.loads(raw or b"{}")

        def _auth_header(self) -> str:
            return self.headers.get("Authorization", "")

        def log_message(self, *args):  # silence default stderr logging
            pass

        def do_GET(self):
            try:
                if self.path == "/healthz":
                    return self._send(200, {"status": "ok"})
                if self.path.startswith("/v1/schedules/"):
                    vid = self.path.rsplit("/", 1)[-1]
                    return self._send(200, service.get_plan(self._auth_header(), vid))
                if self.path.startswith("/v1/status/"):
                    vid = self.path.rsplit("/", 1)[-1]
                    return self._send(200, service.get_status(self._auth_header(), vid))
                return self._send(404, {"error": "not found"})
            except AuthError as exc:
                return self._send(401, {"error": str(exc)})
            except KeyError:
                return self._send(404, {"error": "unknown vehicle"})

        def do_POST(self):
            try:
                body = self._read_body()
                if self.path == "/v1/schedules":
                    return self._send(201, service.set_schedule(self._auth_header(), body))
                if self.path == "/v1/status":
                    return self._send(200, service.report_status(self._auth_header(), body))
                return self._send(404, {"error": "not found"})
            except AuthError as exc:
                return self._send(401, {"error": str(exc)})
            except ValueError as exc:
                return self._send(400, {"error": str(exc)})

    return Handler


def serve(host: str = "127.0.0.1", port: int = 8080,
          service: ScheduleService = None) -> ThreadingHTTPServer:
    if service is None:
        raise ValueError("a ScheduleService instance is required")
    httpd = ThreadingHTTPServer((host, port), make_handler(service))
    return httpd
