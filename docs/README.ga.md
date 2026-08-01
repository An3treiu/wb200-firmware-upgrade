# Uasghrádú dochtearraí WB200

**[English — treoir iomlán](../README.md)** · **[Gach teanga](../README.md#-languages)**

Uasghrádaigh dochtearraí gléas HyFix WB200 (mianadóir GEODNET) ón líne ordaithe. Fíoraithe ar chrua-earraí fíora: `2.0.33 → 2.0.51`.

> Treoir ghairid. Tá an tagairt iomlán — an tábla iomlán críochphointí, uasghrádú as líne go leagan ar leith, agus gach gaiste — sa [README Béarla](../README.md).

## Tosú tapa

Cuir `<IP>` (réamhshocrú `192.168.10.1`), `<SN>` (sraithuimhir) agus `<TOKEN>` in ionad na n-áitchoinneálaithe.

```bash
# 1. Léigh an stádas agus faigh an tsraithuimhir — gan logáil isteach
curl -s http://<IP>/action/devStatus

# 2. Logáil isteach — IS Í an tsraithuimhir an focal faire. Is é an freagra do chomhartha
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Tosaigh an t-uasghrádú
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Nó lig don script gach rud a dhéanamh:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Réamhriachtanais

Léigh `http://<IP>/action/devStatus` — poiblí, gan logáil isteach — agus seiceáil:

- `inupgrade` = `0`, nó tá uasghrádú ar siúl cheana féin
- `wiredIP` = `ONLINE`, nó WiFi ceangailte
- tá rochtain idirlín ag an ngléas

Is é `minerStatus = MINING` an cruthúnas is láidre ar rochtain idirlín, ach **ní riachtanas é**. Laistigh, gan radharc glan ar an spéir don aeróg, ní fhágann an mianadóir an staid `WAITING` riamh — tá sin gnách agus ní chuireann sé bac ar an uasghrádú.

## Cad a tharlaíonn

| Am | Teagmhas |
|---|---|
| ~10 s | Dochtearraí aimsithe ar fhreastalaí an mhonaróra |
| ~3–4 nóim | Íoslódáilte agus scríofa — gan aon aiseolas ar bith |
| ansin | Atosaíonn an gléas as a stuaim féin, titeann na naisc |
| ~1 nóim | Ar líne arís, `inupgrade` fós ag `1` |
| cúpla nóim | Éiríonn `inupgrade` ina `0` — críochnaithe |

> ⚠️ **Ná bain an chumhacht agus ná tarraing an cábla líonra amach** le linn an uasghrádaithe. Tá baol ann go millfí an gléas go buan.

## Deimhniú

```bash
curl -s http://<IP>/action/devStatus
```

Tá sé críochnaithe nuair a thaispeánann `fwVer` an leagan nua **agus** `inupgrade` = `0`.

Craoltar an dul chun cinn beo trí WebSocket ag `ws://<IP>:8080/mcm` — féach [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Ciallaíonn titim an naisc gur scríobhadh na dochtearraí agus go bhfuil an gléas ag atosú; ní earráid é.

## Gaistí

- **Glacann `/action/debug_ping` le cód uimhriúil (`ping=2`), ní le seoladh IP.** Le seoladh IP freagraíonn sé `no ip / Get addr error`, rud a bhreathnaíonn cosúil le „gan idirlíon" ach nach bhfuil.
- **Athraíonn deighilteoir an leagain idir eisiúintí:** `WB200_v2.0.33` → `WB200-v2.0.51`. Ná déan comparáid riamh idir an leagan agus teaghrán crua-chódaithe.
- **Fanann `inupgrade` ag `1`** ar feadh 2–3 nóiméad tar éis don ghléas teacht ar ais ar líne. Féadfaidh an gléas atosú níos mó ná uair amháin.
- **Tá `health: WiFi is not connected!` neamhdhíobhálach** nuair a úsáideann tú Ethernet — is pointe rochtana agus cliant sreangaithe é an gléas ag an am céanna.
- **Ní féidir an leagan a roghnú ar líne.** Soláthraíonn freastalaí an mhonaróra na dochtearraí is déanaí i gcónaí. Le haghaidh leagain ar leith, bain úsáid as an uasghrádú as líne atá tuairiscithe sa treoir Bhéarla.

## ⚠️ Slándáil

Tá `/action/devStatus` poiblí agus nochtann sé an tsraithuimhir — arb é an focal faire é chomh maith. Níl sa chomhartha seisiúin ach `base64("user:" + SN)`. Go praiticiúil: is féidir le duine ar bith a shroicheann an gléas ar an líonra é a athchumrú nó dochtearraí nua a scríobh air. Ná nocht port 80 an mhianadóra don idirlíon **riamh**; coinnigh ar LAN iontaofa é.

## Ceadúnas

[MIT](../LICENSE) · Gan aon cheangal le HyFix ná GEODNET. Baineann riosca le dochtearraí a scríobh — ar do phriacal féin, ar chrua-earraí ar leatsa iad.
