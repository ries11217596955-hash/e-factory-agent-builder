import json
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from server import BridgeServer, BridgeState  # noqa: E402


class BridgeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.token = "test-token-abcdefghijklmnopqrstuvwxyz-123456"
        token_file = self.root / "token.txt"
        token_file.write_text(self.token, encoding="utf-8")
        reports = self.root / "reports"
        recovery = self.root / "recovery"
        cfg = {
            "bind_host": "127.0.0.1",
            "port": 0,
            "shell": "bash",
            "token_file": str(token_file),
            "report_dir": str(reports),
            "recovery_report_dir": str(recovery),
            "allowed_roots": [str(self.root)],
            "default_cwd": str(self.root),
            "max_timeout_sec": 20,
            "max_body_bytes": 65536,
            "max_inline_output_bytes": 50000,
        }
        self.cfg_path = self.root / "config.json"
        self.cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
        self.state = BridgeState(self.cfg_path)
        self.server = BridgeServer(self.state)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        host, port = self.server.server_address
        self.base = f"http://{host}:{port}"

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=3)
        self.tmp.cleanup()

    def request(self, path, method="GET", body=None, token=None):
        data = None if body is None else json.dumps(body).encode("utf-8")
        headers = {}
        if body is not None:
            headers["Content-Type"] = "application/json"
        if token is not None:
            headers["X-Bridge-Token"] = token
        req = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                return resp.status, json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            return exc.code, json.loads(exc.read().decode("utf-8"))

    def test_health_without_auth(self):
        status, data = self.request("/health")
        self.assertEqual(status, 200)
        self.assertEqual(data["status"], "OK")

    def test_auth_required(self):
        status, _ = self.request("/capabilities")
        self.assertEqual(status, 401)
        status, data = self.request("/capabilities", token=self.token)
        self.assertEqual(status, 200)
        self.assertIn("terminal_run", data["capabilities"])

    def test_openapi_has_api_key(self):
        status, data = self.request("/openapi.json")
        self.assertEqual(status, 200)
        scheme = data["components"]["securitySchemes"]["BridgeToken"]
        self.assertEqual(scheme["name"], "X-Bridge-Token")

    def test_run_and_report(self):
        status, data = self.request(
            "/run",
            method="POST",
            token=self.token,
            body={"command": "printf bridge_ok", "cwd": str(self.root), "timeout_sec": 5},
        )
        self.assertEqual(status, 200)
        self.assertEqual(data["status"], "PASS")
        self.assertEqual(data["stdout"], "bridge_ok")
        self.assertTrue(Path(data["report_path"]).exists())
        status, latest = self.request("/reports/latest", token=self.token)
        self.assertEqual(status, 200)
        self.assertEqual(latest["run_id"], data["run_id"])

    def test_cwd_boundary(self):
        outside = Path(self.root.parent)
        status, data = self.request(
            "/run",
            method="POST",
            token=self.token,
            body={"command": "true", "cwd": str(outside)},
        )
        self.assertEqual(status, 403)
        self.assertEqual(data["status"], "FORBIDDEN")


if __name__ == "__main__":
    unittest.main(verbosity=2)
