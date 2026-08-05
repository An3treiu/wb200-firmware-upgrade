# WB200 firmware-frissítés

**[English — teljes útmutató](../README.md)** · **[Minden nyelv](../README.md#-languages)**

Frissítsd egy HyFix WB200 (Wingbits ADS-B állomás) firmware-ét parancssorból. Valódi hardveren ellenőrizve: `2.0.33 → 2.0.51`.

> Rövid útmutató. A teljes referencia — a teljes végpont-táblázat, offline frissítés adott verzióra és minden buktató — az [angol README-ben](../README.md) található.

## Gyors indulás

Cseréld le a `<IP>` (alapértelmezés `192.168.10.1`), `<SN>` (sorozatszám) és `<TOKEN>` helyőrzőket.

```bash
# 1. Olvasd ki az állapotot és a sorozatszámot — bejelentkezés nélkül
curl -s http://<IP>/action/devStatus

# 2. Jelentkezz be — a jelszó MAGA a sorozatszám. A válasz a tokened
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Indítsd a frissítést
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Vagy bízd az egészet a szkriptre:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Előfeltételek

Olvasd ki a `http://<IP>/action/devStatus` végpontot — nyilvános, bejelentkezés nélkül — és ellenőrizd:

- `inupgrade` = `0`, különben már fut egy frissítés
- `wiredIP` = `ONLINE`, vagy csatlakoztatott WiFi
- az eszköznek van internet-hozzáférése

A `minerStatus = MINING` a legerősebb bizonyíték az internetkapcsolatra, de **nem követelmény**. Beltérben, ahol az antenna nem lát rá szabadon az égre, a bányász soha nem lép ki a `WAITING` állapotból — ez normális, és nem akadályozza a frissítést.

## Mi történik

| Idő | Esemény |
|---|---|
| ~10 mp | A firmware megtalálva a gyártó szerverén |
| ~3–4 perc | Letöltés és kiírás — mindenféle visszajelzés nélkül |
| utána | Az eszköz magától újraindul, a kapcsolatok megszakadnak |
| ~1 perc | Ismét online, az `inupgrade` még mindig `1` |
| pár perc | Az `inupgrade` `0` lesz — kész |

> ⚠️ **Ne szakítsd meg a tápellátást, és ne húzd ki a hálózati kábelt** a frissítés alatt. Kockáztatod, hogy az eszköz használhatatlanná válik.

## Megerősítés

```bash
curl -s http://<IP>/action/devStatus
```

Akkor kész, ha az `fwVer` az új verziót mutatja **és** az `inupgrade` = `0`.

Az előrehaladás élőben érkezik WebSocketen a `ws://<IP>:8080/mcm` címen — lásd: [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Ha a kapcsolat megszakad, az azt jelenti, hogy a firmware kiírásra került és az eszköz újraindul; ez nem hiba.

## Buktatók

- **A `/action/debug_ping` számkódot vár (`ping=2`), nem IP-címet.** IP-címmel `no ip / Get addr error` a válasz, ami úgy néz ki, mintha nem lenne internet — pedig van.
- **A verzió elválasztójele kiadásonként változik:** `WB200_v2.0.33` → `WB200-v2.0.51`. Soha ne hasonlítsd a verziót fixen beégetett szöveghez.
- **Az `inupgrade` még 2–3 percig `1` marad** azután is, hogy az eszköz visszatért online. Az eszköz többször is újraindulhat.
- **A `health: WiFi is not connected!` ártalmatlan**, ha Ethernetet használsz — az eszköz egyszerre hozzáférési pont és vezetékes kliens.
- **Online nem választhatsz verziót.** A gyártó szervere mindig a legfrissebb firmware-t adja. Konkrét verzióhoz használd az angol útmutatóban leírt offline frissítést.

## ⚠️ Biztonság

A `/action/devStatus` nyilvános, és felfedi a sorozatszámot — ami egyben a jelszó is. A munkamenet-token nem más, mint `base64("user:" + SN)`. A gyakorlatban: bárki, aki eléri az eszközt a hálózaton, újrakonfigurálhatja vagy újraflashelheti. **Soha** ne tedd ki a bányász 80-as portját az internetre; tartsd megbízható helyi hálózaton.

## Licenc

[MIT](../LICENSE) · Semmilyen kapcsolatban nem áll a HyFix, a Wingbits vagy a GEODNET céggel. A firmware kiírása kockázattal jár — saját felelősségre, a saját tulajdonú hardvereden.
