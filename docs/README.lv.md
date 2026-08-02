# WB200 programmaparatūras atjaunināšana

**[English — pilnīga rokasgrāmata](../README.md)** · **[Visas valodas](../README.md#-languages)**

Atjauniniet HyFix WB200 (Wingbits ADS-B stacijas) programmaparatūru no komandrindas. Pārbaudīts uz reālas aparatūras: `2.0.33 → 2.0.51`.

> Īsa rokasgrāmata. Pilnā atsauce — visa galapunktu tabula, bezsaistes atjaunināšana uz konkrētu versiju un visas lamatas — atrodama [angļu valodas README](../README.md).

## Ātrā sākšana

Aizstājiet `<IP>` (noklusējums `192.168.10.1`), `<SN>` (sērijas numurs) un `<TOKEN>`.

```bash
# 1. Nolasiet statusu un iegūstiet sērijas numuru — bez pieteikšanās
curl -s http://<IP>/action/devStatus

# 2. Piesakieties — parole IR sērijas numurs. Atbilde ir jūsu pilnvara
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Sāciet atjaunināšanu
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Vai ļaujiet skriptam izdarīt visu:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Priekšnosacījumi

Nolasiet `http://<IP>/action/devStatus` — publisks, bez pieteikšanās — un pārbaudiet:

- `inupgrade` = `0`, citādi atjaunināšana jau notiek
- `wiredIP` = `ONLINE`, vai pievienots WiFi
- ierīcei ir piekļuve internetam

`minerStatus = MINING` ir spēcīgākais pierādījums interneta piekļuvei, taču tā **nav prasība**. Telpās, kur antenai nav brīva skata uz debesīm, racējs nekad neizkļūst no stāvokļa `WAITING` — tas ir normāli un netraucē atjaunināšanu.

## Kas notiek

| Laiks | Notikums |
|---|---|
| ~10 s | Programmaparatūra atrasta ražotāja serverī |
| ~3–4 min | Lejupielādēta un ierakstīta — bez jebkādas atgriezeniskās saites |
| pēc tam | Ierīce pati pārstartējas, savienojumi pārtrūkst |
| ~1 min | Atkal tiešsaistē, `inupgrade` joprojām `1` |
| dažas min | `inupgrade` kļūst `0` — pabeigts |

> ⚠️ **Atjaunināšanas laikā neatvienojiet strāvu un neizvelciet tīkla kabeli.** Riskējat neatgriezeniski sabojāt ierīci.

## Apstiprināšana

```bash
curl -s http://<IP>/action/devStatus
```

Pabeigts, kad `fwVer` rāda jauno versiju **un** `inupgrade` = `0`.

Norise tiek pārraidīta tiešraidē caur WebSocket adresē `ws://<IP>:8080/mcm` — skatiet [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Savienojuma pārtrūkšana nozīmē, ka programmaparatūra tika ierakstīta un ierīce pārstartējas; tā nav kļūda.

## Lamatas

- **`/action/debug_ping` gaida skaitlisku kodu (`ping=2`), nevis IP adresi.** Ar IP adresi tas atbild `no ip / Get addr error`, kas izskatās pēc «nav interneta», bet tāds nav.
- **Versijas atdalītājs mainās starp laidieniem:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nekad nesalīdziniet versiju ar cieti ierakstītu virkni.
- **`inupgrade` paliek `1`** vēl 2–3 minūtes pēc tam, kad ierīce atgriezusies tiešsaistē. Ierīce var pārstartēties vairāk nekā vienu reizi.
- **`health: WiFi is not connected!` ir nekaitīgs**, ja lietojat Ethernet — ierīce vienlaikus ir piekļuves punkts un vadu klients.
- **Tiešsaistē versiju izvēlēties nevar.** Ražotāja serveris vienmēr piegādā jaunāko programmaparatūru. Konkrētai versijai izmantojiet bezsaistes atjaunināšanu, kas aprakstīta angļu rokasgrāmatā.

## ⚠️ Drošība

`/action/devStatus` ir publisks un atklāj sērijas numuru — kas vienlaikus ir arī parole. Sesijas pilnvara nav nekas vairāk kā `base64("user:" + SN)`. Praksē: ikviens, kas tīklā sasniedz ierīci, var to pārkonfigurēt vai pārrakstīt. **Nekad** neatveriet racēja 80. portu internetam; turiet to uzticamā lokālajā tīklā.

## Licence

[MIT](../LICENSE) · Nav saistīts ar HyFix, Wingbits vai GEODNET. Programmaparatūras ierakstīšana vienmēr ir riskanta — uz jūsu paša atbildību, uz aparatūras, kas pieder jums.
