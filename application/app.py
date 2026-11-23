"""Tiny standard-library HTTP service used by the delivery-platform lab."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import threading
import time
from urllib.parse import urlparse

PORT = int(os.getenv("PORT", "8080"))
APP_VERSION = os.getenv("APP_VERSION", "local")
FAIL_REQUESTS = os.getenv("FAIL_REQUESTS", "false").lower() == "true"
LOCK = threading.Lock()
COUNTERS = {}
STARTED = time.time()


def record(path: str, status: int) -> None:
    key = (path, status)
    with LOCK:
        COUNTERS[key] = COUNTERS.get(key, 0) + 1


class Handler(BaseHTTPRequestHandler):
    server_version = "delivery-demo/1.0"

    def log_message(self, fmt, *args):
        # Keep logs useful but avoid noisy default request logging.
        print(json.dumps({"event": "http", "message": fmt % args}), flush=True)

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/healthz":
            self._send(200, {"status": "ok"})
            return

        if path == "/readyz":
            self._send(200, {"status": "ready", "version": APP_VERSION})
            return

        if path == "/metrics":
            self._metrics()
            return

        if path == "/" and FAIL_REQUESTS:
            self._send(503, {"status": "degraded", "version": APP_VERSION,
                             "reason": "fault-injection.enabled is present"})
            return

        if path == "/":
            self._send(200, {"service": "secure-gitops-demo", "version": APP_VERSION,
                             "status": "healthy", "uptime_seconds": int(time.time() - STARTED)})
            return

        self._send(404, {"error": "not_found", "path": path})

    def _send(self, status: int, payload: dict):
        path = urlparse(self.path).path
        record(path, status)
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _metrics(self):
        with LOCK:
            snapshot = dict(COUNTERS)
        lines = [
            "# HELP app_http_requests_total Total HTTP requests by path and status.",
            "# TYPE app_http_requests_total counter",
        ]
        for (path, status), count in sorted(snapshot.items()):
            safe_path = path.replace('\\', '\\\\').replace('"', '\\"')
            lines.append(f'app_http_requests_total{{path="{safe_path}",status="{status}"}} {count}')
        lines.extend([
            "# HELP app_uptime_seconds Process uptime in seconds.",
            "# TYPE app_uptime_seconds gauge",
            f"app_uptime_seconds {int(time.time() - STARTED)}",
        ])
        body = ("\n".join(lines) + "\n").encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(json.dumps({"event": "startup", "version": APP_VERSION,
                      "fail_requests": FAIL_REQUESTS, "port": PORT}), flush=True)
    server.serve_forever()
