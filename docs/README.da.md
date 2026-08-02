# WB200 firmwareopdatering

**[English — komplet vejledning](../README.md)** · **[Alle sprog](../README.md#-languages)**

Opdater firmwaren på en HyFix WB200 (Wingbits ADS-B-station) fra kommandolinjen. Verificeret på rigtig hardware: `2.0.33 → 2.0.51`.

> Kort vejledning. Den fulde reference — hele endpoint-tabellen, offlineopdatering til en bestemt version og alle faldgruber — findes i den [engelske README](../README.md).

## Hurtig start

Erstat `<IP>` (standard `192.168.10.1`), `<SN>` (serienummer) og `<TOKEN>`.

```bash
# 1. Læs status og hent serienummeret — ingen login nødvendig
curl -s http://<IP>/action/devStatus

# 2. Log ind — adgangskoden ER serienummeret. Svaret er dit token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Start opdateringen
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Eller lad scriptet klare det hele:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Forudsætninger

Læs `http://<IP>/action/devStatus` — offentligt, uden login — og kontrollér:

- `inupgrade` = `0`, ellers kører der allerede en opdatering
- `wiredIP` = `ONLINE`, eller WiFi tilsluttet
- enheden har internetadgang

`minerStatus = MINING` er det stærkeste bevis på internet, men det er **ikke et krav**. Indendørs, uden frit udsyn til himlen for antennen, forlader mineren aldrig tilstanden `WAITING` — det er normalt og blokerer ikke opdateringen.

## Sådan forløber det

| Tid | Hændelse |
|---|---|
| ~10 s | Firmware fundet på producentens server |
| ~3–4 min | Hentet og skrevet — helt uden tilbagemelding |
| derefter | Enheden genstarter af sig selv, forbindelser falder ud |
| ~1 min | Online igen, `inupgrade` stadig `1` |
| et par min | `inupgrade` bliver `0` — færdig |

> ⚠️ **Afbryd ikke strømmen, og træk ikke netværkskablet ud** under opdateringen. Du risikerer at ødelægge enheden.

## Bekræftelse

```bash
curl -s http://<IP>/action/devStatus
```

Færdig, når `fwVer` viser den nye version **og** `inupgrade` = `0`.

Fremdriften streames live over WebSocket på `ws://<IP>:8080/mcm` — se [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). At forbindelsen falder ud betyder, at firmwaren blev skrevet, og at enheden genstarter; det er ikke en fejl.

## Faldgruber

- **`/action/debug_ping` tager en talkode (`ping=2`), ikke en IP-adresse.** Med en IP svarer den `no ip / Get addr error`, hvilket ligner «intet internet», men ikke er det.
- **Versionens adskillelsestegn ændrer sig mellem udgivelser:** `WB200_v2.0.33` → `WB200-v2.0.51`. Sammenlign aldrig versionen med en hårdkodet tekststreng.
- **`inupgrade` bliver på `1`** i 2–3 minutter efter at enheden er online igen. Enheden kan genstarte mere end én gang.
- **`health: WiFi is not connected!` er harmløst**, når du bruger Ethernet — enheden er både accesspunkt og kabelforbundet klient.
- **Du kan ikke vælge version online.** Producentens server leverer altid den nyeste firmware. Brug offlineopdateringen fra den engelske vejledning til en bestemt version.

## ⚠️ Sikkerhed

`/action/devStatus` er offentlig og afslører serienummeret — som samtidig er adgangskoden. Sessionstokenet er blot `base64("user:" + SN)`. I praksis: enhver, der kan nå enheden på netværket, kan omkonfigurere eller genflashe den. Eksponer **aldrig** minerens port 80 mod internettet; hold den på et betroet LAN.

## Licens

[MIT](../LICENSE) · Ingen tilknytning til HyFix, Wingbits eller GEODNET. At flashe firmware indebærer risiko — på eget ansvar, på hardware du selv ejer.
