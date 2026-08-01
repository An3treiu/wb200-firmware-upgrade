# Aġġornament tal-firmware WB200

**[English — gwida sħiħa](../README.md)** · **[Il-lingwi kollha](../README.md#-languages)**

Aġġorna l-firmware ta' HyFix WB200 (minatur GEODNET) mil-linja tal-kmand. Ivverifikat fuq ħardwer reali: `2.0.33 → 2.0.51`.

> Gwida qasira. Ir-referenza sħiħa — it-tabella kollha tal-endpoints, l-aġġornament offline għal verżjoni speċifika u n-nases kollha — tinsab fir-[README bl-Ingliż](../README.md).

## Bidu mgħaġġel

Ibdel `<IP>` (awtomatiku `192.168.10.1`), `<SN>` (numru tas-serje) u `<TOKEN>`.

```bash
# 1. Aqra l-istat u ġib in-numru tas-serje — mingħajr login
curl -s http://<IP>/action/devStatus

# 2. Idħol — il-password HUWA n-numru tas-serje. It-tweġiba hija t-token tiegħek
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Ibda l-aġġornament
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Jew ħalli l-iskript jagħmel kollox:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Rekwiżiti minn qabel

Aqra `http://<IP>/action/devStatus` — pubbliku, mingħajr login — u ċċekkja:

- `inupgrade` = `0`, inkella diġà għaddej aġġornament
- `wiredIP` = `ONLINE`, jew WiFi konness
- l-apparat għandu aċċess għall-internet

`minerStatus = MINING` hija l-aqwa prova ta' aċċess għall-internet, iżda **mhijiex rekwiżit**. Ġewwa, mingħajr veduta ħielsa tas-sema għall-antenna, il-minatur qatt ma joħroġ mill-istat `WAITING` — dan huwa normali u ma jwaqqafx l-aġġornament.

## X'jiġri

| Ħin | Ġrajja |
|---|---|
| ~10 s | Il-firmware jinstab fuq is-server tal-manifattur |
| ~3–4 min | Jitniżżel u jinkiteb — mingħajr ebda rispons |
| imbagħad | L-apparat jerġa' jibda waħdu, il-konnessjonijiet jaqgħu |
| ~1 min | Online mill-ġdid, `inupgrade` għadu `1` |
| ftit min | `inupgrade` isir `0` — lest |

> ⚠️ **Taqtax id-dawl u tiġbidx il-kejbil tan-netwerk** waqt l-aġġornament. Tirriskja li ġġib l-apparat inutli għal dejjem.

## Konferma

```bash
curl -s http://<IP>/action/devStatus
```

Lest meta `fwVer` juri l-verżjoni l-ġdida **u** `inupgrade` = `0`.

Il-progress jixxandar dirett permezz ta' WebSocket fuq `ws://<IP>:8080/mcm` — ara [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Il-qtugħ tal-konnessjoni jfisser li l-firmware inkiteb u l-apparat qed jerġa' jibda; mhijiex żball.

## Nases

- **`/action/debug_ping` jieħu kodiċi numeriku (`ping=2`), mhux indirizz IP.** B'indirizz IP iwieġeb `no ip / Get addr error`, li jidher qisu «ebda internet» iżda mhuwiex.
- **Is-separatur tal-verżjoni jinbidel bejn ħarġa u oħra:** `WB200_v2.0.33` → `WB200-v2.0.51`. Qatt tqabbel il-verżjoni ma' test iffissat fil-kodiċi.
- **`inupgrade` jibqa' `1`** għal 2–3 minuti wara li l-apparat jerġa' jkun online. L-apparat jista' jerġa' jibda aktar minn darba.
- **`health: WiFi is not connected!` mhuwiex problema** meta tuża l-Ethernet — l-apparat huwa fl-istess ħin access point u klijent bil-fili.
- **Online ma tistax tagħżel il-verżjoni.** Is-server tal-manifattur dejjem jagħti l-aħħar firmware. Għal verżjoni speċifika uża l-aġġornament offline deskritt fil-gwida bl-Ingliż.

## ⚠️ Sigurtà

`/action/devStatus` huwa pubbliku u jikxef in-numru tas-serje — li huwa wkoll il-password. It-token tas-sessjoni mhu xejn ħlief `base64("user:" + SN)`. Fil-prattika: kull min jasal għall-apparat fin-netwerk jista' jerġa' jikkonfigurah jew jerġa' jiktiblu l-firmware. **Qatt** tesponi l-port 80 tal-minatur għall-internet; żommu fuq LAN fdata.

## Liċenzja

[MIT](../LICENSE) · Mingħajr ebda rabta ma' HyFix jew GEODNET. Il-kitba tal-firmware iġġib magħha riskju — għar-riskju tiegħek, fuq ħardwer li huwa tiegħek.
