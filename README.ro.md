<div align="center">

# WB200 — Upgrade firmware

**Actualizezi un miner HyFix WB200 (GEODNET) din linia de comandă — fără click-uri prin interfața web.**

[![CI](https://github.com/An3treiu/wb200-firmware-upgrade/actions/workflows/ci.yml/badge.svg)](https://github.com/An3treiu/wb200-firmware-upgrade/actions/workflows/ci.yml)
[![Licență: MIT](https://img.shields.io/badge/licen%C8%9B%C4%83-MIT-yellow.svg)](LICENSE)
[![Platformă](https://img.shields.io/badge/platform%C4%83-Windows%20%7C%20Linux%20%7C%20macOS-0078D6)](#scripturi)
[![Dependințe](https://img.shields.io/badge/dependin%C8%9Be-niciuna-brightgreen)](#scripturi)
[![Verificat pe hardware](https://img.shields.io/badge/verificat-WB200%20hw__v1.0-success)](#disclaimer)
[![Documentație](https://img.shields.io/badge/documenta%C8%9Bie-25%20de%20limbi-informational)](#-limbi)

</div>

---

Totul de aici a fost dedus din interfața web a device-ului și **verificat pe hardware real** — un upgrade reușit `2.0.33 → 2.0.51`. Fără fișiere proprietare, fără firmware modificat: sunt exact aceleași apeluri HTTP pe care le face și interfața oficială.

| | |
|---|---|
| 🔌 **Zero instalare** | Ai nevoie doar de `curl`. Vine preinstalat în Windows 10/11, Linux și macOS |
| ⚡ **O singură comandă** | Scripturile află singure serialul, se autentifică, fac flash-ul și așteaptă reboot-ul |
| 📡 **Progres live** | Monitor WebSocket în 200 de linii de Python, doar biblioteca standard |
| 🧯 **Testat în teren** | Fiecare capcană de mai jos a costat timp real — inclusiv cele două care fac un device funcțional să pară stricat |

## 🌍 Limbi

Ghid complet în **engleză** și **română** (pagina asta). Ghid scurt — start rapid, precondiții, progres, capcane și nota de securitate — în toate celelalte limbi oficiale ale UE, plus arabă.

| | | | | |
|---|---|---|---|---|
| <img src="docs/flags/gb.png" width="22" alt=""> [English](README.md) | <img src="docs/flags/ro.png" width="22" alt=""> [Română](README.ro.md) | <img src="docs/flags/bg.png" width="22" alt=""> [Български](docs/README.bg.md) | <img src="docs/flags/cz.png" width="22" alt=""> [Čeština](docs/README.cs.md) | <img src="docs/flags/dk.png" width="22" alt=""> [Dansk](docs/README.da.md) |
| <img src="docs/flags/de.png" width="22" alt=""> [Deutsch](docs/README.de.md) | <img src="docs/flags/ee.png" width="22" alt=""> [Eesti](docs/README.et.md) | <img src="docs/flags/gr.png" width="22" alt=""> [Ελληνικά](docs/README.el.md) | <img src="docs/flags/es.png" width="22" alt=""> [Español](docs/README.es.md) | <img src="docs/flags/fr.png" width="22" alt=""> [Français](docs/README.fr.md) |
| <img src="docs/flags/ie.png" width="22" alt=""> [Gaeilge](docs/README.ga.md) | <img src="docs/flags/hr.png" width="22" alt=""> [Hrvatski](docs/README.hr.md) | <img src="docs/flags/it.png" width="22" alt=""> [Italiano](docs/README.it.md) | <img src="docs/flags/lv.png" width="22" alt=""> [Latviešu](docs/README.lv.md) | <img src="docs/flags/lt.png" width="22" alt=""> [Lietuvių](docs/README.lt.md) |
| <img src="docs/flags/hu.png" width="22" alt=""> [Magyar](docs/README.hu.md) | <img src="docs/flags/mt.png" width="22" alt=""> [Malti](docs/README.mt.md) | <img src="docs/flags/nl.png" width="22" alt=""> [Nederlands](docs/README.nl.md) | <img src="docs/flags/pl.png" width="22" alt=""> [Polski](docs/README.pl.md) | <img src="docs/flags/pt.png" width="22" alt=""> [Português](docs/README.pt.md) |
| <img src="docs/flags/sk.png" width="22" alt=""> [Slovenčina](docs/README.sk.md) | <img src="docs/flags/si.png" width="22" alt=""> [Slovenščina](docs/README.sl.md) | <img src="docs/flags/fi.png" width="22" alt=""> [Suomi](docs/README.fi.md) | <img src="docs/flags/se.png" width="22" alt=""> [Svenska](docs/README.sv.md) | <img src="docs/flags/sa.png" width="22" alt=""> [العربية](docs/README.ar.md) |

---

## Pe scurt — 3 comenzi

```bash
# 1. Citești starea și afli serial number-ul (fără login)
curl -s http://<IP>/action/devStatus

# 2. Login — parola ESTE serial number-ul. Răspunsul e tokenul
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Pornești upgrade-ul online
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Aștepți 5–8 minute, apoi reiei comanda 1 ca să confirmi.

**Sau rulezi direct scriptul**, care face singur tot lanțul:

```powershell
.\scripts\upgrade-wb200.ps1 -Ip 192.168.10.1     # Windows
```
```bash
./scripts/upgrade-wb200.sh 192.168.10.1          # Linux / macOS / Git Bash
```

---

## Convenții folosite

| Simbol | Ce înseamnă | De unde îl iei |
|---|---|---|
| `<IP>` | Adresa device-ului | Implicit `192.168.10.1` în mod AP — vezi [Pasul 1](#pasul-1--găsește-device-ul) |
| `<SN>` | Serial number, 12 caractere | Din `devStatus` — vezi [Pasul 2](#pasul-2--citește-starea-și-află-sn-ul) |
| `<TOKEN>` | Tokenul de sesiune | Îl întoarce `login` — vezi [Pasul 3](#pasul-3--login) |

> **În CMD pe Windows:** folosește doar ghilimele duble `"`. Apostroful `'` nu funcționează în CMD.
> `curl.exe` vine preinstalat în Windows 10/11, nu trebuie instalat nimic.

---

## Pasul 1 — Găsește device-ul

Un WB200 e accesibil pe mai multe căi, în ordinea siguranței:

1. **Cablu direct în PC, sau conectat la WiFi-ul emis de el** (mod Access Point). Atunci device-ul e mereu la `192.168.10.1`.

   ```bash
   ping 192.168.10.1
   ```
   ```cmd
   ipconfig | findstr /C:"192.168.10"
   ```
   Trebuie să vezi PC-ul pe `192.168.10.x`, cu Default Gateway `192.168.10.1`.

2. **Prin numele mDNS**, dacă e în aceeași rețea cu PC-ul:

   ```bash
   ping wb200_XXXXXX.local
   ```
   `XXXXXX` corespunde etichetei de pe device / numelui rețelei WiFi pe care o emite.

3. **Prin IP-ul primit de la router** — din lista de clienți DHCP a routerului, sau din câmpul `wiredIP` de la Pasul 2.

---

## Pasul 2 — Citește starea și află SN-ul

```bash
curl -s http://<IP>/action/devStatus
```

Acest endpoint e **public — nu cere autentificare.** Întoarce JSON:

| Câmp | Ce înseamnă |
|---|---|
| `sn` | Serial number — **este și parola de login** |
| `fwVer` | Versiunea firmware instalată, ex. `WB200_v2.0.33` |
| `inupgrade` | `0` = liber, `1` = rulează deja un upgrade |
| `wiredIP` | `ONLINE,<ip>` când cablul e conectat |
| `minerStatus` | `MINING` — dovada reală că device-ul are **internet** |
| `nsStatus` | `TRANSMITTING` — trimite date către caster |
| `gps` | Starea fixului GNSS |
| `temp` | Temperatura, °C |

### Precondiții — înainte de upgrade

- [ ] `inupgrade` = `0` — altfel rulează deja un upgrade, **nu porni altul**
- [ ] `wiredIP` = `ONLINE` (sau WiFi conectat)
- [ ] Device-ul are **acces la internet** — upgrade-ul online descarcă firmware-ul de pe serverul producătorului

> **Cum apreciezi accesul la internet.** `minerStatus = MINING` e cea mai puternică confirmare, fiindcă minarea cere o conexiune activă la caster. Dar **nu este o condiție pentru upgrade** — vezi [Upgrade pe masă / în interior](#upgrade-pe-masă--în-interior). Dacă device-ul a primit adresă prin DHCP de la un router cu internet, e suficient.

### Upgrade pe masă / în interior

Dacă actualizezi minerii **în casă** — pe masă, fără vedere la cer pentru antenă — device-ul nu va ajunge *niciodată* la `MINING`. Rămâne la:

```
minerStatus = WAITING
nsStatus    = SOCKET-CONNECTING
gps         = Waiting for GPS Fix
```

E normal și **nu** blochează upgrade-ul de firmware. Minarea are nevoie de fix GPS; descărcarea și scrierea firmware-ului, nu.

În acest scenariu, apreciezi rezultatul după două câmpuri, atât:

```
fwVer     = versiunea nouă
inupgrade = 0
```

Folosește `-Force` / `--force` ca să sari peste avertismentul interactiv când faci mai multe unități la rând.

Doar esențialul, în PowerShell:

```powershell
$s = Invoke-RestMethod http://<IP>/action/devStatus
$s.fwVer; $s.sn; $s.inupgrade; $s.minerStatus
```

---

## Pasul 3 — Login

**Parola device-ului este serial number-ul** citit la Pasul 2.

```bash
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"
```

Răspunsul *este* tokenul. Îl trimiți mai departe ca și cookie: `-b "USER=<TOKEN>"`.

Tokenul nu e nimic altceva decât base64 din textul `user:<SN>`, deci îl poți calcula și singur:

```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("user:<SN>"))
```
```bash
printf 'user:%s' "<SN>" | base64
```

---

## Pasul 4 — Pornește upgrade-ul online

> ⚠️ **Aceasta este comanda care face flash-ul.**

```bash
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Răspuns așteptat: `OK`

Ce urmează, automat, fără intervenția ta:

| Timp | Ce se întâmplă |
|---|---|
| ~10 s | Device-ul găsește firmware-ul pe serverul FTP al producătorului |
| ~3–4 min | Îl descarcă și îl scrie — **fără niciun feedback pe HTTP** |
| apoi | **Repornește singur** — toate conexiunile pică brusc. E normal. |
| ~1 min | Revine online pe versiunea nouă, dar `inupgrade` e încă `1` |
| încă câteva min | `inupgrade` trece pe `0`, apoi minerul revine la `MINING` (are nevoie întâi de fix GPS) |

> 🚨 **Nu întrerupe alimentarea și nu scoate cablul de rețea** în acest interval. Riști să blochezi device-ul (brick).

---

## Pasul 5 — Urmărește progresul

### Simplu — reiei comanda de status

```bash
curl -s http://<IP>/action/devStatus
```

### Automat — buclă PowerShell

Înlocuiește `<IP>` și `<VERSIUNE_VECHE>` (ex. `2.0.33`):

```powershell
while ($true) {
  try {
    $s = Invoke-RestMethod http://<IP>/action/devStatus -TimeoutSec 5
    "{0}  ver={1}  inupgrade={2}  miner={3}" -f (Get-Date -f HH:mm:ss), $s.fwVer, $s.inupgrade, $s.minerStatus
    if ($s.inupgrade -eq "0" -and $s.fwVer -notlike "*<VERSIUNE_VECHE>*") { "GATA!"; break }
  } catch { "{0}  OFFLINE (reporneste...)" -f (Get-Date -f HH:mm:ss) }
  Start-Sleep 10
}
```

### În timp real — WebSocket

Interfața web primește progresul pe WebSocket, la fel poți și tu:

```
ws://<IP>:8080/mcm
```

| Prefix mesaj | Ce înseamnă |
|---|---|
| `APPOTA:ONLINE:` | Text de stare, ex. `Found firmware vX.Y.Z` |
| `APPOTA:UPLOAD:NN` | Procent încărcare fișier (doar la upgrade offline) |
| `APPOTA:UPGRADE:NN` | Procent scriere firmware |
| `GNSSOTA:UPLOAD/UPGRADE:NN` | Idem, pentru modulul GNSS |

Un listener fără dependințe e inclus — [`scripts/ws-monitor.py`](scripts/ws-monitor.py):

```bash
python scripts/ws-monitor.py 192.168.10.1
```

Faptul că **WebSocket-ul se rupe este semnul că flash-ul s-a aplicat** și device-ul repornește — nu e o eroare.

---

## Pasul 6 — Confirmă finalizarea

```bash
curl -s http://<IP>/action/devStatus
```

**Upgrade-ul în sine** e terminat când ambele sunt adevărate:

```
fwVer     = versiunea nouă
inupgrade = 0
```

Pentru un miner **montat**, cu antena la cer, serviciul e complet restabilit când ajunge și la:

```
minerStatus = MINING
nsStatus    = TRANSMITTING
```

Dacă minerul stă în `WAITING` cu `gps: Waiting for GPS Fix`, nu e nimic stricat — pur și simplu antena n-are încă fix. E normal câteva minute după orice reboot, și permanent dacă lucrezi în interior. Vezi [Upgrade pe masă / în interior](#upgrade-pe-masă--în-interior).

---

## Dacă vrei o versiune *anume* (upgrade offline)

> **Prin upgrade online nu poți alege versiunea.** Cererea trimite doar `protocol=ftp`, iar serverul producătorului decide ce firmware livrează — întotdeauna cel mai nou. Chiar dacă vrei o versiune intermediară, tot pe cea mai recentă o primești.

Pentru o versiune fixă îți trebuie fișierul `.bin` și endpoint-ul offline:

```bash
curl -s -X POST http://<IP>/action/ota_app -b "USER=<TOKEN>" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@/cale/catre/firmware.bin"
```

Limitări:

- Fișierul trebuie să fie **sub 100 MB** (limita e impusă de device)
- Interfața web îl trimite în bucăți (chunks); dacă un singur POST eșuează, folosește interfața web: **Firmware Upgrade → Upgrade Offline**
- Firmware-ul modulului GNSS e separat, pe `/action/ota_gnss`. Modulul on-board cere **5 fișiere**: DA, Partition Table, Bootloader, Firmware, Configuration

---

## Capcane — verificate practic

**`/action/debug_ping` nu primește o adresă IP.** Primește un cod numeric (`ping=2`). Dacă îi dai un IP, răspunde `no ip / Get addr error`, ceea ce arată exact ca „device-ul n-are internet" — concluzie falsă. Testul corect de internet este `minerStatus = MINING`.

**`"health":"WiFi is not connected!"` nu e o problemă** dacă folosești cablu. Device-ul este simultan access point (`192.168.10.1`) și client pe Ethernet.

**Separatorul din numele versiunii se poate schimba între firmware-uri:**

```
WB200_v2.0.33   (underscore)   →   WB200-v2.0.51   (liniuță)
```

Nu compara niciodată versiunea cu un text fix — parsează partea numerică, sau compar-o cu valoarea citită *înainte* de upgrade.

**`inupgrade` rămâne `1` încă 2–3 minute după ce device-ul a revenit online.** Doar `inupgrade=0` înseamnă terminat. Device-ul poate reporni de mai multe ori — e normal.

**Serverul web este GoAhead** (server HTTP embedded clasic). Rutele `/action/*` sunt funcții C compilate în firmware, nu fișiere — degeaba le cauți pe disc.

---

## ⚠️ Notă de securitate

`/action/devStatus` este **public, fără autentificare, și expune chiar serial number-ul** — adică parola. Tokenul de sesiune e doar `base64("user:" + SN)`, fără secret, fără nonce, fără expirare.

Practic: **oricine ajunge la device în rețea îl poate reconfigura sau reflasha.**

Pe un LAN izolat e acceptabil, și tocmai asta face posibilă automatizarea din acest repo. Pe o interfață publică **nu** este.

- **Niciodată** nu face port-forward la portul 80 al minerului spre internet
- **Niciodată** nu-l pune într-o rețea de invitați / neîncrezută
- Ține-l pe un LAN de încredere sau pe un VLAN dedicat

---

## Referință endpoint-uri

Extrase din interfața web a device-ului. Toate cer cookie-ul `USER`, **cu excepția** lui `/action/devStatus`.

| Metodă | Endpoint | Rol |
|---|---|---|
| GET | `/action/devStatus` | Stare completă — **public, fără login** |
| POST | `/action/login` | `mkey=<SN>` → token |
| POST | `/action/ota_online` | `protocol=ftp` → upgrade online |
| POST | `/action/ota_app` | Upload firmware principal (offline) |
| POST | `/action/ota_gnss` | Upload firmware modul GNSS |
| GET | `/action/gnssotamode` | Mod OTA pentru GNSS |
| POST | `/action/config_wifi` | Configurare WiFi |
| POST | `/action/config_mk` | Configurare miner key |
| POST | `/action/config_mi` | Configurare miner |
| POST | `/action/config_led` | Configurare LED |
| POST | `/action/config_adsb` | Configurare ADS-B |
| POST | `/action/config_graph` | Configurare grafice |
| POST | `/action/config_madmin` | Configurare admin |
| POST | `/action/debug_ping` | Test rețea (`ping=2`) |
| POST | `/action/debug_rtcmd` | Comandă RTK / diagnostic |
| GET | `/action/netHistory` | Istoric rețea |
| GET | `/action/downfile` | Descărcare fișiere |
| GET | `/action/start_down` | Inițiere descărcare |
| WS | `ws://<IP>:8080/mcm` | Flux de evenimente în timp real |

---

## Scripturi

| Fișier | Ce face |
|---|---|
| [`scripts/upgrade-wb200.ps1`](scripts/upgrade-wb200.ps1) | Automatizare completă în PowerShell: citește SN-ul, se autentifică, verifică precondițiile, face upgrade-ul și așteaptă finalizarea |
| [`scripts/upgrade-wb200.sh`](scripts/upgrade-wb200.sh) | Același flux în bash + curl (Linux / macOS / Git Bash). Nu are nevoie de `jq` |
| [`scripts/ws-monitor.py`](scripts/ws-monitor.py) | Listener WebSocket fără dependințe, pentru progres OTA în timp real (doar stdlib) |

---

## Disclaimer

Fără nicio afiliere cu HyFix sau GEODNET. Scrierea de firmware implică întotdeauna un risc — o pană de curent în timpul scrierii poate bloca definitiv device-ul. Îl folosești pe propria răspundere, pe hardware care îți aparține.

Verificat pe: **WB200, hw_v1.0**, upgrade `WB200_v2.0.33 → WB200-v2.0.51`.

Corecturi și rezultate de pe alte revizii hardware sunt binevenite — deschide un issue sau un PR.

## Licență

[MIT](LICENSE)
