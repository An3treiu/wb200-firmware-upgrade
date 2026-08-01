<div align="center">

# WB200 Firmware Upgrade

**Flash a HyFix WB200 GEODNET miner from the command line — no clicking through the web UI.**

[![CI](https://github.com/An3treiu/wb200-firmware-upgrade/actions/workflows/ci.yml/badge.svg)](https://github.com/An3treiu/wb200-firmware-upgrade/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-0078D6)](#scripts)
[![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#scripts)
[![Verified on hardware](https://img.shields.io/badge/verified-WB200%20hw__v1.0-success)](#disclaimer)
[![Docs](https://img.shields.io/badge/docs-25%20languages-informational)](#-languages)

</div>

---

Everything here was reverse-engineered from the device's own web interface and **verified on real hardware** — a successful `2.0.33 → 2.0.51` upgrade. No proprietary files, no patched firmware: these are the same HTTP calls the official web UI makes.

| | |
|---|---|
| 🔌 **Zero install** | `curl` is all you need. Ships with Windows 10/11, Linux and macOS |
| ⚡ **One command** | The scripts discover the serial, log in, flash and wait for the reboot |
| 📡 **Live progress** | WebSocket monitor in 200 lines of Python standard library |
| 🧯 **Field-tested** | Every gotcha below cost real time to find — including the two that make a working device look broken |

## 🌍 Languages

Full guide in **English** (this page) and **Romanian**. Short guides — quick start, preconditions, progress, gotchas and the security note — in every other official EU language, plus Arabic.

| | | | | |
|---|---|---|---|---|
| 🇬🇧 [English](README.md) | 🇷🇴 [Română](README.ro.md) | 🇧🇬 [Български](docs/README.bg.md) | 🇨🇿 [Čeština](docs/README.cs.md) | 🇩🇰 [Dansk](docs/README.da.md) |
| 🇩🇪 [Deutsch](docs/README.de.md) | 🇪🇪 [Eesti](docs/README.et.md) | 🇬🇷 [Ελληνικά](docs/README.el.md) | 🇪🇸 [Español](docs/README.es.md) | 🇫🇷 [Français](docs/README.fr.md) |
| 🇮🇪 [Gaeilge](docs/README.ga.md) | 🇭🇷 [Hrvatski](docs/README.hr.md) | 🇮🇹 [Italiano](docs/README.it.md) | 🇱🇻 [Latviešu](docs/README.lv.md) | 🇱🇹 [Lietuvių](docs/README.lt.md) |
| 🇭🇺 [Magyar](docs/README.hu.md) | 🇲🇹 [Malti](docs/README.mt.md) | 🇳🇱 [Nederlands](docs/README.nl.md) | 🇵🇱 [Polski](docs/README.pl.md) | 🇵🇹 [Português](docs/README.pt.md) |
| 🇸🇰 [Slovenčina](docs/README.sk.md) | 🇸🇮 [Slovenščina](docs/README.sl.md) | 🇫🇮 [Suomi](docs/README.fi.md) | 🇸🇪 [Svenska](docs/README.sv.md) | 🇸🇦 [العربية](docs/README.ar.md) |

---

## TL;DR — three commands

```bash
# 1. Read status, get the serial number (no login needed)
curl -s http://<IP>/action/devStatus

# 2. Log in — the password IS the serial number. Response = your token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Start the online upgrade
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Wait 5–8 minutes, then re-run step 1 to confirm.

**Or just run the script** — it does all of the above by itself:

```powershell
.\scripts\upgrade-wb200.ps1 -Ip 192.168.10.1     # Windows
```
```bash
./scripts/upgrade-wb200.sh 192.168.10.1          # Linux / macOS / Git Bash
```

---

## Placeholders used in this guide

| Placeholder | Meaning | How you get it |
|---|---|---|
| `<IP>` | Device address | Default `192.168.10.1` in AP mode — see [Step 1](#step-1--find-the-device) |
| `<SN>` | Serial number, 12 alphanumeric chars | From `devStatus` — see [Step 2](#step-2--read-status-and-get-the-serial-number) |
| `<TOKEN>` | Session token | Returned by `login` — see [Step 3](#step-3--log-in) |

> **Windows CMD users:** use double quotes `"` only. Single quotes `'` do not work in CMD.
> `curl.exe` ships with Windows 10/11, so no install is needed.

---

## Step 1 — Find the device

The WB200 is reachable in several ways, most reliable first:

1. **Direct cable to your PC, or its own WiFi access point.** The device is then always at `192.168.10.1`.

   ```bash
   ping 192.168.10.1
   ```
   ```cmd
   ipconfig | findstr /C:"192.168.10"
   ```
   You should see your PC on `192.168.10.x` with default gateway `192.168.10.1`.

2. **mDNS hostname**, if it is on the same network as your PC:

   ```bash
   ping wb200_XXXXXX.local
   ```
   `XXXXXX` matches the label on the device / the WiFi network it broadcasts.

3. **DHCP address from your router** — look it up in the router's client list, or read the `wiredIP` field in Step 2.

---

## Step 2 — Read status and get the serial number

```bash
curl -s http://<IP>/action/devStatus
```

This endpoint is **public — no authentication required.** It returns JSON:

| Field | Meaning |
|---|---|
| `sn` | Serial number — **this is also the login password** |
| `fwVer` | Installed firmware version, e.g. `WB200_v2.0.33` |
| `inupgrade` | `0` = idle, `1` = an upgrade is already running |
| `wiredIP` | `ONLINE,<ip>` when the Ethernet cable is up |
| `minerStatus` | `MINING` — the real proof the device has **internet** |
| `nsStatus` | `TRANSMITTING` — sending data to the caster |
| `gps` | GNSS fix state |
| `temp` | Temperature in °C |

### Preconditions — before upgrading

- [ ] `inupgrade` = `0` — otherwise an upgrade is already in progress, **do not start another**
- [ ] `wiredIP` = `ONLINE` (or WiFi connected)
- [ ] The device has **internet access** — the online upgrade downloads firmware from the vendor's server

> **How to judge internet access.** `minerStatus = MINING` is the strongest confirmation, since mining requires a live connection to the caster. But it is **not a requirement for upgrading** — see [Bench and indoor upgrades](#bench-and-indoor-upgrades). If the device pulled a DHCP address from a router that has internet, you are fine.

### Bench and indoor upgrades

If you are updating units **indoors** — on a desk, with no antenna sky view — the device will *never* reach `MINING`. It sits at:

```
minerStatus = WAITING
nsStatus    = SOCKET-CONNECTING
gps         = Waiting for GPS Fix
```

This is expected and does **not** block a firmware upgrade. Mining needs a GPS fix; downloading and flashing firmware does not.

In this workflow, judge the result by two fields only:

```
fwVer     = the new version
inupgrade = 0
```

Use `-Force` / `--force` to skip the interactive warning when flashing several units in a row.

PowerShell one-liner for just the essentials:

```powershell
$s = Invoke-RestMethod http://<IP>/action/devStatus
$s.fwVer; $s.sn; $s.inupgrade; $s.minerStatus
```

---

## Step 3 — Log in

**The device password is its serial number**, which you read in Step 2.

```bash
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"
```

The response body *is* the token. Send it back as a cookie: `-b "USER=<TOKEN>"`.

The token is nothing more than base64 of the string `user:<SN>`, so you can compute it offline:

```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("user:<SN>"))
```
```bash
printf 'user:%s' "<SN>" | base64
```

---

## Step 4 — Start the online upgrade

> ⚠️ **This is the command that flashes the device.**

```bash
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Expected response: `OK`

What happens next, automatically:

| Time | What happens |
|---|---|
| ~10 s | Device locates the firmware on the vendor's FTP server |
| ~3–4 min | Downloads and writes it — **no HTTP feedback during this** |
| then | **Reboots by itself** — all connections drop abruptly. This is normal. |
| ~1 min | Comes back online on the new version, but `inupgrade` is still `1` |
| a few more min | `inupgrade` flips to `0`, then the miner returns to `MINING` (needs a GPS fix first) |

> 🚨 **Do not cut power and do not unplug the network cable** during this window. You risk bricking the device.

---

## Step 5 — Track progress

### Simple — poll the status endpoint

```bash
curl -s http://<IP>/action/devStatus
```

### Automatic — PowerShell loop

Replace `<IP>` and `<OLD_VERSION>` (e.g. `2.0.33`):

```powershell
while ($true) {
  try {
    $s = Invoke-RestMethod http://<IP>/action/devStatus -TimeoutSec 5
    "{0}  ver={1}  inupgrade={2}  miner={3}" -f (Get-Date -f HH:mm:ss), $s.fwVer, $s.inupgrade, $s.minerStatus
    if ($s.inupgrade -eq "0" -and $s.fwVer -notlike "*<OLD_VERSION>*") { "DONE!"; break }
  } catch { "{0}  OFFLINE (rebooting...)" -f (Get-Date -f HH:mm:ss) }
  Start-Sleep 10
}
```

### Real-time — WebSocket

The web UI streams progress over a WebSocket, and so can you:

```
ws://<IP>:8080/mcm
```

| Message prefix | Meaning |
|---|---|
| `APPOTA:ONLINE:` | Status text, e.g. `Found firmware vX.Y.Z` |
| `APPOTA:UPLOAD:NN` | File upload percentage (offline upgrade only) |
| `APPOTA:UPGRADE:NN` | Firmware write percentage |
| `GNSSOTA:UPLOAD/UPGRADE:NN` | Same, for the GNSS module |

A dependency-free listener is included — [`scripts/ws-monitor.py`](scripts/ws-monitor.py):

```bash
python scripts/ws-monitor.py 192.168.10.1
```

The WebSocket **dropping is the signal that the flash was applied** and the device is rebooting — not an error.

---

## Step 6 — Confirm completion

```bash
curl -s http://<IP>/action/devStatus
```

The **upgrade itself** is finished when both of these hold:

```
fwVer     = the new version
inupgrade = 0
```

For a **deployed miner** with antenna sky view, full service is back when it also reaches:

```
minerStatus = MINING
nsStatus    = TRANSMITTING
```

If the miner sits in `WAITING` with `gps: Waiting for GPS Fix`, nothing is broken — the antenna simply has no fix yet. That is normal for a few minutes after any reboot, and permanent if you are working indoors. See [Bench and indoor upgrades](#bench-and-indoor-upgrades).

---

## Installing a *specific* version (offline upgrade)

> **You cannot pick the version with the online upgrade.** The request only carries `protocol=ftp`; the vendor's server decides which firmware to serve — always the newest one. Asking for an older or intermediate release still gets you the latest.

For a fixed version you need the `.bin` file and the offline endpoint:

```bash
curl -s -X POST http://<IP>/action/ota_app -b "USER=<TOKEN>" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@/path/to/firmware.bin"
```

Constraints:

- The file must be **under 100 MB** (enforced by the device)
- The web UI uploads it in chunks; if a single POST fails, use the web UI: **Firmware Upgrade → Upgrade Offline**
- GNSS module firmware is separate, on `/action/ota_gnss`. The on-board module expects **5 files**: DA, Partition Table, Bootloader, Firmware, Configuration

---

## Gotchas — verified the hard way

**`/action/debug_ping` does not take an IP address.** It takes a numeric code (`ping=2`). Passing an IP returns `no ip / Get addr error`, which looks exactly like "the device has no internet" — a false conclusion. The correct internet check is `minerStatus = MINING`.

**`"health":"WiFi is not connected!"` is not a problem** when you are on Ethernet. The device is simultaneously an access point (`192.168.10.1`) and a wired client.

**The version-string separator can change between firmware releases:**

```
WB200_v2.0.33   (underscore)   →   WB200-v2.0.51   (hyphen)
```

Never compare versions against a hardcoded string — parse the numeric part, or compare against the value you read *before* the upgrade.

**`inupgrade` stays `1` for another 2–3 minutes after the device is back online.** Only `inupgrade=0` means finished. The device may reboot more than once — don't panic.

**The web server is GoAhead** (a classic embedded HTTP server). `/action/*` routes are C handlers compiled into the firmware, not files — there is nothing to find on disk.

---

## ⚠️ Security note

`/action/devStatus` is **public, unauthenticated, and exposes the serial number** — which is also the password. The session token is just `base64("user:" + SN)`, with no secret, nonce, or expiry.

In practice: **anyone who can reach the device on the network can reconfigure or reflash it.**

This is fine on an isolated LAN, and it is what makes the automation in this repo possible. It is *not* fine on a public interface.

- **Never** port-forward the miner's port 80 to the internet
- **Never** put it on an untrusted/guest network
- Keep it on a trusted LAN or a dedicated VLAN

---

## Endpoint reference

Extracted from the device's own web interface. All require the `USER` cookie **except** `/action/devStatus`.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/action/devStatus` | Full status — **public, no login** |
| POST | `/action/login` | `mkey=<SN>` → token |
| POST | `/action/ota_online` | `protocol=ftp` → online upgrade |
| POST | `/action/ota_app` | Upload main firmware (offline) |
| POST | `/action/ota_gnss` | Upload GNSS module firmware |
| GET | `/action/gnssotamode` | GNSS OTA mode |
| POST | `/action/config_wifi` | WiFi configuration |
| POST | `/action/config_mk` | Miner key configuration |
| POST | `/action/config_mi` | Miner configuration |
| POST | `/action/config_led` | LED configuration |
| POST | `/action/config_adsb` | ADS-B configuration |
| POST | `/action/config_graph` | Charts configuration |
| POST | `/action/config_madmin` | Admin configuration |
| POST | `/action/debug_ping` | Network test (`ping=2`) |
| POST | `/action/debug_rtcmd` | RTK / diagnostic command |
| GET | `/action/netHistory` | Network history |
| GET | `/action/downfile` | File download |
| GET | `/action/start_down` | Start download |
| WS | `ws://<IP>:8080/mcm` | Real-time event stream |

---

## Scripts

| File | What it does |
|---|---|
| [`scripts/upgrade-wb200.ps1`](scripts/upgrade-wb200.ps1) | Full PowerShell automation: reads the SN, logs in, checks preconditions, upgrades, waits for completion |
| [`scripts/upgrade-wb200.sh`](scripts/upgrade-wb200.sh) | Same flow in bash + curl (Linux / macOS / Git Bash). No `jq` required |
| [`scripts/ws-monitor.py`](scripts/ws-monitor.py) | Dependency-free WebSocket listener for live OTA progress (stdlib only) |

---

## Disclaimer

Not affiliated with HyFix or GEODNET. Flashing firmware always carries risk — a power cut mid-write can brick the device. Use at your own risk, on hardware you own.

Verified on: **WB200, hw_v1.0**, upgrade `WB200_v2.0.33 → WB200-v2.0.51`.

Corrections and results from other hardware revisions are welcome — please open an issue or a PR.

## License

[MIT](LICENSE)
