# Actualización de firmware del WB200

**[English — guía completa](../README.md)** · **[Todos los idiomas](../README.md#-languages)**

Flashea un HyFix WB200 (estación ADS-B de Wingbits) desde la línea de comandos. Verificado en hardware real: `2.0.33 → 2.0.51`.

> Guía breve. La referencia completa — tabla íntegra de endpoints, actualización sin conexión a una versión concreta y todas las trampas — está en el [README en inglés](../README.md).

## Inicio rápido

Sustituye `<IP>` (por defecto `192.168.10.1`), `<SN>` (número de serie) y `<TOKEN>`.

```bash
# 1. Leer el estado y obtener el número de serie — sin autenticación
curl -s http://<IP>/action/devStatus

# 2. Iniciar sesión — la contraseña ES el número de serie. La respuesta es el token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Lanzar la actualización
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

O deja que el script lo haga todo:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Requisitos previos

Lee `http://<IP>/action/devStatus` — público, sin autenticación — y comprueba:

- `inupgrade` = `0`, de lo contrario ya hay una actualización en curso
- `wiredIP` = `ONLINE`, o el WiFi está conectado
- el dispositivo tiene acceso a Internet

`minerStatus = MINING` es la prueba más sólida de que hay Internet, pero **no es un requisito**. En interiores, sin visión despejada del cielo para la antena, el minero nunca sale de `WAITING` — es normal y no bloquea la actualización.

## Qué ocurre

| Tiempo | Suceso |
|---|---|
| ~10 s | Firmware localizado en el servidor del fabricante |
| ~3–4 min | Descargado y escrito — sin ninguna señal de progreso |
| después | El dispositivo se reinicia solo, las conexiones se caen |
| ~1 min | De nuevo en línea, `inupgrade` sigue en `1` |
| unos min | `inupgrade` pasa a `0` — terminado |

> ⚠️ **No cortes la alimentación ni desconectes el cable de red** durante la actualización. Corres el riesgo de inutilizar el dispositivo.

## Confirmación

```bash
curl -s http://<IP>/action/devStatus
```

Está terminado cuando `fwVer` muestra la versión nueva **y** `inupgrade` = `0`.

El progreso se transmite en directo por WebSocket en `ws://<IP>:8080/mcm` — consulta [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Que la conexión se corte significa que el firmware se ha escrito y el dispositivo se está reiniciando; no es un error.

## Trampas

- **`/action/debug_ping` espera un código numérico (`ping=2`), no una dirección IP.** Con una IP responde `no ip / Get addr error`, lo que parece «sin Internet» pero no lo es.
- **El separador de la versión cambia entre lanzamientos:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nunca compares la versión con una cadena fija en el código.
- **`inupgrade` permanece en `1`** durante 2–3 minutos después de que el dispositivo vuelva a estar en línea. Puede reiniciarse más de una vez.
- **`health: WiFi is not connected!` es inofensivo** si usas Ethernet — el dispositivo es punto de acceso y cliente por cable a la vez.
- **No puedes elegir la versión en línea.** El servidor del fabricante siempre entrega el firmware más reciente. Para una versión concreta, usa la actualización sin conexión descrita en la guía en inglés.

## ⚠️ Seguridad

`/action/devStatus` es público y expone el número de serie — que además es la contraseña. El token de sesión no es más que `base64("user:" + SN)`. En la práctica: cualquiera que alcance el dispositivo en la red puede reconfigurarlo o reflashearlo. **Nunca** expongas el puerto 80 del minero a Internet; mantenlo en una LAN de confianza.

## Licencia

[MIT](../LICENSE) · Sin afiliación con HyFix, Wingbits ni GEODNET. Flashear firmware conlleva riesgos — bajo tu propia responsabilidad, en hardware de tu propiedad.
