#!/usr/bin/env bash
#
# Upgrade the firmware of a HyFix WB200 (GEODNET miner) over the network.
#
# Runs the whole chain by itself: reads the device status, extracts the serial
# number, logs in, verifies the preconditions, triggers the online upgrade and
# waits until the device has rebooted onto the new firmware.
#
# You never type a serial number or a token -- both are discovered at runtime.
# Only curl and standard shell tools are required (no jq).
#
# Usage:
#   ./upgrade-wb200.sh [IP] [--force]
#
# Examples:
#   ./upgrade-wb200.sh
#   ./upgrade-wb200.sh 192.168.1.50 --force
#
# WARNING: do NOT cut power or unplug the network cable while it runs.
# https://github.com/An3treiu/wb200-firmware-upgrade

set -uo pipefail

IP="192.168.10.1"
FORCE=0
TIMEOUT_MINUTES=20

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) IP="$arg" ;;
    esac
done

# Extract one string field from the device's JSON without needing jq.
json_field() {
    printf '%s' "$1" | grep -oE "\"$2\":\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

dev_status() {
    curl -s -m "${1:-10}" "http://$IP/action/devStatus" 2>/dev/null
}

# --- 1. Read status (this endpoint needs no authentication) -------------------
echo "Contacting device at $IP ..."
STATUS="$(dev_status 10)"
if [ -z "$STATUS" ]; then
    echo "ERROR: cannot reach the device at $IP. Check the cable/WiFi and the IP address." >&2
    exit 1
fi

SN="$(json_field "$STATUS" sn)"
OLD_VERSION="$(json_field "$STATUS" fwVer)"
INUPGRADE="$(json_field "$STATUS" inupgrade)"
MINER="$(json_field "$STATUS" minerStatus)"

echo
echo "Device      : $(json_field "$STATUS" devtype)  (hw $(json_field "$STATUS" hwVer))"
echo "Serial      : $SN"
echo "Firmware    : $OLD_VERSION"
echo "Network     : $(json_field "$STATUS" wiredIP)"
echo "Miner       : $MINER   NS: $(json_field "$STATUS" nsStatus)"
echo "Temperature : $(json_field "$STATUS" temp) C"
echo

# --- 2. Preconditions --------------------------------------------------------
if [ "$INUPGRADE" != "0" ]; then
    echo "ERROR: an upgrade is already running (inupgrade=$INUPGRADE). Wait for it to finish." >&2
    exit 1
fi

if [ "$MINER" != "MINING" ] && [ "$FORCE" -eq 0 ]; then
    echo "WARNING: miner is '$MINER', not 'MINING'."
    echo "         If the unit is indoors / on a bench with no GPS fix, this is expected and the"
    echo "         upgrade will still work, as long as the device has internet."
    echo "         Mining needs a fix; flashing does not."
    echo "         If this unit is deployed and should be mining, check its connection first."
    read -r -p "Continue anyway? (y/N) " answer
    case "$answer" in [yY]*) ;; *) echo "Aborted."; exit 0 ;; esac
fi

if [ "$FORCE" -eq 0 ]; then
    echo "This will FLASH the device firmware. Do not cut power during the process."
    read -r -p "Start the upgrade? (y/N) " answer
    case "$answer" in [yY]*) ;; *) echo "Aborted."; exit 0 ;; esac
fi

# --- 3. Log in (the password IS the serial number) ---------------------------
echo "Logging in ..."
TOKEN="$(curl -s -m 10 -X POST "http://$IP/action/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "mkey=$SN")"

if [ -z "$TOKEN" ]; then
    echo "ERROR: login failed (empty token)." >&2
    exit 1
fi
echo "Authenticated."

# --- 4. Trigger the online upgrade -------------------------------------------
RESULT="$(curl -s -m 30 -X POST "http://$IP/action/ota_online" \
    -b "USER=$TOKEN" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "protocol=ftp")"

echo
echo "Upgrade command sent. Device replied: $RESULT"
echo "DO NOT cut power and DO NOT unplug the network cable."
echo "The device will download the firmware, flash it and reboot on its own."
echo

# --- 5. Wait for completion --------------------------------------------------
# The device goes offline mid-flash, so failed requests here are expected and
# must not abort the loop. Compare against the version read *before* the upgrade
# rather than a hardcoded string: the separator changed between releases
# (WB200_v2.0.33 -> WB200-v2.0.51), so a fixed pattern would silently fail.
ATTEMPTS=$(( TIMEOUT_MINUTES * 6 ))
WAS_OFFLINE=0

for _ in $(seq 1 "$ATTEMPTS"); do
    sleep 10
    CUR="$(dev_status 5)"

    if [ -z "$CUR" ]; then
        if [ "$WAS_OFFLINE" -eq 0 ]; then
            echo "$(date +%H:%M:%S)  device offline - rebooting, this is expected ..."
            WAS_OFFLINE=1
        fi
        continue
    fi

    if [ "$WAS_OFFLINE" -eq 1 ]; then
        echo "Device is back online."
        WAS_OFFLINE=0
    fi

    VER="$(json_field "$CUR" fwVer)"
    UPG="$(json_field "$CUR" inupgrade)"
    MST="$(json_field "$CUR" minerStatus)"
    echo "$(date +%H:%M:%S)  ver=$VER  inupgrade=$UPG  miner=$MST"

    if [ "$UPG" = "0" ] && [ "$VER" != "$OLD_VERSION" ]; then
        echo
        echo "SUCCESS: $OLD_VERSION  ->  $VER"
        if [ "$MST" != "MINING" ]; then
            echo "Miner is '$MST' and GPS reports '$(json_field "$CUR" gps)'."
            echo "The firmware upgrade is complete regardless. Mining resumes once the antenna"
            echo "regains a fix - which never happens indoors, and that is fine."
        fi
        exit 0
    fi
done

echo "WARNING: timed out after $TIMEOUT_MINUTES minutes. The device may still be finishing." >&2
echo "Check manually:  curl -s http://$IP/action/devStatus" >&2
exit 1
