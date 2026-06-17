!/usr/bin/env python3
"""
Hyprland: segunda ventana de Firefox en el mismo workspace → flotante.
Firefox suele usar el mismo initialTitle en todas las ventanas, así que las
windowrules estáticas no bastan; se escucha el socket de eventos (socket2).
"""

from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import threading
import time

OPENWINDOW = re.compile(r"^(?:openwindowv2|openwindow)>>(0x[0-9a-f]+)")
FF_CLASSES = frozenset(
    {"firefox", "org.mozilla.firefox", "LibreWolf", "librewolf"},
)


def _hypr_clients() -> list[dict] | None:
    try:
        out = subprocess.run(
            ["hyprctl", "clients", "-j"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        if out.returncode != 0:
            return None
        data = json.loads(out.stdout)
        return data if isinstance(data, list) else None
    except (json.JSONDecodeError, subprocess.TimeoutExpired, OSError):
        return None


def _float_secondary(addr: str) -> None:
    win: dict | None = None
    for _ in range(12):
        clients = _hypr_clients()
        if not clients:
            time.sleep(0.04)
            continue
        win = next((c for c in clients if c.get("address") == addr), None)
        if win:
            break
        time.sleep(0.04)

    if not win:
        return

    cls = win.get("class") or ""
    if cls not in FF_CLASSES:
        return

    ws = win.get("workspace") or {}
    ws_id = ws.get("id")
    if ws_id is None:
        return

    clients = _hypr_clients()
    if not clients:
        return

    n = sum(
        1
        for c in clients
        if (c.get("class") or "") in FF_CLASSES
        and (c.get("workspace") or {}).get("id") == ws_id
    )
    if n < 2:
        return

    batch = (
        f"dispatch setfloating address:{addr};"
        f"dispatch resizewindowpixel exact 85% 80%,address:{addr};"
        f"dispatch centerwindow address:{addr}"
    )
    subprocess.run(
        ["hyprctl", "--batch", batch],
        capture_output=True,
        timeout=5,
        check=False,
    )


def _handle_line(line: str) -> None:
    m = OPENWINDOW.match(line.strip())
    if not m:
        return
    addr = m.group(1)
    if not addr:
        return
    t = threading.Thread(target=_float_secondary, args=(addr,), daemon=True)
    t.start()


def main() -> None:
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    rt = os.environ.get("XDG_RUNTIME_DIR", "")
    if not sig or not rt:
        return

    path = os.path.join(rt, "hypr", sig, ".socket2.sock")
    if not os.path.exists(path):
        return

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(path)
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    _handle_line(line.decode("utf-8", errors="replace"))
                except Exception:
                    pass


if __name__ == "__main__":
    main()
