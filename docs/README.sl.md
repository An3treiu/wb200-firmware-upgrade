# Nadgradnja vdelane programske opreme WB200

**[English — celoten vodnik](../README.md)** · **[Vsi jeziki](../README.md#-languages)**

Nadgradite vdelano programsko opremo naprave HyFix WB200 (rudar GEODNET) iz ukazne vrstice. Preverjeno na resnični strojni opremi: `2.0.33 → 2.0.51`.

> Kratek vodnik. Celotna referenca — celotna tabela končnih točk, nespletna nadgradnja na določeno različico in vse pasti — je v [angleškem README](../README.md).

## Hitri začetek

Zamenjajte `<IP>` (privzeto `192.168.10.1`), `<SN>` (serijska številka) in `<TOKEN>`.

```bash
# 1. Preberite stanje in pridobite serijsko številko — brez prijave
curl -s http://<IP>/action/devStatus

# 2. Prijavite se — geslo JE serijska številka. Odgovor je vaš žeton
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Zaženite nadgradnjo
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Ali pa vse prepustite skriptu:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Predpogoji

Preberite `http://<IP>/action/devStatus` — javno, brez prijave — in preverite:

- `inupgrade` = `0`, sicer nadgradnja že poteka
- `wiredIP` = `ONLINE`, ali povezan WiFi
- naprava ima dostop do interneta

`minerStatus = MINING` je najmočnejši dokaz dostopa do interneta, vendar **ni pogoj**. V zaprtih prostorih, brez prostega pogleda antene na nebo, rudar nikoli ne zapusti stanja `WAITING` — to je običajno in nadgradnje ne ovira.

## Kaj se dogaja

| Čas | Dogodek |
|---|---|
| ~10 s | Programska oprema najdena na strežniku proizvajalca |
| ~3–4 min | Prenesena in zapisana — brez kakršne koli povratne informacije |
| nato | Naprava se sama znova zažene, povezave se prekinejo |
| ~1 min | Spet na spletu, `inupgrade` še vedno `1` |
| nekaj min | `inupgrade` postane `0` — končano |

> ⚠️ **Med nadgradnjo ne prekinjajte napajanja in ne izklapljajte omrežnega kabla.** Tvegate trajno okvaro naprave.

## Potrditev

```bash
curl -s http://<IP>/action/devStatus
```

Končano je, ko `fwVer` prikazuje novo različico **in** je `inupgrade` = `0`.

Napredek se v živo prenaša prek WebSocketa na `ws://<IP>:8080/mcm` — glejte [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Prekinitev povezave pomeni, da je bila programska oprema zapisana in se naprava znova zaganja; to ni napaka.

## Pasti

- **`/action/debug_ping` sprejme številčno kodo (`ping=2`), ne naslova IP.** Z naslovom IP odgovori `no ip / Get addr error`, kar je videti kot »ni interneta«, a ni res.
- **Ločilo v različici se med izdajami spremeni:** `WB200_v2.0.33` → `WB200-v2.0.51`. Različice nikoli ne primerjajte s trdo zapisanim nizom.
- **`inupgrade` ostane `1`** še 2–3 minute po tem, ko je naprava spet na spletu. Naprava se lahko znova zažene večkrat.
- **`health: WiFi is not connected!` je neškodljivo**, kadar uporabljate Ethernet — naprava je hkrati dostopna točka in žični odjemalec.
- **Različice na spletu ne morete izbrati.** Strežnik proizvajalca vedno postreže najnovejšo programsko opremo. Za določeno različico uporabite nespletno nadgradnjo, opisano v angleškem vodniku.

## ⚠️ Varnost

`/action/devStatus` je javen in razkriva serijsko številko — ki je hkrati geslo. Žeton seje ni nič drugega kot `base64("user:" + SN)`. V praksi: kdor koli doseže napravo v omrežju, jo lahko prekonfigurira ali znova zapiše. Vrat 80 rudarja **nikoli** ne izpostavljajte internetu; obdržite ga v zaupanja vrednem lokalnem omrežju.

## Licenca

[MIT](../LICENSE) · Brez kakršne koli povezave s HyFix ali GEODNET. Zapisovanje vdelane programske opreme prinaša tveganje — na lastno odgovornost, na strojni opremi, ki je vaša.
