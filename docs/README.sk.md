# Aktualizácia firmvéru WB200

**[English — kompletný návod](../README.md)** · **[Všetky jazyky](../README.md#-languages)**

Aktualizujte firmvér zariadenia HyFix WB200 (stanica ADS-B Wingbits) z príkazového riadka. Overené na skutočnom hardvéri: `2.0.33 → 2.0.51`.

> Stručný návod. Úplná referencia — celá tabuľka koncových bodov, offline aktualizácia na konkrétnu verziu a všetky nástrahy — je v [anglickom README](../README.md).

## Rýchly štart

Nahraďte `<IP>` (predvolene `192.168.10.1`), `<SN>` (sériové číslo) a `<TOKEN>`.

```bash
# 1. Načítajte stav a získajte sériové číslo — bez prihlásenia
curl -s http://<IP>/action/devStatus

# 2. Prihláste sa — heslom JE sériové číslo. Odpoveďou je váš token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Spustite aktualizáciu
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Alebo nechajte všetko na skript:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Predpoklady

Načítajte `http://<IP>/action/devStatus` — verejné, bez prihlásenia — a skontrolujte:

- `inupgrade` = `0`, inak už prebieha aktualizácia
- `wiredIP` = `ONLINE`, alebo pripojená WiFi
- zariadenie má prístup na internet

`minerStatus = MINING` je najsilnejší dôkaz pripojenia na internet, ale **nie je podmienkou**. V interiéri, bez voľného výhľadu antény na oblohu, ťažiar nikdy neopustí stav `WAITING` — je to normálne a aktualizácii to nebráni.

## Priebeh

| Čas | Udalosť |
|---|---|
| ~10 s | Firmvér nájdený na serveri výrobcu |
| ~3–4 min | Stiahnutý a zapísaný — úplne bez spätnej väzby |
| potom | Zariadenie sa samo reštartuje, spojenia sa prerušia |
| ~1 min | Opäť online, `inupgrade` stále `1` |
| pár min | `inupgrade` sa zmení na `0` — hotovo |

> ⚠️ **Počas aktualizácie neodpájajte napájanie ani sieťový kábel.** Riskujete trvalé znefunkčnenie zariadenia.

## Potvrdenie

```bash
curl -s http://<IP>/action/devStatus
```

Hotovo, keď `fwVer` zobrazuje novú verziu **a** `inupgrade` = `0`.

Priebeh sa prenáša naživo cez WebSocket na `ws://<IP>:8080/mcm` — pozri [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Prerušenie spojenia znamená, že firmvér bol zapísaný a zariadenie sa reštartuje; nie je to chyba.

## Nástrahy

- **`/action/debug_ping` očakáva číselný kód (`ping=2`), nie IP adresu.** S IP adresou odpovie `no ip / Get addr error`, čo vyzerá ako „bez internetu", ale nie je.
- **Oddeľovač vo verzii sa medzi vydaniami mení:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nikdy neporovnávajte verziu s natvrdo zapísaným reťazcom.
- **`inupgrade` zostáva na `1`** ešte 2–3 minúty po tom, čo je zariadenie späť online. Zariadenie sa môže reštartovať aj viackrát.
- **`health: WiFi is not connected!` je neškodné**, ak používate Ethernet — zariadenie je zároveň prístupový bod aj drôtový klient.
- **Verziu online zvoliť nemožno.** Server výrobcu vždy poskytne najnovší firmvér. Pre konkrétnu verziu použite offline aktualizáciu opísanú v anglickom návode.

## ⚠️ Bezpečnosť

`/action/devStatus` je verejný a prezrádza sériové číslo — ktoré je zároveň heslom. Token relácie nie je nič iné než `base64("user:" + SN)`. V praxi: ktokoľvek, kto sa k zariadeniu dostane v sieti, ho môže prekonfigurovať alebo preprogramovať. **Nikdy** nevystavujte port 80 ťažiara do internetu; ponechajte ho v dôveryhodnej sieti LAN.

## Licencia

[MIT](../LICENSE) · Bez akéhokoľvek prepojenia na HyFix, Wingbits či GEODNET. Zápis firmvéru so sebou nesie riziko — na vlastné riziko, na hardvéri, ktorý vlastníte.
