# Aktualizacja firmware'u WB200

**[English — pełny przewodnik](../README.md)** · **[Wszystkie języki](../README.md#-languages)**

Zaktualizuj firmware urządzenia HyFix WB200 (koparka GEODNET) z wiersza poleceń. Sprawdzone na prawdziwym sprzęcie: `2.0.33 → 2.0.51`.

> Krótki przewodnik. Pełna dokumentacja — kompletna tabela punktów końcowych, aktualizacja offline do konkretnej wersji i wszystkie pułapki — znajduje się w [angielskim README](../README.md).

## Szybki start

Podmień `<IP>` (domyślnie `192.168.10.1`), `<SN>` (numer seryjny) i `<TOKEN>`.

```bash
# 1. Odczytaj stan i pobierz numer seryjny — bez logowania
curl -s http://<IP>/action/devStatus

# 2. Zaloguj się — hasłem JEST numer seryjny. Odpowiedź to Twój token
curl -s -X POST http://<IP>/action/login \
  -H "Content-Type: application/x-www-form-urlencoded" -d "mkey=<SN>"

# 3. Uruchom aktualizację
curl -s -X POST http://<IP>/action/ota_online -b "USER=<TOKEN>" \
  -H "Content-Type: application/x-www-form-urlencoded" -d "protocol=ftp"
```

Albo pozwól, by wszystko zrobił skrypt:

```powershell
.\scripts\upgrade-wb200.ps1        # Windows
```
```bash
./scripts/upgrade-wb200.sh         # Linux / macOS
```

## Wymagania wstępne

Odczytaj `http://<IP>/action/devStatus` — publicznie, bez logowania — i sprawdź:

- `inupgrade` = `0`, w przeciwnym razie aktualizacja już trwa
- `wiredIP` = `ONLINE`, albo WiFi połączone
- urządzenie ma dostęp do internetu

`minerStatus = MINING` to najmocniejszy dowód na dostęp do internetu, ale **nie jest wymagany**. W pomieszczeniu, bez odsłoniętego nieba dla anteny, koparka nigdy nie wyjdzie ze stanu `WAITING` — to normalne i nie blokuje aktualizacji.

## Przebieg

| Czas | Zdarzenie |
|---|---|
| ~10 s | Firmware odnaleziony na serwerze producenta |
| ~3–4 min | Pobrany i zapisany — bez żadnej informacji zwrotnej |
| potem | Urządzenie samo się restartuje, połączenia zrywają się |
| ~1 min | Znów online, `inupgrade` wciąż `1` |
| kilka min | `inupgrade` zmienia się na `0` — gotowe |

> ⚠️ **Nie odcinaj zasilania ani nie odłączaj kabla sieciowego** w trakcie aktualizacji. Ryzykujesz trwałe uszkodzenie urządzenia.

## Potwierdzenie

```bash
curl -s http://<IP>/action/devStatus
```

Gotowe, gdy `fwVer` pokazuje nową wersję **i** `inupgrade` = `0`.

Postęp jest przesyłany na żywo przez WebSocket pod `ws://<IP>:8080/mcm` — zobacz [`scripts/ws-monitor.py`](../scripts/ws-monitor.py). Zerwanie połączenia oznacza, że firmware został zapisany i urządzenie się restartuje; to nie błąd.

## Pułapki

- **`/action/debug_ping` przyjmuje kod liczbowy (`ping=2`), a nie adres IP.** Podanie IP zwraca `no ip / Get addr error`, co wygląda jak „brak internetu", ale nim nie jest.
- **Separator w nazwie wersji zmienia się między wydaniami:** `WB200_v2.0.33` → `WB200-v2.0.51`. Nigdy nie porównuj wersji ze sztywno wpisanym tekstem.
- **`inupgrade` pozostaje `1`** jeszcze przez 2–3 minuty po powrocie urządzenia online. Urządzenie może zrestartować się więcej niż raz.
- **`health: WiFi is not connected!` jest nieszkodliwe**, gdy korzystasz z Ethernetu — urządzenie jest jednocześnie punktem dostępowym i klientem przewodowym.
- **Online nie wybierzesz wersji.** Serwer producenta zawsze podaje najnowszy firmware. Po konkretną wersję sięgnij po aktualizację offline opisaną w angielskim przewodniku.

## ⚠️ Bezpieczeństwo

`/action/devStatus` jest publiczny i ujawnia numer seryjny — który jest zarazem hasłem. Token sesji to nic więcej niż `base64("user:" + SN)`. W praktyce: każdy, kto dosięgnie urządzenia w sieci, może je przekonfigurować lub przeprogramować. **Nigdy** nie wystawiaj portu 80 koparki do internetu; trzymaj ją w zaufanej sieci LAN.

## Licencja

[MIT](../LICENSE) · Bez żadnych powiązań z HyFix ani GEODNET. Wgrywanie firmware'u wiąże się z ryzykiem — na własną odpowiedzialność, na sprzęcie, który należy do Ciebie.
