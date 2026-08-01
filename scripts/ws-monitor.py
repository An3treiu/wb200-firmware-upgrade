#!/usr/bin/env python3
"""Live OTA progress monitor for a HyFix WB200 (GEODNET miner).

The device's web UI receives upgrade progress over a WebSocket at
``ws://<ip>:8080/mcm``. This script subscribes to the same stream and prints
every message with a timestamp, so you can watch an upgrade from the terminal.

It implements just enough of RFC 6455 to read text frames, so it runs on a
stock Python 3 install -- no ``websocket-client``, no ``websockets``, no pip.

Usage::

    python ws-monitor.py [IP] [SECONDS]

Examples::

    python ws-monitor.py                    # 192.168.10.1, 15 minutes
    python ws-monitor.py 192.168.1.50 1800  # custom host, 30 minutes

Messages you will see during an upgrade::

    APPOTA:ONLINE:Found firmware vX.Y.Z    status text
    APPOTA:UPLOAD:NN                       file upload percentage (offline only)
    APPOTA:UPGRADE:NN                      firmware write percentage
    GNSSOTA:UPLOAD/UPGRADE:NN              same, for the GNSS module

The connection dropping mid-upgrade is EXPECTED: it means the flash was applied
and the device is rebooting.

https://github.com/An3treiu/wb200-firmware-upgrade
"""

import base64
import json
import os
import socket
import struct
import sys
import time
import urllib.request

WS_PORT = 8080
WS_PATH = "/mcm"


def log(message):
    print(f"[{time.strftime('%H:%M:%S')}] {message}", flush=True)


def fetch_token(host):
    """Build the session cookie from the serial number.

    ``/action/devStatus`` is public, and the token is simply
    base64("user:<serial>") -- so no login round-trip is needed.
    Returns None if the device cannot be reached; the WebSocket handshake
    is still attempted without a cookie.
    """
    try:
        with urllib.request.urlopen(f"http://{host}/action/devStatus", timeout=8) as response:
            serial = json.loads(response.read().decode()).get("sn")
        if not serial:
            return None
        return base64.b64encode(f"user:{serial}".encode()).decode()
    except Exception as exc:
        log(f"could not read devStatus ({exc}); continuing without a cookie")
        return None


def handshake(sock, host, token):
    key = base64.b64encode(os.urandom(16)).decode()
    lines = [
        f"GET {WS_PATH} HTTP/1.1",
        f"Host: {host}:{WS_PORT}",
        "Upgrade: websocket",
        "Connection: Upgrade",
        f"Sec-WebSocket-Key: {key}",
        "Sec-WebSocket-Version: 13",
        f"Origin: http://{host}",
    ]
    if token:
        lines.append(f"Cookie: USER={token}")
    sock.sendall(("\r\n".join(lines) + "\r\n\r\n").encode())

    buffer = b""
    while b"\r\n\r\n" not in buffer:
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("connection closed during handshake")
        buffer += chunk

    header, remainder = buffer.split(b"\r\n\r\n", 1)
    status_line = header.split(b"\r\n")[0].decode(errors="replace")
    log(f"handshake: {status_line}")
    if b"101" not in header.split(b"\r\n")[0]:
        raise ConnectionError(f"handshake failed: {status_line}")
    return remainder


class FrameReader:
    """Buffered reader so we can pull an exact number of bytes off the socket."""

    def __init__(self, sock, initial=b""):
        self.sock = sock
        self.buffer = bytearray(initial)

    def read(self, count):
        while len(self.buffer) < count:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("connection closed by device")
            self.buffer += chunk
        data = bytes(self.buffer[:count])
        del self.buffer[:count]
        return data


def send_frame(sock, opcode, payload=b""):
    """Client-to-server frames must be masked (RFC 6455 section 5.3)."""
    mask = os.urandom(4)
    masked = bytes(byte ^ mask[i % 4] for i, byte in enumerate(payload))
    header = bytes([0x80 | opcode])
    length = len(payload)
    if length < 126:
        header += bytes([0x80 | length])
    elif length < 65536:
        header += bytes([0x80 | 126]) + struct.pack(">H", length)
    else:
        header += bytes([0x80 | 127]) + struct.pack(">Q", length)
    sock.sendall(header + mask + masked)


def monitor(host, duration):
    token = fetch_token(host)
    sock = socket.create_connection((host, WS_PORT), timeout=15)
    reader = FrameReader(sock, handshake(sock, host, token))
    sock.settimeout(5)

    deadline = time.time() + duration
    log(f"listening for OTA messages on ws://{host}:{WS_PORT}{WS_PATH} ...")

    while time.time() < deadline:
        try:
            first, second = reader.read(2)
        except socket.timeout:
            continue
        except ConnectionError as exc:
            log(f"DISCONNECTED: {exc}")
            log("during an upgrade this is expected - the device is rebooting.")
            return

        opcode = first & 0x0F
        masked = second & 0x80
        length = second & 0x7F
        if length == 126:
            length = struct.unpack(">H", reader.read(2))[0]
        elif length == 127:
            length = struct.unpack(">Q", reader.read(8))[0]

        mask = reader.read(4) if masked else None
        payload = reader.read(length) if length else b""
        if mask:
            payload = bytes(byte ^ mask[i % 4] for i, byte in enumerate(payload))

        if opcode == 0x1:  # text frame
            for line in payload.decode(errors="replace").splitlines():
                if line.strip():
                    log(line.strip())
        elif opcode == 0x9:  # ping -> pong
            send_frame(sock, 0xA, payload)
        elif opcode == 0x8:  # close
            log("device closed the connection")
            return

    log("monitoring window elapsed")


def main():
    host = sys.argv[1] if len(sys.argv) > 1 else "192.168.10.1"
    duration = int(sys.argv[2]) if len(sys.argv) > 2 else 900
    try:
        monitor(host, duration)
    except KeyboardInterrupt:
        log("stopped")
    except Exception as exc:
        log(f"ERROR: {type(exc).__name__}: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
