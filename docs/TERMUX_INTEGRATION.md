# Termux / proot integration for Kitsuné Byte

Goal: the phone is the **primary** build machine. The terminal routes commands
to a real Linux environment when available, and falls back to simulation.

## Architecture

```
┌──────────────────────────┐
│  Kitsuné Terminal (Flutter) │
│  command router + tool cards │
└────────────┬─────────────┘
             │ ShellRouter
     ┌───────┼───────────────┐
     ▼       ▼               ▼
 LocalBridge  TermuxIntent   Simulated
 (HTTP :8765) (RUN_COMMAND)  (always on)
     │
     ▼
 Termux / proot-distro
 (full userspace, no root)
```

## Option A — Local HTTP bridge (recommended first)

Run a tiny helper **inside Termux** that executes commands and returns JSON.

```bash
# In Termux
pkg install python
pip install flask
```

Minimal bridge (`~/kitsune_bridge.py`):

```python
from flask import Flask, request, jsonify
import subprocess, shlex

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify(ok=True)

@app.post("/exec")
def exec_cmd():
    body = request.get_json(force=True)
    cmd = body.get("cmd", "")
    cwd = body.get("cwd")
    try:
        p = subprocess.run(
            cmd, shell=True, cwd=cwd,
            capture_output=True, text=True, timeout=120,
        )
        return jsonify(stdout=p.stdout, stderr=p.stderr, code=p.returncode)
    except Exception as e:
        return jsonify(stdout="", stderr=str(e), code=1), 500

app.run(host="127.0.0.1", port=8765)
```

Start it: `python ~/kitsune_bridge.py`

Flutter's `LocalBridgeShellBackend` probes `http://127.0.0.1:8765/health`
and POSTs to `/exec`.

**Android note:** cleartext localhost is fine for debug; for release add
network security config allowing 127.0.0.1.

## Option B — Termux RUN_COMMAND intent

Termux exposes `com.termux.RUN_COMMAND` so other apps can run scripts after the
user grants **Run commands in Termux environment**.

Extras (from Termux docs):

| Extra | Purpose |
|-------|---------|
| `com.termux.RUN_COMMAND_PATH` | absolute path to executable |
| `com.termux.RUN_COMMAND_ARGUMENTS` | string array of args |
| `com.termux.RUN_COMMAND_WORKDIR` | working directory |
| `com.termux.RUN_COMMAND_BACKGROUND` | boolean |
| `com.termux.RUN_COMMAND_SESSION_ACTION` | session handling |

Wire via Android `MethodChannel` in `android/` once the app has a native host
project (`flutter create .`). `TermuxIntentShellBackend` documents the contract;
`isAvailable()` stays false until the channel is registered.

## Option C — proot-distro

Inside Termux:

```bash
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
```

`ProotShellBackend` wraps any inner backend and prefixes:

```text
proot-distro login ubuntu -- bash -lc '<cmd>'
```

Gives a full Debian/Ubuntu userspace without root — ideal for `flutter`,
`node`, `python` toolchains on-device.

## Security

- Default: ask before every shell command (session / always / never later).
- Never ship a bridge that binds `0.0.0.0` without auth.
- Credit-gated AI path is separate from shell path.

## Detection order (`ShellRouter`)

1. Local bridge health check  
2. Termux intent (when platform channel exists)  
3. Simulated backend (always)

## Next implementation steps

1. `flutter create .` to generate `android/`  
2. MethodChannel for Termux package detection + RUN_COMMAND  
3. Optional foreground service to keep the bridge alive  
4. Permission UI: allowlist binaries (`flutter`, `git`, `ls`, …)
