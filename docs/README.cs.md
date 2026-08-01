# Aktualizace firmwaru WB200

**[English — kompletní návod](../README.md)** · **[Všechny jazyky](../README.md#-languages)**

Aktualizujte firmware zařízení HyFix WB200 (těžař GEODNET) z příkazové řádky. Ověřeno na skutečném hardwaru: `2.0.33 → 2.0.51`.

> Stručný návod. Úplná referenční příručka — celá tabulka koncových bodů, offline aktualizace na konkrétní verzi a všechny nástrahy — je v [anglickém README](../README.md).

## Rychlý start

Nahraďte `<IP>` (výchozí `192.168.10.1`), `<SN>` (sériové číslo) a `<TOKEN>`.

```bash
# 1. Načtěte stav a získejte sériové číslo — bez přihlášení
curl -s http://<IP>/action/devStatus

# 2. Přihlaste se — heslem JE sériové číslo. Odpovědí je váš token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Spusťte aktualizaci
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Nebo nechte všechno na skriptu:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Předpoklady

Načtěte `http://<IP>/action/devStatus` — veřejné, bez přihlášení — a zkontrolujte:

- `inupgrade` = `0`, jinak už aktualizace probíhá
- `wiredIP` = `ONLINE`, nebo připojená WiFi
- zařízení má přístup k internetu

`minerStatus = MINING` je nejsilnější důkaz připojení k internetu, ale **není podmínkou**. Uvnitř budovy, bez volného výhledu antény na oblohu, těžař nikdy neopustí stav `WAITING` — to je normální a aktualizaci to nebrání.

## Průběh

| Čas | Událost |
|---|---|
| ~10 s | Firmware nalezen na serveru výrobce |
| ~3–4 min | Stažen a zapsán — zcela bez zpětné vazby |
| poté | Zařízení se samo restartuje, spojení se přeruší |
| ~1 min | Opět online, `inupgrade` stále `1` |
| pár min | `inupgrade` přejde na `0` — hotovo |

> ⚠️ **Během aktualizace neodpojujte napájení ani síťový kabel.** Riskujete trvalé znefunkčnění zařízení.

## Potvrzení

```bash
curl -s http://<IP>/action/devStatus
```

Hotovo, když `fwVer` ukazuje novou verzi **a** `inupgrade` = `0`.

Průběh se přenáší živě přes WebSocket na `ws://<IP>:8080/mcm` — viz [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Přerušení spojení znamená, že firmware byl zapsán a zařízení se restartuje; není to chyba.

## Nástrahy

- **`/action/debug_ping` očekává číselný kód (`ping=2`), nikoli IP adresu.** S IP adresou odpoví `no ip / Get addr error`, což vypadá jako „bez internetu", ale není.
- **Oddělovač ve verzi se mezi vydáními mění:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nikdy neporovnávejte verzi s napevno zapsaným řetězcem.
- **`inupgrade` zůstává na `1`** ještě 2–3 minuty poté, co je zařízení zpět online. Zařízení se může restartovat i vícekrát.
- **`health: WiFi is not connected!` je neškodné**, pokud používáte Ethernet — zařízení je zároveň přístupový bod i drátový klient.
- **Verzi online zvolit nelze.** Server výrobce vždy poskytne nejnovější firmware. Pro konkrétní verzi použijte offline aktualizaci popsanou v anglickém návodu.

## ⚠️ Bezpečnost

`/action/devStatus` je veřejný a vyzrazuje sériové číslo — které je zároveň heslem. Token relace není nic jiného než `base64("user:" + SN)`. V praxi: kdokoli, kdo se k zařízení dostane v síti, jej může přenastavit nebo přeprogramovat. **Nikdy** nevystavujte port 80 těžaře do internetu; ponechte jej v důvěryhodné síti LAN.

## Licence

[MIT](../LICENSE) · Bez jakékoli vazby na HyFix či GEODNET. Zápis firmwaru s sebou nese riziko — na vlastní nebezpečí, na hardwaru, který vlastníte.
