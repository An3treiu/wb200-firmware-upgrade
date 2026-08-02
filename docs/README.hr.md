# Nadogradnja firmvera WB200

**[English — potpuni vodič](../README.md)** · **[Svi jezici](../README.md#-languages)**

Nadogradite firmver uređaja HyFix WB200 (Wingbits ADS-B stanica) iz naredbenog retka. Provjereno na stvarnom hardveru: `2.0.33 → 2.0.51`.

> Kratki vodič. Potpuna referenca — cijela tablica krajnjih točaka, izvanmrežna nadogradnja na određenu verziju i sve zamke — nalazi se u [engleskom README-u](../README.md).

## Brzi početak

Zamijenite `<IP>` (zadano `192.168.10.1`), `<SN>` (serijski broj) i `<TOKEN>`.

```bash
# 1. Pročitajte stanje i dohvatite serijski broj — bez prijave
curl -s http://<IP>/action/devStatus

# 2. Prijavite se — lozinka JEST serijski broj. Odgovor je vaš token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Pokrenite nadogradnju
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Ili prepustite sve skripti:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Preduvjeti

Pročitajte `http://<IP>/action/devStatus` — javno, bez prijave — i provjerite:

- `inupgrade` = `0`, inače nadogradnja već traje
- `wiredIP` = `ONLINE`, ili je WiFi povezan
- uređaj ima pristup internetu

`minerStatus = MINING` najjači je dokaz pristupa internetu, ali **nije uvjet**. U zatvorenom prostoru, bez slobodnog pogleda antene na nebo, rudar nikada ne izlazi iz stanja `WAITING` — to je normalno i ne sprječava nadogradnju.

## Što se događa

| Vrijeme | Događaj |
|---|---|
| ~10 s | Firmver pronađen na poslužitelju proizvođača |
| ~3–4 min | Preuzet i zapisan — bez ikakve povratne informacije |
| zatim | Uređaj se sam ponovno pokreće, veze pucaju |
| ~1 min | Ponovno na mreži, `inupgrade` i dalje `1` |
| nekoliko min | `inupgrade` postaje `0` — gotovo |

> ⚠️ **Ne prekidajte napajanje i ne izvlačite mrežni kabel** tijekom nadogradnje. Riskirate trajno onesposobiti uređaj.

## Potvrda

```bash
curl -s http://<IP>/action/devStatus
```

Gotovo je kada `fwVer` prikazuje novu verziju **i** `inupgrade` = `0`.

Napredak se prenosi uživo putem WebSocketa na `ws://<IP>:8080/mcm` — vidi [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Prekid veze znači da je firmver zapisan i da se uređaj ponovno pokreće; to nije pogreška.

## Zamke

- **`/action/debug_ping` prima brojčani kod (`ping=2`), a ne IP adresu.** S IP adresom odgovara `no ip / Get addr error`, što izgleda kao „nema interneta", ali nije.
- **Znak razdvajanja u verziji mijenja se između izdanja:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nikada ne uspoređujte verziju s čvrsto upisanim nizom.
- **`inupgrade` ostaje `1`** još 2–3 minute nakon što se uređaj vrati na mrežu. Uređaj se može ponovno pokrenuti više puta.
- **`health: WiFi is not connected!` je bezopasno** kada koristite Ethernet — uređaj je istodobno pristupna točka i žičani klijent.
- **Verziju ne možete birati na mreži.** Poslužitelj proizvođača uvijek isporučuje najnoviji firmver. Za određenu verziju upotrijebite izvanmrežnu nadogradnju opisanu u engleskom vodiču.

## ⚠️ Sigurnost

`/action/devStatus` je javan i otkriva serijski broj — koji je ujedno i lozinka. Token sesije nije ništa drugo nego `base64("user:" + SN)`. U praksi: svatko tko dosegne uređaj na mreži može ga prekonfigurirati ili ponovno programirati. **Nikada** ne izlažite port 80 rudara internetu; držite ga u pouzdanoj lokalnoj mreži.

## Licencija

[MIT](../LICENSE) · Bez ikakve povezanosti s HyFixom, Wingbitsom ili GEODNET-om. Zapisivanje firmvera nosi rizik — na vlastitu odgovornost, na hardveru koji posjedujete.
