# Aggiornamento firmware WB200

**[English — guida completa](../README.md)** · **[Tutte le lingue](../README.md#-languages)**

Aggiorna il firmware di un HyFix WB200 (miner GEODNET) dalla riga di comando. Verificato su hardware reale: `2.0.33 → 2.0.51`.

> Guida breve. Il riferimento completo — tabella integrale degli endpoint, aggiornamento offline a una versione specifica e tutte le insidie — si trova nel [README in inglese](../README.md).

## Avvio rapido

Sostituisci `<IP>` (predefinito `192.168.10.1`), `<SN>` (numero di serie) e `<TOKEN>`.

```bash
# 1. Leggere lo stato e ottenere il numero di serie — senza autenticazione
curl -s http://<IP>/action/devStatus

# 2. Accedere — la password È il numero di serie. La risposta è il token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Avviare l'aggiornamento
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Oppure lascia fare tutto allo script:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Prerequisiti

Leggi `http://<IP>/action/devStatus` — pubblico, senza autenticazione — e verifica:

- `inupgrade` = `0`, altrimenti è già in corso un aggiornamento
- `wiredIP` = `ONLINE`, oppure WiFi connesso
- il dispositivo ha accesso a Internet

`minerStatus = MINING` è la prova più solida della connessione a Internet, ma **non è un requisito**. Al chiuso, senza cielo libero per l'antenna, il miner non esce mai da `WAITING` — è normale e non impedisce l'aggiornamento.

## Cosa succede

| Tempo | Evento |
|---|---|
| ~10 s | Firmware individuato sul server del produttore |
| ~3–4 min | Scaricato e scritto — senza alcun riscontro |
| poi | Il dispositivo si riavvia da solo, le connessioni cadono |
| ~1 min | Di nuovo online, `inupgrade` ancora a `1` |
| qualche min | `inupgrade` diventa `0` — completato |

> ⚠️ **Non togliere l'alimentazione e non scollegare il cavo di rete** durante l'aggiornamento. Rischi di rendere inutilizzabile il dispositivo.

## Conferma

```bash
curl -s http://<IP>/action/devStatus
```

È finito quando `fwVer` mostra la nuova versione **e** `inupgrade` = `0`.

L'avanzamento viene trasmesso in tempo reale via WebSocket su `ws://<IP>:8080/mcm` — vedi [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). La caduta della connessione significa che il firmware è stato scritto e il dispositivo si sta riavviando; non è un errore.

## Insidie

- **`/action/debug_ping` vuole un codice numerico (`ping=2`), non un indirizzo IP.** Con un IP risponde `no ip / Get addr error`, che sembra «nessuna connessione» ma non lo è.
- **Il separatore della versione cambia tra una release e l'altra:** `WB200_v2.0.33` → `WB200-v2.0.51`. Non confrontare mai la versione con una stringa fissa nel codice.
- **`inupgrade` resta a `1`** per 2–3 minuti dopo che il dispositivo è tornato online. Può riavviarsi più di una volta.
- **`health: WiFi is not connected!` è innocuo** se usi Ethernet — il dispositivo è access point e client cablato allo stesso tempo.
- **Online non puoi scegliere la versione.** Il server del produttore fornisce sempre il firmware più recente. Per una versione specifica usa l'aggiornamento offline descritto nella guida in inglese.

## ⚠️ Sicurezza

`/action/devStatus` è pubblico ed espone il numero di serie — che è anche la password. Il token di sessione è soltanto `base64("user:" + SN)`. In pratica: chiunque raggiunga il dispositivo in rete può riconfigurarlo o riprogrammarlo. **Non** esporre mai la porta 80 del miner a Internet; tienilo su una LAN fidata.

## Licenza

[MIT](../LICENSE) · Nessuna affiliazione con HyFix o GEODNET. Aggiornare il firmware comporta dei rischi — a tuo rischio, su hardware di tua proprietà.
