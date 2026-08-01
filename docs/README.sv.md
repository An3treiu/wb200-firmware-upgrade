# WB200 firmware-uppdatering

**[English — fullständig guide](../README.md)** · **[Alla språk](../README.md#-languages)**

Uppdatera firmware på en HyFix WB200 (Wingbits ADS-B-station) från kommandoraden. Verifierat på riktig hårdvara: `2.0.33 → 2.0.51`.

> Kort guide. Den fullständiga referensen — hela endpoint-tabellen, offlineuppdatering till en bestämd version och samtliga fallgropar — finns i den [engelska README-filen](../README.md).

## Snabbstart

Byt ut `<IP>` (standard `192.168.10.1`), `<SN>` (serienummer) och `<TOKEN>`.

```bash
# 1. Läs status och hämta serienumret — ingen inloggning krävs
curl -s http://<IP>/action/devStatus

# 2. Logga in — lösenordet ÄR serienumret. Svaret är din token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Starta uppdateringen
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Eller låt skriptet sköta allt:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Förutsättningar

Läs `http://<IP>/action/devStatus` — öppet, utan inloggning — och kontrollera:

- `inupgrade` = `0`, annars pågår redan en uppdatering
- `wiredIP` = `ONLINE`, eller WiFi anslutet
- enheten har internetåtkomst

`minerStatus = MINING` är det starkaste beviset på internet, men det är **inget krav**. Inomhus, utan fri sikt mot himlen för antennen, lämnar minern aldrig läget `WAITING` — det är normalt och hindrar inte uppdateringen.

## Vad som händer

| Tid | Händelse |
|---|---|
| ~10 s | Firmware hittas på tillverkarens server |
| ~3–4 min | Laddas ner och skrivs — helt utan återkoppling |
| därefter | Enheten startar om av sig själv, anslutningar bryts |
| ~1 min | Online igen, `inupgrade` fortfarande `1` |
| några min | `inupgrade` blir `0` — klart |

> ⚠️ **Bryt inte strömmen och dra inte ur nätverkskabeln** medan uppdateringen pågår. Du riskerar att förstöra enheten.

## Bekräfta

```bash
curl -s http://<IP>/action/devStatus
```

Klart när `fwVer` visar den nya versionen **och** `inupgrade` = `0`.

Förloppet strömmas i realtid över WebSocket på `ws://<IP>:8080/mcm` — se [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Att anslutningen bryts betyder att firmware skrevs och att enheten startar om; det är inget fel.

## Fallgropar

- **`/action/debug_ping` tar en numerisk kod (`ping=2`), inte en IP-adress.** Med en IP svarar den `no ip / Get addr error`, vilket ser ut som «inget internet» men inte är det.
- **Versionens avskiljare ändras mellan releaser:** `WB200_v2.0.33` → `WB200-v2.0.51`. Jämför aldrig versionen mot en hårdkodad sträng.
- **`inupgrade` står kvar på `1`** i 2–3 minuter efter att enheten är online igen. Enheten kan starta om mer än en gång.
- **`health: WiFi is not connected!` är harmlöst** när du kör på Ethernet — enheten är accesspunkt och trådbunden klient samtidigt.
- **Du kan inte välja version online.** Tillverkarens server levererar alltid den senaste firmware. För en bestämd version, använd offlineuppdateringen som beskrivs i den engelska guiden.

## ⚠️ Säkerhet

`/action/devStatus` är öppen och avslöjar serienumret — som också är lösenordet. Sessionstoken är inget annat än `base64("user:" + SN)`. I praktiken: den som når enheten på nätverket kan konfigurera om eller flasha om den. Exponera **aldrig** minerns port 80 mot internet; håll den på ett betrott LAN.

## Licens

[MIT](../LICENSE) · Ingen koppling till HyFix, Wingbits eller GEODNET. Att flasha firmware innebär alltid en risk — på egen risk, på hårdvara du äger.
