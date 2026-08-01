# WB200 Firmware-Update

**[English — vollständige Anleitung](../README.md)** · **[Alle Sprachen](../README.md#-languages)**

Einen HyFix WB200 (GEODNET-Miner) über die Kommandozeile flashen. Auf echter Hardware verifiziert: `2.0.33 → 2.0.51`.

> Kurzanleitung. Die vollständige Referenz — komplette Endpunkt-Tabelle, Offline-Update für eine bestimmte Version und alle Stolperfallen — steht in der [englischen README](../README.md).

## Schnellstart

Ersetze `<IP>` (Standard `192.168.10.1`), `<SN>` (Seriennummer) und `<TOKEN>`.

```bash
# 1. Status lesen und Seriennummer holen — ohne Anmeldung
curl -s http://<IP>/action/devStatus

# 2. Anmelden — das Passwort IST die Seriennummer. Die Antwort ist dein Token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Update starten
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Oder das Skript erledigt alles:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Voraussetzungen

Lies `http://<IP>/action/devStatus` — öffentlich, ohne Anmeldung — und prüfe:

- `inupgrade` = `0`, sonst läuft bereits ein Update
- `wiredIP` = `ONLINE`, oder WLAN verbunden
- das Gerät hat Internetzugang

`minerStatus = MINING` ist der stärkste Beleg für Internet, aber **keine Voraussetzung**. In Innenräumen, ohne freie Sicht zum Himmel für die Antenne, verlässt der Miner den Zustand `WAITING` nie — das ist normal und verhindert das Update nicht.

## Ablauf

| Zeit | Ereignis |
|---|---|
| ~10 s | Firmware auf dem Herstellerserver gefunden |
| ~3–4 Min. | Heruntergeladen und geschrieben — ganz ohne Rückmeldung |
| danach | Das Gerät startet von selbst neu, Verbindungen brechen ab |
| ~1 Min. | Wieder online, `inupgrade` weiterhin `1` |
| einige Min. | `inupgrade` wird `0` — fertig |

> ⚠️ **Trenne während des Updates weder die Stromversorgung noch das Netzwerkkabel.** Du riskierst, das Gerät unbrauchbar zu machen.

## Abschluss prüfen

```bash
curl -s http://<IP>/action/devStatus
```

Fertig, wenn `fwVer` die neue Version zeigt **und** `inupgrade` = `0` ist.

Der Fortschritt wird live über WebSocket unter `ws://<IP>:8080/mcm` gestreamt — siehe [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Bricht die Verbindung ab, wurde die Firmware geschrieben und das Gerät startet neu; das ist kein Fehler.

## Stolperfallen

- **`/action/debug_ping` erwartet einen Zahlencode (`ping=2`), keine IP-Adresse.** Mit einer IP antwortet es `no ip / Get addr error`, was wie „kein Internet" aussieht, es aber nicht ist.
- **Das Trennzeichen der Version ändert sich zwischen Releases:** `WB200_v2.0.33` → `WB200-v2.0.51`. Vergleiche die Version niemals mit einer fest codierten Zeichenkette.
- **`inupgrade` bleibt noch 2–3 Minuten auf `1`**, nachdem das Gerät wieder online ist. Das Gerät kann mehrfach neu starten.
- **`health: WiFi is not connected!` ist harmlos**, wenn du Ethernet nutzt — das Gerät ist gleichzeitig Access Point und kabelgebundener Client.
- **Online lässt sich die Version nicht wählen.** Der Herstellerserver liefert immer die neueste Firmware. Für eine bestimmte Version nutze das Offline-Update aus der englischen Anleitung.

## ⚠️ Sicherheit

`/action/devStatus` ist öffentlich und gibt die Seriennummer preis — die zugleich das Passwort ist. Das Sitzungs-Token ist lediglich `base64("user:" + SN)`. Praktisch heißt das: Wer das Gerät im Netzwerk erreicht, kann es umkonfigurieren oder neu flashen. Gib Port 80 des Miners **niemals** ins Internet frei; halte ihn in einem vertrauenswürdigen LAN.

## Lizenz

[MIT](../LICENSE) · Keine Verbindung zu HyFix oder GEODNET. Firmware zu flashen birgt Risiken — Nutzung auf eigene Gefahr, auf Hardware, die dir gehört.
