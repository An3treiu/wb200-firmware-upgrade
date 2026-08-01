# Mise à jour du firmware WB200

**[English — guide complet](../README.md)** · **[Toutes les langues](../README.md#-languages)**

Flasher un HyFix WB200 (mineur GEODNET) en ligne de commande. Vérifié sur du matériel réel : `2.0.33 → 2.0.51`.

> Guide court. La référence complète — tableau des points de terminaison, mise à jour hors ligne vers une version précise et tous les pièges — se trouve dans le [README anglais](../README.md).

## Démarrage rapide

Remplacez `<IP>` (par défaut `192.168.10.1`), `<SN>` (numéro de série) et `<TOKEN>`.

```bash
# 1. Lire l'état et récupérer le numéro de série — sans authentification
curl -s http://<IP>/action/devStatus

# 2. Se connecter — le mot de passe EST le numéro de série. La réponse est le jeton
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Lancer la mise à jour
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Ou laissez le script tout faire :

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Prérequis

Lisez `http://<IP>/action/devStatus` — public, sans authentification — et vérifiez :

- `inupgrade` = `0`, sinon une mise à jour est déjà en cours
- `wiredIP` = `ONLINE`, ou le WiFi est connecté
- l'appareil a accès à Internet

`minerStatus = MINING` est la preuve la plus solide d'un accès Internet, mais ce n'est **pas une condition requise**. En intérieur, sans vue dégagée sur le ciel pour l'antenne, le mineur ne quitte jamais l'état `WAITING` — c'est normal et cela ne bloque pas la mise à jour.

## Déroulement

| Durée | Événement |
|---|---|
| ~10 s | Firmware localisé sur le serveur du fabricant |
| ~3–4 min | Téléchargé puis écrit — sans le moindre retour |
| ensuite | L'appareil redémarre tout seul, les connexions tombent |
| ~1 min | De retour en ligne, `inupgrade` toujours à `1` |
| quelques min | `inupgrade` passe à `0` — terminé |

> ⚠️ **Ne coupez pas l'alimentation et ne débranchez pas le câble réseau** pendant la mise à jour. Vous risquez de rendre l'appareil inutilisable.

## Confirmation

```bash
curl -s http://<IP>/action/devStatus
```

C'est terminé quand `fwVer` affiche la nouvelle version **et** que `inupgrade` = `0`.

La progression est diffusée en direct par WebSocket sur `ws://<IP>:8080/mcm` — voir [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). La coupure de la connexion signifie que le firmware a été écrit et que l'appareil redémarre ; ce n'est pas une erreur.

## Pièges

- **`/action/debug_ping` attend un code numérique (`ping=2`), pas une adresse IP.** Avec une IP, il répond `no ip / Get addr error`, ce qui ressemble à « pas d'Internet » sans l'être.
- **Le séparateur de version change d'une version à l'autre :** `WB200_v2.0.33` → `WB200-v2.0.51`. Ne comparez jamais la version à une chaîne codée en dur.
- **`inupgrade` reste à `1`** pendant 2 à 3 minutes après le retour en ligne de l'appareil. Celui-ci peut redémarrer plusieurs fois.
- **`health: WiFi is not connected!` est sans conséquence** si vous êtes en Ethernet — l'appareil est à la fois point d'accès et client filaire.
- **Impossible de choisir la version en ligne.** Le serveur du fabricant sert toujours le firmware le plus récent. Pour une version précise, utilisez la mise à jour hors ligne décrite dans le guide anglais.

## ⚠️ Sécurité

`/action/devStatus` est public et expose le numéro de série — qui est aussi le mot de passe. Le jeton de session n'est rien d'autre que `base64("user:" + SN)`. Concrètement : quiconque atteint l'appareil sur le réseau peut le reconfigurer ou le reflasher. N'exposez **jamais** le port 80 du mineur sur Internet ; gardez-le sur un LAN de confiance.

## Licence

[MIT](../LICENSE) · Sans aucun lien avec HyFix ou GEODNET. Flasher un firmware comporte des risques — à vos propres risques, sur du matériel qui vous appartient.
