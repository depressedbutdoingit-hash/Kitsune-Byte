#!/usr/bin/env python3
"""
Kitsuné Byte — Termux local shell bridge
Run inside Termux:  python kitsune_bridge.py

Flutter LocalBridgeShellBackend talks to:
  GET  http://127.0.0.1:8765/health
  POST http://127.0.0.1:8765/exec   {"cmd": "...", "cwd": "..."}
"""

from __future__ import annotations

import json
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "127.0.0.1"
PORT = 8765


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[kitsune-bridge] " + (fmt % args) + "\n")

    def _json(self, code: int, payload: dict):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.rstrip("/") == "/health":
            self._json(200, {"ok": True, "service": "kitsune-bridge"})
            return
        self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path.rstrip("/") != "/exec":
            self._json(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._json(400, {"stdout": "", "stderr": "invalid json", "code": 1})
            return

        cmd = body.get("cmd") or ""
        cwd = body.get("cwd")
        if not cmd.strip():
            self._json(400, {"stdout": "", "stderr": "empty cmd", "code": 1})
            return

        try:
            p = subprocess.run(
                cmd,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=120,
            )
            self._json(
                200,
                {
                    "stdout": p.stdout or "",
                    "stderr": p.stderr or "",
                    "code": p.returncode,
                },
            )
        except subprocess.TimeoutExpired:
            self._json(500, {"stdout": "", "stderr": "timeout (120s)", "code": 124})
        except Exception as e:
            self._json(500, {"stdout": "", "stderr": str(e), "code": 1})


def main():
    server = HTTPServer((HOST, PORT), Handler)
    print(f"kitsune-bridge listening on http://{HOST}:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye", flush=True)


if __name__ == "__main__":
    main()
