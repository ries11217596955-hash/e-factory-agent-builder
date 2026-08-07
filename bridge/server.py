from __future__ import annotations

import argparse
import hmac
import json
import os
import platform
import re
import shutil
import subprocess
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

VERSION = "0.1.0"
REPO_MARKERS = (
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def expand_path(value: str) -> str:
    if not value:
        return value

    def repl(match: re.Match[str]) -> str:
        name = match.group(1)
        return os.environ.get(name, match.group(0))

    value = re.sub(r"%([^%]+)%", repl, value)
    return os.path.abspath(os.path.expanduser(os.path.expandvars(value)))


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8-sig") as f:
        value = json.load(f)
    if not isinstance(value, dict):
        raise ValueError(f"JSON object required: {path}")
    return value


def atomic_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, path)


class BridgeState:
    def __init__(self, config_path: Path):
        self.config_path = config_path.resolve()
        cfg = load_json(self.config_path)
        self.bind_host = str(cfg.get("bind_host", "127.0.0.1"))
        self.port = int(cfg.get("port", 8765))
        self.shell = str(cfg.get("shell", "powershell" if os.name == "nt" else "bash"))
        self.max_timeout_sec = max(1, min(int(cfg.get("max_timeout_sec", 900)), 3600))
        self.max_body_bytes = max(1024, min(int(cfg.get("max_body_bytes", 65536)), 1024 * 1024))
        self.max_inline_output_bytes = max(1024, min(int(cfg.get("max_inline_output_bytes", 50000)), 500000))

        token_file = expand_path(str(cfg.get("token_file", "")))
        if not token_file:
            raise ValueError("token_file is required")
        self.token_file = Path(token_file)
        if not self.token_file.exists():
            raise FileNotFoundError(f"token file missing: {self.token_file}")
        self.token = self.token_file.read_text(encoding="utf-8-sig").strip()
        if len(self.token) < 24:
            raise ValueError("bridge token is too short")

        report_dir = expand_path(str(cfg.get("report_dir", "")))
        if not report_dir:
            raise ValueError("report_dir is required")
        self.report_dir = Path(report_dir)
        self.report_dir.mkdir(parents=True, exist_ok=True)

        raw_roots = cfg.get("allowed_roots", [])
        if not isinstance(raw_roots, list) or not raw_roots:
            raise ValueError("allowed_roots must be a non-empty list")
        self.allowed_roots = tuple(Path(expand_path(str(p))).resolve() for p in raw_roots)

        default_cwd = expand_path(str(cfg.get("default_cwd", str(self.allowed_roots[0]))))
        self.default_cwd = Path(default_cwd).resolve()
        self.resolve_cwd(str(self.default_cwd))

        recovery_report_dir = expand_path(str(cfg.get(
            "recovery_report_dir",
            os.path.join(os.environ.get("LOCALAPPDATA", str(Path.home())), "EFactory", "Recovery", "reports"),
        )))
        self.recovery_report_dir = Path(recovery_report_dir)
        self.lock = threading.Lock()

    def authorized(self, supplied: str | None) -> bool:
        if supplied is None:
            return False
        return hmac.compare_digest(self.token, supplied)

    def is_allowed_path(self, path: Path) -> bool:
        candidate = path.resolve()
        for root in self.allowed_roots:
            try:
                candidate.relative_to(root)
                return True
            except ValueError:
                continue
        return False

    def resolve_cwd(self, value: str | None) -> Path:
        path = self.default_cwd if not value else Path(expand_path(value)).resolve()
        if not self.is_allowed_path(path):
            raise PermissionError(f"cwd outside allowed_roots: {path}")
        if not path.exists() or not path.is_dir():
            raise FileNotFoundError(f"cwd does not exist: {path}")
        return path

    def write_run_report(self, report: dict, stdout: str, stderr: str) -> dict:
        run_id = report["run_id"]
        run_dir = self.report_dir / run_id
        run_dir.mkdir(parents=True, exist_ok=True)
        stdout_path = run_dir / "stdout.txt"
        stderr_path = run_dir / "stderr.txt"
        report_path = run_dir / "report.json"
        stdout_path.write_text(stdout, encoding="utf-8")
        stderr_path.write_text(stderr, encoding="utf-8")
        report = dict(report)
        report["stdout_path"] = str(stdout_path)
        report["stderr_path"] = str(stderr_path)
        report["report_path"] = str(report_path)
        atomic_json(report_path, report)
        latest = self.report_dir / "latest.json"
        atomic_json(latest, report)
        return report

    def latest_report(self) -> dict | None:
        path = self.report_dir / "latest.json"
        if not path.exists():
            return None
        return load_json(path)

    def latest_recovery_report(self) -> dict | None:
        if not self.recovery_report_dir.exists():
            return None
        files = sorted(self.recovery_report_dir.glob("recovery_*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
        if not files:
            return None
        return load_json(files[0])


def run_git(cwd: Path, *args: str) -> tuple[int, str, str]:
    git = shutil.which("git") or "git"
    proc = subprocess.run(
        [git, "-C", str(cwd), *args],
        capture_output=True,
        text=True,
        timeout=20,
        shell=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def repo_status(state: BridgeState, requested_path: str | None) -> dict:
    cwd = state.resolve_cwd(requested_path)
    code, root_text, err = run_git(cwd, "rev-parse", "--show-toplevel")
    if code != 0:
        raise RuntimeError(f"not a git repository: {err or root_text}")
    root = Path(root_text).resolve()
    if not state.is_allowed_path(root):
        raise PermissionError("git root outside allowed_roots")

    marker_missing = [m for m in REPO_MARKERS if not (root / m).exists()]
    code, branch, _ = run_git(root, "branch", "--show-current")
    if code != 0:
        branch = ""
    code, head, err = run_git(root, "rev-parse", "HEAD")
    if code != 0:
        raise RuntimeError(err or "unable to read HEAD")
    code, porcelain, err = run_git(root, "status", "--porcelain")
    if code != 0:
        raise RuntimeError(err or "unable to read status")
    code, remote, _ = run_git(root, "remote", "get-url", "origin")
    if code != 0:
        remote = ""

    changed = [line for line in porcelain.splitlines() if line.strip()]
    return {
        "status": "OK" if not marker_missing else "WRONG_OR_INCOMPLETE_AGENT_BUILDER_REPO",
        "repo_root": str(root),
        "branch": branch,
        "head": head,
        "dirty": bool(changed),
        "changed_files_count": len(changed),
        "origin": remote,
        "identity_missing": marker_missing,
        "timestamp": utc_now(),
    }


def shell_args(state: BridgeState, command: str) -> list[str]:
    shell_name = state.shell.lower()
    if shell_name == "powershell":
        exe = shutil.which("powershell.exe") or shutil.which("pwsh") or "powershell.exe"
        return [exe, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", command]
    if shell_name == "pwsh":
        exe = shutil.which("pwsh") or "pwsh"
        return [exe, "-NoProfile", "-NonInteractive", "-Command", command]
    if shell_name == "bash":
        exe = shutil.which("bash") or "bash"
        return [exe, "-lc", command]
    raise ValueError(f"unsupported shell: {state.shell}")


def execute_command(state: BridgeState, body: dict) -> dict:
    command = body.get("command")
    if not isinstance(command, str) or not command.strip():
        raise ValueError("command must be a non-empty string")
    if len(command) > 20000:
        raise ValueError("command too long")

    cwd = state.resolve_cwd(body.get("cwd"))
    timeout_sec = int(body.get("timeout_sec", min(120, state.max_timeout_sec)))
    timeout_sec = max(1, min(timeout_sec, state.max_timeout_sec))
    run_id = uuid.uuid4().hex
    started = time.monotonic()
    started_at = utc_now()
    timed_out = False

    try:
        proc = subprocess.run(
            shell_args(state, command),
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=timeout_sec,
            shell=False,
        )
        exit_code = proc.returncode
        stdout = proc.stdout or ""
        stderr = proc.stderr or ""
        status = "PASS" if exit_code == 0 else "FAIL"
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        exit_code = 124
        stdout = exc.stdout.decode(errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        stderr = exc.stderr.decode(errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        stderr += f"\nTIMEOUT after {timeout_sec}s"
        status = "TIMEOUT"

    duration_ms = int((time.monotonic() - started) * 1000)
    report = {
        "schema_version": 1,
        "run_id": run_id,
        "status": status,
        "started_at": started_at,
        "finished_at": utc_now(),
        "duration_ms": duration_ms,
        "cwd": str(cwd),
        "shell": state.shell,
        "command": command,
        "timeout_sec": timeout_sec,
        "timed_out": timed_out,
        "exit_code": exit_code,
    }
    report = state.write_run_report(report, stdout, stderr)

    limit = state.max_inline_output_bytes
    return {
        **report,
        "stdout": stdout[:limit],
        "stderr": stderr[:limit],
        "stdout_truncated": len(stdout) > limit,
        "stderr_truncated": len(stderr) > limit,
    }


def openapi_schema() -> dict:
    security = [{"BridgeToken": []}]
    return {
        "openapi": "3.1.0",
        "info": {"title": "E-Factory Local Bridge", "version": VERSION},
        "servers": [{"url": "/"}],
        "components": {
            "securitySchemes": {
                "BridgeToken": {"type": "apiKey", "in": "header", "name": "X-Bridge-Token"}
            }
        },
        "paths": {
            "/health": {"get": {"operationId": "bridgeHealth", "responses": {"200": {"description": "Bridge health"}}}},
            "/capabilities": {"get": {"operationId": "bridgeCapabilities", "security": security, "responses": {"200": {"description": "Capabilities"}}}},
            "/repo/status": {"get": {"operationId": "repoStatus", "security": security, "parameters": [{"name": "path", "in": "query", "required": False, "schema": {"type": "string"}}], "responses": {"200": {"description": "Repository status"}}}},
            "/run": {"post": {"operationId": "runCommand", "security": security, "requestBody": {"required": True, "content": {"application/json": {"schema": {"type": "object", "required": ["command"], "properties": {"command": {"type": "string"}, "cwd": {"type": "string"}, "timeout_sec": {"type": "integer", "minimum": 1, "maximum": 3600}}}}}}, "responses": {"200": {"description": "Execution result"}}}},
            "/reports/latest": {"get": {"operationId": "latestRunReport", "security": security, "responses": {"200": {"description": "Latest execution report"}}}},
            "/recovery/status": {"get": {"operationId": "recoveryStatus", "security": security, "responses": {"200": {"description": "Latest Recovery Agent report"}}}},
            "/openapi.json": {"get": {"operationId": "openApiSchema", "responses": {"200": {"description": "OpenAPI schema"}}}},
        },
    }


class BridgeHandler(BaseHTTPRequestHandler):
    server_version = "EFactoryBridge/0.1"

    @property
    def state(self) -> BridgeState:
        return self.server.bridge_state  # type: ignore[attr-defined]

    def log_message(self, fmt: str, *args) -> None:
        return

    def send_json(self, status_code: int, value: dict) -> None:
        payload = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def require_auth(self) -> bool:
        supplied = self.headers.get("X-Bridge-Token")
        if not self.state.authorized(supplied):
            self.send_json(401, {"status": "UNAUTHORIZED"})
            return False
        return True

    def read_json_body(self) -> dict:
        raw_length = self.headers.get("Content-Length")
        if raw_length is None:
            raise ValueError("Content-Length required")
        length = int(raw_length)
        if length < 0 or length > self.state.max_body_bytes:
            raise ValueError("request body too large")
        raw = self.rfile.read(length)
        value = json.loads(raw.decode("utf-8"))
        if not isinstance(value, dict):
            raise ValueError("JSON object required")
        return value

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/health":
                self.send_json(200, {
                    "status": "OK",
                    "version": VERSION,
                    "pid": os.getpid(),
                    "platform": platform.system(),
                    "timestamp": utc_now(),
                })
                return
            if parsed.path == "/openapi.json":
                self.send_json(200, openapi_schema())
                return
            if not self.require_auth():
                return
            if parsed.path == "/capabilities":
                self.send_json(200, {
                    "status": "OK",
                    "capabilities": ["health", "repo_status", "terminal_run", "reports", "recovery_status", "openapi"],
                    "allowed_roots": [str(p) for p in self.state.allowed_roots],
                    "shell": self.state.shell,
                    "max_timeout_sec": self.state.max_timeout_sec,
                })
                return
            if parsed.path == "/repo/status":
                query = parse_qs(parsed.query)
                requested = query.get("path", [None])[0]
                self.send_json(200, repo_status(self.state, requested))
                return
            if parsed.path == "/reports/latest":
                value = self.state.latest_report()
                self.send_json(200 if value else 404, value or {"status": "NO_REPORT"})
                return
            if parsed.path == "/recovery/status":
                value = self.state.latest_recovery_report()
                self.send_json(200 if value else 404, value or {"status": "NO_RECOVERY_REPORT"})
                return
            self.send_json(404, {"status": "NOT_FOUND"})
        except PermissionError as exc:
            self.send_json(403, {"status": "FORBIDDEN", "error": str(exc)})
        except FileNotFoundError as exc:
            self.send_json(404, {"status": "NOT_FOUND", "error": str(exc)})
        except Exception as exc:
            self.send_json(500, {"status": "ERROR", "error": str(exc)})

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        try:
            if not self.require_auth():
                return
            if parsed.path == "/run":
                body = self.read_json_body()
                result = execute_command(self.state, body)
                self.send_json(200, result)
                return
            self.send_json(404, {"status": "NOT_FOUND"})
        except PermissionError as exc:
            self.send_json(403, {"status": "FORBIDDEN", "error": str(exc)})
        except (ValueError, json.JSONDecodeError) as exc:
            self.send_json(400, {"status": "BAD_REQUEST", "error": str(exc)})
        except Exception as exc:
            self.send_json(500, {"status": "ERROR", "error": str(exc)})


class BridgeServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, state: BridgeState):
        super().__init__((state.bind_host, state.port), BridgeHandler)
        self.bridge_state = state


def main() -> int:
    parser = argparse.ArgumentParser(description="E-Factory Local Bridge")
    parser.add_argument("--config", required=True, help="Path to local Bridge config JSON")
    args = parser.parse_args()
    state = BridgeState(Path(args.config))
    server = BridgeServer(state)
    print(f"BRIDGE_LISTEN=http://{state.bind_host}:{state.port}", flush=True)
    print(f"BRIDGE_REPORT_DIR={state.report_dir}", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
