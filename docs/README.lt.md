# WB200 programinės aparatinės įrangos naujinimas

**[English — visas vadovas](../README.md)** · **[Visos kalbos](../README.md#-languages)**

Atnaujinkite HyFix WB200 (GEODNET kasėjo) programinę aparatinę įrangą iš komandų eilutės. Patikrinta su tikra įranga: `2.0.33 → 2.0.51`.

> Trumpas vadovas. Visa informacija — pilna galinių taškų lentelė, atnaujinimas neprisijungus į konkrečią versiją ir visos spąstos — pateikta [angliškame README](../README.md).

## Greita pradžia

Pakeiskite `<IP>` (numatytoji `192.168.10.1`), `<SN>` (serijos numeris) ir `<TOKEN>`.

```bash
# 1. Perskaitykite būseną ir gaukite serijos numerį — be prisijungimo
curl -s http://<IP>/action/devStatus

# 2. Prisijunkite — slaptažodis YRA serijos numeris. Atsakymas yra jūsų prieigos raktas
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Paleiskite naujinimą
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Arba leiskite viską padaryti scenarijui:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Būtinos sąlygos

Perskaitykite `http://<IP>/action/devStatus` — viešas, be prisijungimo — ir patikrinkite:

- `inupgrade` = `0`, kitaip naujinimas jau vyksta
- `wiredIP` = `ONLINE`, arba prijungtas WiFi
- įrenginys turi prieigą prie interneto

`minerStatus = MINING` yra stipriausias interneto prieigos įrodymas, tačiau tai **nėra būtina sąlyga**. Patalpose, kai antena nemato atviro dangaus, kasėjas niekada neišeina iš būsenos `WAITING` — tai normalu ir naujinimui netrukdo.

## Kas vyksta

| Laikas | Įvykis |
|---|---|
| ~10 s | Programinė įranga rasta gamintojo serveryje |
| ~3–4 min | Atsisiųsta ir įrašyta — visiškai be jokio atsako |
| po to | Įrenginys pats persikrauna, ryšiai nutrūksta |
| ~1 min | Vėl prisijungęs, `inupgrade` vis dar `1` |
| kelios min | `inupgrade` tampa `0` — baigta |

> ⚠️ **Naujinimo metu neatjunkite maitinimo ir netraukite tinklo kabelio.** Rizikuojate visam laikui sugadinti įrenginį.

## Patvirtinimas

```bash
curl -s http://<IP>/action/devStatus
```

Baigta, kai `fwVer` rodo naują versiją **ir** `inupgrade` = `0`.

Eiga tiesiogiai perduodama per WebSocket adresu `ws://<IP>:8080/mcm` — žr. [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Ryšio nutrūkimas reiškia, kad programinė įranga buvo įrašyta ir įrenginys persikrauna; tai nėra klaida.

## Spąstai

- **`/action/debug_ping` priima skaitinį kodą (`ping=2`), o ne IP adresą.** Su IP adresu jis atsako `no ip / Get addr error`, kas atrodo kaip „nėra interneto", bet taip nėra.
- **Versijos skirtukas keičiasi tarp laidų:** `WB200_v2.0.33` → `WB200-v2.0.51`. Niekada nelyginkite versijos su griežtai įrašyta eilute.
- **`inupgrade` lieka `1`** dar 2–3 minutes po to, kai įrenginys vėl prisijungia. Įrenginys gali persikrauti ne kartą.
- **`health: WiFi is not connected!` yra nekenksmingas**, kai naudojate Ethernetą — įrenginys tuo pačiu metu yra ir prieigos taškas, ir laidinis klientas.
- **Prisijungus versijos pasirinkti negalima.** Gamintojo serveris visada pateikia naujausią programinę įrangą. Konkrečiai versijai naudokite atnaujinimą neprisijungus, aprašytą angliškame vadove.

## ⚠️ Saugumas

`/action/devStatus` yra viešas ir atskleidžia serijos numerį — kuris kartu yra ir slaptažodis. Seanso prieigos raktas tėra `base64("user:" + SN)`. Praktiškai: bet kas, kas pasiekia įrenginį tinkle, gali jį perkonfigūruoti arba perrašyti. **Niekada** neatverkite kasėjo 80 prievado internetui; laikykite jį patikimame vietiniame tinkle.

## Licencija

[MIT](../LICENSE) · Nesusiję su HyFix ar GEODNET. Programinės aparatinės įrangos įrašymas visada rizikingas — savo atsakomybe, jums priklausančioje įrangoje.
