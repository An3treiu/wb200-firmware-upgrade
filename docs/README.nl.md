# WB200 firmware-update

**[English — volledige handleiding](../README.md)** · **[Alle talen](../README.md#-languages)**

Werk de firmware van een HyFix WB200 (Wingbits ADS-B-station) bij vanaf de opdrachtregel. Geverifieerd op echte hardware: `2.0.33 → 2.0.51`.

> Korte handleiding. De volledige referentie — complete endpoint-tabel, offline update naar een specifieke versie en alle valkuilen — staat in de [Engelse README](../README.md).

## Snel starten

Vervang `<IP>` (standaard `192.168.10.1`), `<SN>` (serienummer) en `<TOKEN>`.

```bash
# 1. Status lezen en het serienummer ophalen — zonder aanmelden
curl -s http://<IP>/action/devStatus

# 2. Aanmelden — het wachtwoord IS het serienummer. Het antwoord is je token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. De update starten
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Of laat het script alles doen:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Voorwaarden

Lees `http://<IP>/action/devStatus` — openbaar, zonder aanmelden — en controleer:

- `inupgrade` = `0`, anders loopt er al een update
- `wiredIP` = `ONLINE`, of WiFi verbonden
- het apparaat heeft internettoegang

`minerStatus = MINING` is het sterkste bewijs van internet, maar het is **geen vereiste**. Binnenshuis, zonder vrij zicht op de hemel voor de antenne, verlaat de miner de status `WAITING` nooit — dat is normaal en blokkeert de update niet.

## Wat er gebeurt

| Tijd | Gebeurtenis |
|---|---|
| ~10 s | Firmware gevonden op de server van de fabrikant |
| ~3–4 min | Gedownload en weggeschreven — zonder enige terugkoppeling |
| daarna | Het apparaat herstart uit zichzelf, verbindingen vallen weg |
| ~1 min | Weer online, `inupgrade` nog steeds `1` |
| enkele min | `inupgrade` wordt `0` — klaar |

> ⚠️ **Onderbreek de stroom niet en trek de netwerkkabel er niet uit** tijdens de update. Je riskeert het apparaat onbruikbaar te maken.

## Bevestigen

```bash
curl -s http://<IP>/action/devStatus
```

Klaar wanneer `fwVer` de nieuwe versie toont **en** `inupgrade` = `0`.

De voortgang wordt live doorgegeven via WebSocket op `ws://<IP>:8080/mcm` — zie [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Dat de verbinding wegvalt, betekent dat de firmware is weggeschreven en het apparaat herstart; het is geen fout.

## Valkuilen

- **`/action/debug_ping` verwacht een numerieke code (`ping=2`), geen IP-adres.** Met een IP antwoordt het `no ip / Get addr error`, wat op «geen internet» lijkt maar dat niet is.
- **Het scheidingsteken in de versie verandert tussen releases:** `WB200_v2.0.33` → `WB200-v2.0.51`. Vergelijk de versie nooit met een vaste tekenreeks.
- **`inupgrade` blijft nog 2–3 minuten op `1`** nadat het apparaat weer online is. Het kan meer dan één keer herstarten.
- **`health: WiFi is not connected!` is onschuldig** als je Ethernet gebruikt — het apparaat is tegelijk access point en bekabelde client.
- **Online kun je de versie niet kiezen.** De server van de fabrikant levert altijd de nieuwste firmware. Gebruik voor een specifieke versie de offline update uit de Engelse handleiding.

## ⚠️ Beveiliging

`/action/devStatus` is openbaar en toont het serienummer — dat tevens het wachtwoord is. Het sessietoken is niet meer dan `base64("user:" + SN)`. In de praktijk: wie het apparaat op het netwerk kan bereiken, kan het herconfigureren of opnieuw flashen. Stel poort 80 van de miner **nooit** bloot aan het internet; houd hem op een vertrouwd LAN.

## Licentie

[MIT](../LICENSE) · Geen enkele band met HyFix, Wingbits of GEODNET. Firmware flashen brengt risico's met zich mee — op eigen risico, op hardware die van jou is.
