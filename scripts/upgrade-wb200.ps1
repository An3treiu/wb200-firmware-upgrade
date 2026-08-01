<#
.SYNOPSIS
    Upgrades the firmware of a HyFix WB200 (Wingbits ADS-B station) over the network.

.DESCRIPTION
    Runs the whole chain by itself: reads the device status, extracts the serial
    number, logs in, verifies the preconditions, triggers the online upgrade and
    waits until the device has rebooted onto the new firmware.

    You never type a serial number or a token -- both are discovered at runtime.

.PARAMETER Ip
    Device address. Defaults to 192.168.10.1 (the address in access-point mode).

.PARAMETER TimeoutMinutes
    How long to wait for the upgrade to complete. Default 20.

.PARAMETER Force
    Skip the confirmation prompt and start the upgrade immediately.

.EXAMPLE
    .\upgrade-wb200.ps1
    .\upgrade-wb200.ps1 -Ip 192.168.1.50 -Force

.NOTES
    Do NOT cut power or unplug the network cable while the upgrade is running.
    https://github.com/An3treiu/wb200-firmware-upgrade
#>
[CmdletBinding()]
param(
    [string]$Ip = "192.168.10.1",
    [int]$TimeoutMinutes = 20,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-DevStatus {
    param([int]$TimeoutSec = 10)
    Invoke-RestMethod "http://$Ip/action/devStatus" -TimeoutSec $TimeoutSec
}

# --- 1. Read status (this endpoint needs no authentication) -------------------
Write-Host "Contacting device at $Ip ..." -ForegroundColor Cyan
try {
    $dev = Get-DevStatus
} catch {
    throw "Cannot reach the device at $Ip. Check the cable/WiFi and the IP address. ($_)"
}

$oldVersion = $dev.fwVer
Write-Host ""
Write-Host "Device      : $($dev.devtype)  (hw $($dev.hwVer))"
Write-Host "Serial      : $($dev.sn)"
Write-Host "Firmware    : $oldVersion"
Write-Host "Network     : $($dev.wiredIP)"
Write-Host "Miner       : $($dev.minerStatus)   NS: $($dev.nsStatus)"
Write-Host "Temperature : $($dev.temp) C"
Write-Host ""

# --- 2. Preconditions --------------------------------------------------------
if ($dev.inupgrade -ne "0") {
    throw "An upgrade is already running on this device (inupgrade=$($dev.inupgrade)). Wait for it to finish."
}

if ($dev.minerStatus -ne "MINING") {
    Write-Warning "Miner is '$($dev.minerStatus)', not 'MINING'."
    Write-Warning "If the unit is indoors / on a bench with no GPS fix, this is expected and the upgrade"
    Write-Warning "will still work, as long as the device has internet. Mining needs a fix; flashing does not."
    Write-Warning "If this unit is deployed and should be mining, check its connection first."
    if (-not $Force) {
        $answer = Read-Host "Continue anyway? (y/N)"
        if ($answer -notmatch '^[yY]') { Write-Host "Aborted."; return }
    }
}

if (-not $Force) {
    Write-Host "This will FLASH the device firmware. Do not cut power during the process." -ForegroundColor Yellow
    $answer = Read-Host "Start the upgrade? (y/N)"
    if ($answer -notmatch '^[yY]') { Write-Host "Aborted."; return }
}

# --- 3. Log in (the password IS the serial number) ---------------------------
Write-Host "Logging in ..." -ForegroundColor Cyan
# The device terminates the token with a newline. System.Net.Cookie rejects any
# value containing one ("the 'Value' part of the cookie is invalid"), so trim
# before building the cookie.
$token = ([string](Invoke-RestMethod "http://$Ip/action/login" -Method Post `
    -ContentType "application/x-www-form-urlencoded" -Body "mkey=$($dev.sn)")).Trim()

if ([string]::IsNullOrWhiteSpace($token)) {
    throw "Login failed: the device returned an empty token for serial $($dev.sn)."
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.Cookies.Add((New-Object System.Net.Cookie("USER", $token, "/", $Ip)))
Write-Host "Authenticated." -ForegroundColor Green

# --- 4. Trigger the online upgrade -------------------------------------------
$result = Invoke-RestMethod "http://$Ip/action/ota_online" -Method Post -WebSession $session `
    -ContentType "application/x-www-form-urlencoded" -Body "protocol=ftp"

Write-Host ""
Write-Host "Upgrade command sent. Device replied: $result" -ForegroundColor Green
Write-Host "DO NOT cut power and DO NOT unplug the network cable." -ForegroundColor Yellow
Write-Host "The device will download the firmware, flash it and reboot on its own." -ForegroundColor Yellow
Write-Host ""

# --- 5. Wait for completion --------------------------------------------------
# The device goes offline mid-flash, so connection errors here are expected and
# must not abort the loop. Compare against the version read *before* the upgrade
# rather than a hardcoded string: the separator changed between releases
# (WB200_v2.0.33 -> WB200-v2.0.51), so a fixed pattern would silently fail.
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$wasOffline = $false

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    try {
        $cur = Get-DevStatus -TimeoutSec 5
        if ($wasOffline) { Write-Host "Device is back online." -ForegroundColor Green; $wasOffline = $false }
        "{0}  ver={1}  inupgrade={2}  miner={3}" -f (Get-Date -Format HH:mm:ss), $cur.fwVer, $cur.inupgrade, $cur.minerStatus

        if ($cur.inupgrade -eq "0" -and $cur.fwVer -ne $oldVersion) {
            Write-Host ""
            Write-Host "SUCCESS: $oldVersion  ->  $($cur.fwVer)" -ForegroundColor Green
            if ($cur.minerStatus -ne "MINING") {
                Write-Host "Miner is '$($cur.minerStatus)' and GPS reports '$($cur.gps)'." -ForegroundColor Yellow
                Write-Host "The firmware upgrade is complete regardless. Mining resumes once the antenna" -ForegroundColor Yellow
                Write-Host "regains a fix - which never happens indoors, and that is fine." -ForegroundColor Yellow
            }
            return
        }
    } catch {
        if (-not $wasOffline) {
            "{0}  device offline - rebooting, this is expected ..." -f (Get-Date -Format HH:mm:ss)
            $wasOffline = $true
        }
    }
}

Write-Warning "Timed out after $TimeoutMinutes minutes. The device may still be finishing."
Write-Warning "Check manually:  curl -s http://$Ip/action/devStatus"
