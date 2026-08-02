# WB200-laiteohjelmiston päivitys

**[English — täydellinen opas](../README.md)** · **[Kaikki kielet](../README.md#-languages)**

Päivitä HyFix WB200 -laitteen (Wingbitsin ADS-B-asema) laiteohjelmisto komentoriviltä. Todennettu oikealla laitteistolla: `2.0.33 → 2.0.51`.

> Lyhyt opas. Täydellinen viitedokumentaatio — koko päätepistetaulukko, offline-päivitys tiettyyn versioon ja kaikki sudenkuopat — löytyy [englanninkielisestä README-tiedostosta](../README.md).

## Pikaopas

Korvaa `<IP>` (oletus `192.168.10.1`), `<SN>` (sarjanumero) ja `<TOKEN>`.

```bash
# 1. Lue tila ja hae sarjanumero — kirjautumista ei tarvita
curl -s http://<IP>/action/devStatus

# 2. Kirjaudu — salasana ON sarjanumero. Vastaus on tunnuksesi
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Käynnistä päivitys
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Tai anna skriptin hoitaa kaikki:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Edellytykset

Lue `http://<IP>/action/devStatus` — julkinen, ei kirjautumista — ja tarkista:

- `inupgrade` = `0`, muuten päivitys on jo käynnissä
- `wiredIP` = `ONLINE`, tai WiFi yhdistetty
- laitteella on internetyhteys

`minerStatus = MINING` on vahvin todiste internetyhteydestä, mutta se **ei ole vaatimus**. Sisätiloissa, kun antennilla ei ole esteetöntä näkymää taivaalle, louhija ei koskaan poistu tilasta `WAITING` — se on normaalia eikä estä päivitystä.

## Mitä tapahtuu

| Aika | Tapahtuma |
|---|---|
| ~10 s | Laiteohjelmisto löytyy valmistajan palvelimelta |
| ~3–4 min | Ladataan ja kirjoitetaan — ilman mitään palautetta |
| sitten | Laite käynnistyy itsestään uudelleen, yhteydet katkeavat |
| ~1 min | Taas verkossa, `inupgrade` yhä `1` |
| muutama min | `inupgrade` muuttuu arvoon `0` — valmis |

> ⚠️ **Älä katkaise virtaa äläkä irrota verkkokaapelia** päivityksen aikana. Riskinä on laitteen rikkoutuminen käyttökelvottomaksi.

## Vahvistus

```bash
curl -s http://<IP>/action/devStatus
```

Valmis, kun `fwVer` näyttää uuden version **ja** `inupgrade` = `0`.

Edistyminen välitetään reaaliaikaisesti WebSocketin kautta osoitteessa `ws://<IP>:8080/mcm` — katso [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Yhteyden katkeaminen tarkoittaa, että laiteohjelmisto kirjoitettiin ja laite käynnistyy uudelleen; se ei ole virhe.

## Sudenkuopat

- **`/action/debug_ping` ottaa numerokoodin (`ping=2`), ei IP-osoitetta.** IP-osoitteella se vastaa `no ip / Get addr error`, mikä näyttää siltä kuin internetyhteyttä ei olisi, vaikka on.
- **Version erotinmerkki vaihtuu julkaisujen välillä:** `WB200_v2.0.33` → `WB200-v2.0.51`. Älä koskaan vertaa versiota kovakoodattuun merkkijonoon.
- **`inupgrade` pysyy arvossa `1`** vielä 2–3 minuuttia sen jälkeen, kun laite on taas verkossa. Laite voi käynnistyä uudelleen useammin kuin kerran.
- **`health: WiFi is not connected!` on harmiton**, kun käytät Ethernetiä — laite on samanaikaisesti tukiasema ja langallinen asiakas.
- **Versiota ei voi valita verkkopäivityksessä.** Valmistajan palvelin tarjoaa aina uusimman laiteohjelmiston. Tiettyä versiota varten käytä englanninkielisen oppaan offline-päivitystä.

## ⚠️ Tietoturva

`/action/devStatus` on julkinen ja paljastaa sarjanumeron — joka on samalla salasana. Istuntotunnus on pelkkä `base64("user:" + SN)`. Käytännössä: kuka tahansa, joka tavoittaa laitteen verkossa, voi määrittää sen uudelleen tai kirjoittaa siihen uuden laiteohjelmiston. **Älä koskaan** avaa louhijan porttia 80 internetiin; pidä se luotetussa lähiverkossa.

## Lisenssi

[MIT](../LICENSE) · Ei yhteyttä HyFixiin, Wingbitsiin tai GEODNETiin. Laiteohjelmiston kirjoittamiseen liittyy aina riski — omalla vastuulla, omistamallasi laitteistolla.
