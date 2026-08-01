# Atualização de firmware do WB200

**[English — guia completo](../README.md)** · **[Todos os idiomas](../README.md#-languages)**

Atualize o firmware de um HyFix WB200 (estação ADS-B Wingbits) pela linha de comandos. Verificado em hardware real: `2.0.33 → 2.0.51`.

> Guia breve. A referência completa — tabela integral de endpoints, atualização offline para uma versão específica e todas as armadilhas — está no [README em inglês](../README.md).

## Início rápido

Substitua `<IP>` (por omissão `192.168.10.1`), `<SN>` (número de série) e `<TOKEN>`.

```bash
# 1. Ler o estado e obter o número de série — sem autenticação
curl -s http://<IP>/action/devStatus

# 2. Autenticar — a palavra-passe É o número de série. A resposta é o token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Iniciar a atualização
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Ou deixe o script fazer tudo:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Pré-requisitos

Leia `http://<IP>/action/devStatus` — público, sem autenticação — e confirme:

- `inupgrade` = `0`, caso contrário já está a decorrer uma atualização
- `wiredIP` = `ONLINE`, ou WiFi ligado
- o dispositivo tem acesso à Internet

`minerStatus = MINING` é a prova mais forte de que há Internet, mas **não é um requisito**. Em interiores, sem vista desimpedida do céu para a antena, o minerador nunca sai de `WAITING` — é normal e não impede a atualização.

## O que acontece

| Tempo | Acontecimento |
|---|---|
| ~10 s | Firmware localizado no servidor do fabricante |
| ~3–4 min | Descarregado e escrito — sem qualquer indicação |
| depois | O dispositivo reinicia sozinho, as ligações caem |
| ~1 min | De novo online, `inupgrade` ainda a `1` |
| alguns min | `inupgrade` passa a `0` — concluído |

> ⚠️ **Não corte a alimentação nem desligue o cabo de rede** durante a atualização. Corre o risco de inutilizar o dispositivo.

## Confirmação

```bash
curl -s http://<IP>/action/devStatus
```

Está concluído quando `fwVer` mostra a nova versão **e** `inupgrade` = `0`.

O progresso é transmitido em direto por WebSocket em `ws://<IP>:8080/mcm` — ver [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). A ligação cair significa que o firmware foi escrito e o dispositivo está a reiniciar; não é um erro.

## Armadilhas

- **`/action/debug_ping` espera um código numérico (`ping=2`), não um endereço IP.** Com um IP responde `no ip / Get addr error`, o que parece «sem Internet» mas não é.
- **O separador da versão muda entre lançamentos:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nunca compare a versão com um texto fixo no código.
- **`inupgrade` permanece a `1`** durante 2–3 minutos depois de o dispositivo voltar a estar online. Pode reiniciar mais do que uma vez.
- **`health: WiFi is not connected!` é inofensivo** se usar Ethernet — o dispositivo é ponto de acesso e cliente com fios ao mesmo tempo.
- **Online não pode escolher a versão.** O servidor do fabricante fornece sempre o firmware mais recente. Para uma versão específica, use a atualização offline descrita no guia em inglês.

## ⚠️ Segurança

`/action/devStatus` é público e expõe o número de série — que é também a palavra-passe. O token de sessão não passa de `base64("user:" + SN)`. Na prática: quem alcançar o dispositivo na rede pode reconfigurá-lo ou reprogramá-lo. **Nunca** exponha a porta 80 do minerador à Internet; mantenha-o numa LAN de confiança.

## Licença

[MIT](../LICENSE) · Sem qualquer afiliação com a HyFix, a Wingbits ou a GEODNET. Gravar firmware comporta riscos — por sua conta e risco, em hardware que lhe pertence.
