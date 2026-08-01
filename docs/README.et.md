# WB200 püsivara uuendamine

**[English — täielik juhend](../README.md)** · **[Kõik keeled](../README.md#-languages)**

Uuenda HyFix WB200 (GEODNET-i kaevur) püsivara käsurealt. Kontrollitud päris riistvaral: `2.0.33 → 2.0.51`.

> Lühijuhend. Täielik ülevaade — kogu lõpp-punktide tabel, võrguväline uuendamine kindlale versioonile ja kõik lõksud — on [ingliskeelses README-s](../README.md).

## Kiire algus

Asenda `<IP>` (vaikimisi `192.168.10.1`), `<SN>` (seerianumber) ja `<TOKEN>`.

```bash
# 1. Loe olek ja hangi seerianumber — sisselogimiseta
curl -s http://<IP>/action/devStatus

# 2. Logi sisse — parool ONGI seerianumber. Vastus on sinu luba
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Käivita uuendus
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Või lase skriptil kõik ära teha:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Eeldused

Loe `http://<IP>/action/devStatus` — avalik, sisselogimiseta — ja kontrolli:

- `inupgrade` = `0`, muidu on uuendus juba käimas
- `wiredIP` = `ONLINE`, või WiFi ühendatud
- seadmel on internetiühendus

`minerStatus = MINING` on kõige tugevam tõend internetiühendusest, kuid see **ei ole nõue**. Siseruumis, kus antennil puudub vaba vaade taevale, ei välju kaevur kunagi olekust `WAITING` — see on normaalne ega takista uuendamist.

## Mis toimub

| Aeg | Sündmus |
|---|---|
| ~10 s | Püsivara leitud tootja serverist |
| ~3–4 min | Alla laaditud ja kirjutatud — ilma igasuguse tagasisideta |
| seejärel | Seade taaskäivitub ise, ühendused katkevad |
| ~1 min | Taas võrgus, `inupgrade` endiselt `1` |
| mõni min | `inupgrade` muutub `0`-ks — valmis |

> ⚠️ **Ära katkesta toidet ega eemalda võrgukaablit** uuendamise ajal. Riskid seadme jäädava rikkumisega.

## Kinnitamine

```bash
curl -s http://<IP>/action/devStatus
```

Valmis, kui `fwVer` näitab uut versiooni **ja** `inupgrade` = `0`.

Edenemist edastatakse reaalajas WebSocketi kaudu aadressil `ws://<IP>:8080/mcm` — vaata [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Ühenduse katkemine tähendab, et püsivara kirjutati ja seade taaskäivitub; see ei ole viga.

## Lõksud

- **`/action/debug_ping` ootab numbrikoodi (`ping=2`), mitte IP-aadressi.** IP-aadressiga vastab see `no ip / Get addr error`, mis näeb välja nagu „internetti pole", kuid ei ole seda.
- **Versiooni eraldaja muutub väljalasete vahel:** `WB200_v2.0.33` → `WB200-v2.0.51`. Ära kunagi võrdle versiooni fikseeritud tekstiga.
- **`inupgrade` jääb väärtusele `1`** veel 2–3 minutiks pärast seda, kui seade on taas võrgus. Seade võib taaskäivituda mitu korda.
- **`health: WiFi is not connected!` on kahjutu**, kui kasutad Etherneti — seade on korraga nii pääsupunkt kui ka juhtmega klient.
- **Võrgu kaudu ei saa versiooni valida.** Tootja server pakub alati kõige uuemat püsivara. Kindla versiooni jaoks kasuta ingliskeelses juhendis kirjeldatud võrguvälist uuendamist.

## ⚠️ Turvalisus

`/action/devStatus` on avalik ja paljastab seerianumbri — mis on ühtlasi parool. Seansiluba pole muud kui `base64("user:" + SN)`. Praktikas: igaüks, kes seadmeni võrgus jõuab, saab selle ümber seadistada või uue püsivaraga kirjutada. **Ära kunagi** ava kaevuri porti 80 internetile; hoia see usaldusväärses kohtvõrgus.

## Litsents

[MIT](../LICENSE) · Ei ole seotud HyFixi ega GEODNET-iga. Püsivara kirjutamine on alati riskantne — omal vastutusel, sinu enda riistvaral.
